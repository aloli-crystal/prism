require "./ui/html"
require "./files/recent"
require "./files/preferences"
require "./git/repository"

module Prism
  class App
    @webview : Webview::Webview
    @current_file : String? = nil
    @recent_files : RecentFiles
    @preferences : Preferences
    @git_repo : Git::Repository? = nil
    @initial_file : String? = nil

    def initialize(file_arg : String? = nil)
      @recent_files = RecentFiles.new
      @preferences = Preferences.new
      @webview = Webview::Webview.new(debug: true, title: "Prism — Sans titre")
      @webview.size(@preferences.window_width, @preferences.window_height, Webview::SizeHints::NONE)
      @initial_file = resolve_file_arg(file_arg)
      setup_bindings
    end

    def start
      @webview.html = UI::Html.page
      if file = @initial_file
        json = open_file_at(file)
        @webview.eval("setTimeout(() => { if (window.prism && window.prism.loadFromCli) window.prism.loadFromCli(#{json.to_json}); }, 300);")
      end
      @webview.run
      @preferences.save
      @webview.destroy
    end

    # Appelé par le callback du menu natif macOS
    def handle_menu_action(action_id : String)
      @webview.eval("window.prism.menuAction('#{action_id}')")
    end

    private def resolve_file_arg(arg : String?) : String?
      return nil unless arg
      path = File.expand_path(arg)
      if File.directory?(path)
        Dir.glob(File.join(path, "*.adoc")).first? || Dir.glob(File.join(path, "**/*.adoc")).first?
      elsif File.exists?(path)
        path
      else
        nil
      end
    end

    private def setup_bindings
      # --- Conversion ---
      @webview.bind_typed("convertAsciidoc", String) do |content|
        convert_to_html(content)
      end

      # --- Fichiers ---
      @webview.bind_typed("openFile", String) do |_dummy|
        open_file
      end

      @webview.bind_typed("openFilePath", String) do |path|
        open_file_at(path)
      end

      @webview.bind_typed("saveFile", String, String, String) do |content, stylesheet, path|
        save_file(content, stylesheet, path)
      end

      @webview.bind_typed("saveFileAs", String, String) do |content, stylesheet|
        save_file_as(content, stylesheet)
      end

      @webview.bind_typed("newFile", String) do |_dummy|
        new_file
      end

      @webview.bind_typed("getRecentFiles", String) do |_dummy|
        @recent_files.to_json
      end

      @webview.bind_typed("getPreferences", String) do |_dummy|
        @preferences.to_json
      end

      @webview.bind_typed("savePreferences", String) do |json|
        save_preferences(json)
      end

      # --- Exports ---
      @webview.bind_typed("exportHtml", String, String) do |content, stylesheet|
        export_html(content, stylesheet)
      end

      @webview.bind_typed("exportPdf", String, String) do |content, stylesheet|
        export_pdf(content, stylesheet)
      end

      @webview.bind_typed("exportEpub", String, String) do |content, stylesheet|
        export_epub(content, stylesheet)
      end

      @webview.bind_typed("exportAll", String, String) do |content, stylesheet|
        export_all(content, stylesheet)
      end

      # --- Git ---
      @webview.bind_typed("getGitInfo", String) do |_dummy|
        git_info
      end

      @webview.bind_typed("getGitFileTree", String) do |_dummy|
        @git_repo.try(&.adoc_files) || "[]"
      end

      @webview.bind_typed("getGitFileStatus", String) do |path|
        @git_repo.try(&.file_status(path)) || ""
      end

      @webview.bind_typed("getGitFileLog", String) do |path|
        @git_repo.try(&.file_log(path)) || "[]"
      end

      @webview.bind_typed("getGitDiff", String) do |path|
        @git_repo.try(&.file_diff(path)) || ""
      end
    end

    # --- Conversion ---

    private def convert_to_html(asciidoc : String) : String
      Asciidoctor.convert(asciidoc, {
        "safe"    => "safe",
        "backend" => "html5",
      })
    rescue ex
      "<pre style='color:red'>Erreur de conversion : #{ex.message}</pre>"
    end

    # --- Gestion des fichiers (dialogues natifs AppKit) ---

    private def open_file : String
      path = AppKit::Dialog.open_file("Ouvrir un fichier AsciiDoc", types: "adoc,asciidoc,asc,txt")
      return "" unless path
      open_file_at(path)
    rescue ex
      {error: ex.message}.to_json
    end

    private def open_file_at(path : String) : String
      return "" if path.empty?
      content = File.read(path)
      @current_file = path
      @recent_files.add(path)
      @preferences.last_directory = File.dirname(path)

      @git_repo = Git::Repository.new(path)

      css_path = path.sub(/\.\w+$/, ".css")
      css_content = File.exists?(css_path) ? File.read(css_path) : ""

      update_title(path)
      {
        path:    path,
        content: content,
        css:     css_content,
        git:     @git_repo.try(&.valid?) || false,
        branch:  @git_repo.try(&.current_branch) || "",
      }.to_json
    rescue ex
      {error: ex.message}.to_json
    end

    private def save_file(content : String, stylesheet : String, path : String) : String
      return save_file_as(content, stylesheet) if path.empty?

      File.write(path, content)
      css_path = path.sub(/\.\w+$/, ".css")
      File.write(css_path, stylesheet) unless stylesheet.strip.empty?

      @current_file = path
      @recent_files.add(path)
      update_title(path)
      {success: true, path: path}.to_json
    rescue ex
      {error: ex.message}.to_json
    end

    private def save_file_as(content : String, stylesheet : String) : String
      default_name = @current_file ? File.basename(@current_file.not_nil!) : "document.adoc"
      path = AppKit::Dialog.save_file("Enregistrer sous", default_name: default_name)
      return "" unless path
      path += ".adoc" unless path.includes?(".")
      save_file(content, stylesheet, path)
    rescue ex
      {error: ex.message}.to_json
    end

    private def new_file : String
      @current_file = nil
      @git_repo = nil
      update_title(nil)
      {success: true}.to_json
    end

    private def save_preferences(json : String) : String
      data = JSON.parse(json)
      @preferences.editor_width_pct = data["editor_width_pct"]?.try(&.as_f) || @preferences.editor_width_pct
      @preferences.dark_mode = data["dark_mode"]?.try(&.as_bool) || @preferences.dark_mode
      @preferences.preview_visible = data["preview_visible"]?.try(&.as_bool?) || @preferences.preview_visible
      @preferences.sidebar_visible = data["sidebar_visible"]?.try(&.as_bool?) || @preferences.sidebar_visible
      @preferences.save
      {success: true}.to_json
    rescue ex
      {error: ex.message}.to_json
    end

    # --- Exports (dialogues natifs AppKit) ---

    private def export_html(content : String, stylesheet : String) : String
      html = Asciidoctor.convert(content, {
        "safe"       => "safe",
        "backend"    => "html5",
        "standalone" => "true",
      })
      unless stylesheet.strip.empty?
        html = html.sub("</head>", "<style>#{stylesheet}</style></head>")
      end

      path = AppKit::Dialog.save_file("Exporter en HTML", default_name: base_name("html"))
      return "" unless path
      path += ".html" unless path.ends_with?(".html")

      File.write(path, html)
      {success: true, path: path, format: "HTML"}.to_json
    rescue ex
      {error: ex.message}.to_json
    end

    private def export_pdf(content : String, stylesheet : String) : String
      path = AppKit::Dialog.save_file("Exporter en PDF", default_name: base_name("pdf"))
      return "" unless path
      path += ".pdf" unless path.ends_with?(".pdf")

      doc = Asciidoctor.load(content, {"safe" => "safe", "backend" => "pdf", "outfile" => path})
      AsciidoctorPDF::Converter.new.convert(doc)
      {success: true, path: path, format: "PDF"}.to_json
    rescue ex
      {error: ex.message}.to_json
    end

    private def export_epub(content : String, stylesheet : String) : String
      path = AppKit::Dialog.save_file("Exporter en EPUB", default_name: base_name("epub"))
      return "" unless path
      path += ".epub" unless path.ends_with?(".epub")

      doc = Asciidoctor.load(content, {"safe" => "safe"})
      AsciidoctorEpub::Converter.new.convert_to_file(doc, path)
      {success: true, path: path, format: "EPUB"}.to_json
    rescue ex
      {error: ex.message}.to_json
    end

    private def export_all(content : String, stylesheet : String) : String
      results = [] of String

      html_path = base_export_path("html")
      if html_path
        html = Asciidoctor.convert(content, {"safe" => "safe", "backend" => "html5", "standalone" => "true"})
        unless stylesheet.strip.empty?
          html = html.sub("</head>", "<style>#{stylesheet}</style></head>")
        end
        File.write(html_path, html)
        results << "HTML: #{html_path}"
      end

      pdf_path = base_export_path("pdf")
      if pdf_path
        doc = Asciidoctor.load(content, {"safe" => "safe", "backend" => "pdf", "outfile" => pdf_path})
        AsciidoctorPDF::Converter.new.convert(doc)
        results << "PDF: #{pdf_path}"
      end

      epub_path = base_export_path("epub")
      if epub_path
        doc = Asciidoctor.load(content, {"safe" => "safe"})
        AsciidoctorEpub::Converter.new.convert_to_file(doc, epub_path)
        results << "EPUB: #{epub_path}"
      end

      {success: true, results: results}.to_json
    rescue ex
      {error: ex.message}.to_json
    end

    # --- Git ---

    private def git_info : String
      repo = @git_repo
      return {active: false}.to_json unless repo && repo.valid?
      repo.status_summary
    end

    # --- Helpers ---

    private def update_title(path : String?)
      name = path ? File.basename(path) : "Sans titre"
      branch = @git_repo.try(&.current_branch)
      title = "Prism — #{name}"
      title += " [#{branch}]" if branch && !branch.empty?
      @webview.title = title
    end

    private def base_name(ext : String) : String
      if cf = @current_file
        File.basename(cf).sub(/\.\w+$/, ".#{ext}")
      else
        "document.#{ext}"
      end
    end

    private def base_export_path(ext : String) : String?
      if cf = @current_file
        cf.sub(/\.\w+$/, ".#{ext}")
      else
        nil
      end
    end
  end
end
