module Prism
  module UI
    module Html
      # Le bundle JS est embarqué dans le binaire à la compilation
      EDITOR_JS = {{ read_file("assets/editor.bundle.js") }}

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
            <div class="toolbar-left">
              <svg class="app-logo" viewBox="0 0 24 24" width="18" height="18">
                <polygon points="8,4 12,2 16,4 18,10 16,18 12,20 8,18 6,10" fill="none" stroke="#6e6e73" stroke-width="1.4" stroke-linejoin="round"/>
                <polygon points="12,2 12,20 8,18 8,4" fill="#a0aec0" opacity="0.3"/>
                <polygon points="12,2 16,4 16,18 12,20" fill="#718096" opacity="0.2"/>
                <line x1="6,10" y1="0" x2="18,10" y2="0" stroke="#0071e3" stroke-width="1" opacity="0.5"/>
              </svg>
              <span class="app-title">Prism</span>
            </div>
            <div class="toolbar-actions">
              <button id="btn-export-pdf">Export PDF</button>
              <button id="btn-export-epub">Export EPUB</button>
            </div>
          </div>

          <div class="panels">
            <div class="panel editor-panel">
              <div class="panel-header">
                <span class="tab active" data-tab="asciidoc">AsciiDoc</span>
                <span class="tab" data-tab="style">Style</span>
              </div>
              <div id="editor-asciidoc" class="editor-container"></div>
              <div id="editor-style" class="editor-container hidden"></div>
            </div>

            <div class="divider" id="divider"></div>

            <div class="panel preview-panel">
              <div class="panel-header">
                <span>Prévisualisation</span>
              </div>
              <iframe id="preview" sandbox="allow-same-origin"></iframe>
            </div>
          </div>

          <script>#{EDITOR_JS}</script>
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
          padding: 6px 16px;
          background: linear-gradient(180deg, #fafafa 0%, #f0f0f2 100%);
          border-bottom: 1px solid #d2d2d7;
          -webkit-app-region: drag;
        }

        .toolbar-left {
          display: flex;
          align-items: center;
          gap: 8px;
        }

        .app-title {
          font-size: 13px;
          font-weight: 600;
          color: #6e6e73;
          letter-spacing: 0.5px;
        }

        .toolbar-actions {
          display: flex;
          gap: 6px;
          -webkit-app-region: no-drag;
        }

        .toolbar-actions button {
          padding: 4px 12px;
          border: 1px solid #d2d2d7;
          border-radius: 5px;
          background: linear-gradient(180deg, #ffffff 0%, #f5f5f7 100%);
          color: #1d1d1f;
          font-size: 12px;
          font-family: inherit;
          cursor: pointer;
          transition: all 0.15s;
          box-shadow: 0 0.5px 1px rgba(0,0,0,0.05);
        }

        .toolbar-actions button:hover {
          background: linear-gradient(180deg, #f5f5f7 0%, #e8e8ed 100%);
        }

        .toolbar-actions button:active {
          background: #e8e8ed;
          box-shadow: inset 0 1px 2px rgba(0,0,0,0.06);
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

        .divider {
          width: 5px;
          cursor: col-resize;
          background: #e5e5e7;
          transition: background 0.15s;
        }

        .divider:hover {
          background: #0071e3;
        }

        .panel-header {
          display: flex;
          gap: 0;
          padding: 0 12px;
          background: #fafafa;
          border-bottom: 1px solid #e5e5e7;
          font-size: 12px;
          color: #86868b;
          min-height: 32px;
          align-items: stretch;
        }

        .tab {
          padding: 0 14px;
          cursor: pointer;
          border-bottom: 2px solid transparent;
          display: flex;
          align-items: center;
          transition: all 0.15s;
          user-select: none;
        }

        .tab.active {
          color: #0071e3;
          border-bottom-color: #0071e3;
        }

        .tab:hover:not(.active) {
          color: #1d1d1f;
        }

        .editor-container {
          flex: 1;
          overflow: hidden;
        }

        .editor-container .cm-editor {
          height: 100%;
        }

        .hidden { display: none !important; }

        #preview {
          flex: 1;
          border: none;
          background: #ffffff;
        }

        /* Scrollbar macOS-like */
        ::-webkit-scrollbar {
          width: 8px;
          height: 8px;
        }
        ::-webkit-scrollbar-track {
          background: transparent;
        }
        ::-webkit-scrollbar-thumb {
          background: rgba(0,0,0,0.15);
          border-radius: 4px;
        }
        ::-webkit-scrollbar-thumb:hover {
          background: rgba(0,0,0,0.25);
        }
        CSS
      end
    end
  end
end
