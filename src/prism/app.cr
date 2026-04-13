require "./ui/html"

module Prism
  class App
    @webview : Webview::Webview

    def initialize
      @webview = Webview::Webview.new(debug: true, title: "Prism — AsciiDoc Editor")
      @webview.size(1280, 820, Webview::SizeHints::NONE)
      setup_bindings
    end

    def start
      @webview.html = UI::Html.page
      @webview.run
      @webview.destroy
    end

    private def setup_bindings
      @webview.bind_typed("convertAsciidoc", String) do |content|
        convert_to_html(content)
      end

      @webview.bind_typed("exportPdf", String, String) do |content, stylesheet|
        export_pdf(content, stylesheet)
      end

      @webview.bind_typed("exportEpub", String, String) do |content, stylesheet|
        export_epub(content, stylesheet)
      end
    end

    # Conversion AsciiDoc minimale pour le prototype
    # TODO: remplacer par crystal-asciidoctor
    private def convert_to_html(asciidoc : String) : String
      lines = asciidoc.split("\n")
      html = String.build do |io|
        in_list = false
        in_code = false
        in_paragraph = false
        skip_next = false

        lines.each_with_index do |line, i|
          if skip_next
            skip_next = false
            next
          end

          # Attributs (:key: value) — ignorer
          if line.matches?(/^:\w+:/)
            next
          end

          # Bloc de code (espace en début de ligne)
          if line.starts_with?(" ") && !line.strip.empty?
            if in_paragraph
              io << "</p>"
              in_paragraph = false
            end
            if in_list
              io << "</ul>"
              in_list = false
            end
            if !in_code
              io << "<pre><code>"
              in_code = true
            end
            io << escape_html(line.lstrip) << "\n"
            next
          elsif in_code
            io << "</code></pre>"
            in_code = false
          end

          # Titres
          if m = line.match(/^(={1,5})\s+(.+)$/)
            if in_paragraph
              io << "</p>"
              in_paragraph = false
            end
            if in_list
              io << "</ul>"
              in_list = false
            end
            level = m[1].size
            io << "<h#{level}>#{inline_format(m[2])}</h#{level}>"
            next
          end

          # Listes
          if m = line.match(/^\*\s+(.+)$/)
            if in_paragraph
              io << "</p>"
              in_paragraph = false
            end
            if !in_list
              io << "<ul>"
              in_list = true
            end
            io << "<li>#{inline_format(m[1])}</li>"
            next
          elsif in_list
            io << "</ul>"
            in_list = false
          end

          # Ligne vide
          if line.strip.empty?
            if in_paragraph
              io << "</p>"
              in_paragraph = false
            end
            next
          end

          # Paragraphe
          if !in_paragraph
            io << "<p>"
            in_paragraph = true
          else
            io << " "
          end
          io << inline_format(line)
        end

        # Fermer les blocs ouverts
        io << "</code></pre>" if in_code
        io << "</ul>" if in_list
        io << "</p>" if in_paragraph
      end
      html
    end

    private def inline_format(text : String) : String
      result = escape_html(text)
      # Liens
      result = result.gsub(/https?:\/\/\S+\[([^\]]+)\]/) do |match|
        url = match.split("[").first
        label = match.match(/\[([^\]]+)\]/).try(&.[1]) || url
        %(<a href="#{url}">#{label}</a>)
      end
      # Gras
      result = result.gsub(/\*([^*]+)\*/, "<strong>\\1</strong>")
      # Italique
      result = result.gsub(/_([^_]+)_/, "<em>\\1</em>")
      # Code inline
      result = result.gsub(/`([^`]+)`/, "<code>\\1</code>")
      result
    end

    private def escape_html(text : String) : String
      text.gsub("&", "&amp;").gsub("<", "&lt;").gsub(">", "&gt;")
    end

    private def export_pdf(content : String, stylesheet : String) : String
      # TODO: intégrer crystal-asciidoctor-pdf
      "Export PDF — bientôt disponible"
    end

    private def export_epub(content : String, stylesheet : String) : String
      # TODO: intégrer crystal-asciidoctor-epub3
      "Export EPUB — bientôt disponible"
    end
  end
end
