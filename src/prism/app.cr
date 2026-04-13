require "./ui/html"

module Prism
  class App
    @webview : Webview::Webview

    def initialize
      @webview = Webview::Webview.new(debug: true)
      @webview.title = "Prism — AsciiDoc Editor"
      @webview.size(1200, 800, Webview::SizeHints::NONE)
      setup_bindings
    end

    def start
      @webview.navigate_html(UI::Html.page)
      @webview.run
      @webview.destroy
    end

    private def setup_bindings
      # Crystal -> JS : le frontend appelle ces fonctions
      @webview.bind("convertAsciidoc") do |params|
        content = params[0].as_s
        convert_to_html(content)
      end

      @webview.bind("exportPdf") do |params|
        content = params[0].as_s
        stylesheet = params[1].as_s
        export_pdf(content, stylesheet)
      end

      @webview.bind("exportEpub") do |params|
        content = params[0].as_s
        stylesheet = params[1].as_s
        export_epub(content, stylesheet)
      end
    end

    private def convert_to_html(asciidoc : String) : String
      # TODO: intégrer crystal-asciidoctor
      # Pour le prototype, conversion minimale
      html = asciidoc
        .gsub(/^= (.+)$/m, "<h1>\\1</h1>")
        .gsub(/^== (.+)$/m, "<h2>\\1</h2>")
        .gsub(/^=== (.+)$/m, "<h3>\\1</h3>")
        .gsub(/\*(.+?)\*/, "<strong>\\1</strong>")
        .gsub(/_(.+?)_/, "<em>\\1</em>")
        .gsub(/\n\n/, "</p><p>")
      "<p>#{html}</p>"
    end

    private def export_pdf(content : String, stylesheet : String) : String
      # TODO: intégrer crystal-asciidoctor-pdf
      "PDF export not yet implemented"
    end

    private def export_epub(content : String, stylesheet : String) : String
      # TODO: intégrer crystal-asciidoctor-epub3
      "EPUB export not yet implemented"
    end
  end
end
