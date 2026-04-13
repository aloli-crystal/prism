module Prism
  module UI
    module Html
      def self.page : String
        <<-HTML
        <!DOCTYPE html>
        <html lang="fr">
        <head>
          <meta charset="UTF-8">
          <style>#{css}</style>
        </head>
        <body>
          <div class="toolbar">
            <h1 class="app-title">Prism</h1>
            <div class="toolbar-actions">
              <button onclick="doExportPdf()">Export PDF</button>
              <button onclick="doExportEpub()">Export EPUB</button>
            </div>
          </div>

          <div class="panels">
            <div class="panel editor-panel">
              <div class="panel-header">
                <span class="tab active" data-tab="asciidoc">AsciiDoc</span>
                <span class="tab" data-tab="style">Style</span>
              </div>
              <textarea id="editor-asciidoc" class="editor" spellcheck="false">= Mon document
:author: Philippe

== Introduction

Ceci est un *prototype* de l'éditeur _Prism_.

== Fonctionnalités prévues

* Édition AsciiDoc avec coloration syntaxique
* Prévisualisation live
* Export HTML, PDF et EPUB
* Éditeur de feuille de style</textarea>
              <textarea id="editor-style" class="editor hidden" spellcheck="false">/* Personnalisez le rendu ici */

h1 {
  color: #2d3748;
  border-bottom: 2px solid #4299e1;
  padding-bottom: 0.3em;
}

h2 {
  color: #4a5568;
}

strong {
  color: #e53e3e;
}

body {
  font-family: Georgia, serif;
  line-height: 1.7;
  max-width: 42em;
  padding: 1em;
}</textarea>
            </div>

            <div class="panel preview-panel">
              <div class="panel-header">
                <span>Prévisualisation</span>
              </div>
              <iframe id="preview" sandbox="allow-same-origin"></iframe>
            </div>
          </div>

          <script>#{js}</script>
        </body>
        </html>
        HTML
      end

      private def self.css : String
        <<-CSS
        * { margin: 0; padding: 0; box-sizing: border-box; }

        body {
          font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
          background: #f7f7f8;
          color: #1d1d1f;
          height: 100vh;
          display: flex;
          flex-direction: column;
          overflow: hidden;
        }

        .toolbar {
          display: flex;
          align-items: center;
          justify-content: space-between;
          padding: 8px 16px;
          background: #ffffff;
          border-bottom: 1px solid #e5e5e7;
          -webkit-app-region: drag;
        }

        .app-title {
          font-size: 14px;
          font-weight: 600;
          color: #6e6e73;
          letter-spacing: 1px;
          text-transform: uppercase;
        }

        .toolbar-actions {
          display: flex;
          gap: 8px;
          -webkit-app-region: no-drag;
        }

        .toolbar-actions button {
          padding: 5px 14px;
          border: 1px solid #d2d2d7;
          border-radius: 6px;
          background: #ffffff;
          color: #1d1d1f;
          font-size: 12px;
          cursor: pointer;
          transition: background 0.15s;
        }

        .toolbar-actions button:hover {
          background: #f0f0f2;
        }

        .panels {
          display: flex;
          flex: 1;
          overflow: hidden;
        }

        .panel {
          flex: 1;
          display: flex;
          flex-direction: column;
          min-width: 0;
        }

        .editor-panel {
          border-right: 1px solid #e5e5e7;
        }

        .panel-header {
          display: flex;
          gap: 0;
          padding: 0 12px;
          background: #fafafa;
          border-bottom: 1px solid #e5e5e7;
          font-size: 12px;
          color: #86868b;
        }

        .tab {
          padding: 8px 14px;
          cursor: pointer;
          border-bottom: 2px solid transparent;
          transition: all 0.15s;
        }

        .tab.active {
          color: #0071e3;
          border-bottom-color: #0071e3;
        }

        .tab:hover:not(.active) {
          color: #1d1d1f;
        }

        .editor {
          flex: 1;
          padding: 16px;
          border: none;
          resize: none;
          font-family: "SF Mono", "Fira Code", "Menlo", monospace;
          font-size: 13px;
          line-height: 1.6;
          background: #ffffff;
          color: #1d1d1f;
          outline: none;
          tab-size: 2;
        }

        .hidden { display: none; }

        #preview {
          flex: 1;
          border: none;
          background: #ffffff;
        }
        CSS
      end

      private def self.js : String
        <<-JS
        const editorAsciidoc = document.getElementById('editor-asciidoc');
        const editorStyle = document.getElementById('editor-style');
        const preview = document.getElementById('preview');
        const tabs = document.querySelectorAll('.tab');

        // Onglets
        tabs.forEach(tab => {
          tab.addEventListener('click', () => {
            tabs.forEach(t => t.classList.remove('active'));
            tab.classList.add('active');
            const target = tab.dataset.tab;
            editorAsciidoc.classList.toggle('hidden', target !== 'asciidoc');
            editorStyle.classList.toggle('hidden', target !== 'style');
          });
        });

        // Prévisualisation live
        let debounceTimer;

        function updatePreview() {
          clearTimeout(debounceTimer);
          debounceTimer = setTimeout(async () => {
            const html = await convertAsciidoc(editorAsciidoc.value);
            const style = editorStyle.value;
            const doc = preview.contentDocument;
            doc.open();
            doc.write('<html><head><style>' + style + '</style></head><body>' + html + '</body></html>');
            doc.close();
          }, 300);
        }

        editorAsciidoc.addEventListener('input', updatePreview);
        editorStyle.addEventListener('input', updatePreview);

        // Export
        async function doExportPdf() {
          const result = await exportPdf(editorAsciidoc.value, editorStyle.value);
          alert(result);
        }

        async function doExportEpub() {
          const result = await exportEpub(editorAsciidoc.value, editorStyle.value);
          alert(result);
        }

        // Initialisation
        updatePreview();
        JS
      end
    end
  end
end
