require "./ui/html"

module Prism
  class App
    @webview : Webview::Webview
    @current_file : String? = nil
    @is_modified : Bool = false

    def initialize
      @webview = Webview::Webview.new(debug: true, title: "Prism — Sans titre")
      @webview.size(1280, 820, Webview::SizeHints::NONE)
      setup_bindings
    end

    def start
      @webview.html = UI::Html.page
      @webview.run
      @webview.destroy
    end

    private def setup_bindings
      # Conversion AsciiDoc → HTML (via crystal-asciidoctor)
      @webview.bind_typed("convertAsciidoc", String) do |content|
        convert_to_html(content)
      end

      # Export HTML standalone
      @webview.bind_typed("exportHtml", String, String) do |content, stylesheet|
        export_html(content, stylesheet)
      end

      # Export PDF
      @webview.bind_typed("exportPdf", String, String) do |content, stylesheet|
        export_pdf(content, stylesheet)
      end

      # Export EPUB
      @webview.bind_typed("exportEpub", String, String) do |content, stylesheet|
        export_epub(content, stylesheet)
      end

      # Ouvrir un fichier
      @webview.bind_typed("openFile", String) do |_dummy|
        open_file
      end

      # Sauvegarder
      @webview.bind_typed("saveFile", String, String, String) do |content, stylesheet, path|
        save_file(content, stylesheet, path)
      end

      # Sauvegarder sous
      @webview.bind_typed("saveFileAs", String, String) do |content, stylesheet|
        save_file_as(content, stylesheet)
      end

      # Nouveau fichier
      @webview.bind_typed("newFile", String) do |_dummy|
        new_file
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

    # --- Gestion des fichiers ---

    private def open_file : String
      result = run_dialog("osascript", "-e",
        %(choose file of type {"adoc", "asciidoc", "asc", "txt"} with prompt "Ouvrir un fichier AsciiDoc"))
      return "" if result.empty?

      path = result.gsub("alias ", "").strip
      # Convertir le chemin AppleScript (alias Macintosh HD:Users:...) en POSIX
      posix = run_dialog("osascript", "-e", %(POSIX path of "#{path}"))
      posix = posix.strip
      return "" if posix.empty?

      content = File.read(posix)
      @current_file = posix

      # Charger le CSS associé s'il existe
      css_path = posix.sub(/\.\w+$/, ".css")
      css_content = File.exists?(css_path) ? File.read(css_path) : ""

      update_title(posix)
      {path: posix, content: content, css: css_content}.to_json
    rescue ex
      {error: ex.message}.to_json
    end

    private def save_file(content : String, stylesheet : String, path : String) : String
      if path.empty?
        return save_file_as(content, stylesheet)
      end

      File.write(path, content)
      # Sauvegarder le CSS à côté
      css_path = path.sub(/\.\w+$/, ".css")
      File.write(css_path, stylesheet) unless stylesheet.strip.empty?

      @current_file = path
      @is_modified = false
      update_title(path)
      {success: true, path: path}.to_json
    rescue ex
      {error: ex.message}.to_json
    end

    private def save_file_as(content : String, stylesheet : String) : String
      default_name = @current_file ? File.basename(@current_file.not_nil!) : "document.adoc"
      result = run_dialog("osascript", "-e",
        %(choose file name with prompt "Sauvegarder sous" default name "#{default_name}"))
      return "" if result.empty?

      path = result.gsub("file ", "").strip
      posix = run_dialog("osascript", "-e", %(POSIX path of "#{path}")).strip
      return "" if posix.empty?

      # Ajouter .adoc si pas d'extension
      posix += ".adoc" unless posix.includes?(".")

      save_file(content, stylesheet, posix)
    rescue ex
      {error: ex.message}.to_json
    end

    private def new_file : String
      @current_file = nil
      @is_modified = false
      update_title(nil)
      {success: true}.to_json
    end

    # --- Exports ---

    private def export_html(content : String, stylesheet : String) : String
      html = Asciidoctor.convert(content, {
        "safe"       => "safe",
        "backend"    => "html5",
        "standalone" => "true",
      })

      # Injecter le style personnalisé
      unless stylesheet.strip.empty?
        html = html.sub("</head>", "<style>#{stylesheet}</style></head>")
      end

      path = choose_save_path("document.html", "HTML")
      return "" if path.empty?

      File.write(path, html)
      {success: true, path: path, format: "HTML"}.to_json
    rescue ex
      {error: ex.message}.to_json
    end

    private def export_pdf(content : String, stylesheet : String) : String
      path = choose_save_path("document.pdf", "PDF")
      return "" if path.empty?
      path += ".pdf" unless path.ends_with?(".pdf")

      doc = Asciidoctor.load(content, {"safe" => "safe", "backend" => "pdf", "outfile" => path})
      AsciidoctorPDF::Converter.new.convert(doc)

      {success: true, path: path, format: "PDF"}.to_json
    rescue ex
      {error: ex.message}.to_json
    end

    private def export_epub(content : String, stylesheet : String) : String
      path = choose_save_path("document.epub", "EPUB")
      return "" if path.empty?
      path += ".epub" unless path.ends_with?(".epub")

      doc = Asciidoctor.load(content, {"safe" => "safe"})
      AsciidoctorEpub::Converter.new.convert_to_file(doc, path)

      {success: true, path: path, format: "EPUB"}.to_json
    rescue ex
      {error: ex.message}.to_json
    end

    # --- Helpers ---

    private def update_title(path : String?)
      name = path ? File.basename(path) : "Sans titre"
      @webview.title = "Prism — #{name}"
    end

    private def choose_save_path(default_name : String, format : String) : String
      result = run_dialog("osascript", "-e",
        %(choose file name with prompt "Exporter en #{format}" default name "#{default_name}"))
      return "" if result.empty?

      path = result.gsub("file ", "").strip
      posix = run_dialog("osascript", "-e", %(POSIX path of "#{path}")).strip
      posix
    end

    private def run_dialog(cmd : String, *args : String) : String
      output = IO::Memory.new
      status = Process.run(cmd, args.to_a, output: output, error: Process::Redirect::Close)
      status.success? ? output.to_s : ""
    end
  end
end
