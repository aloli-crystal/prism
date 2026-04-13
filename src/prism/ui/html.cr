module Prism
  module UI
    module Html
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
              <svg class="app-logo" viewBox="0 0 24 24" width="16" height="16">
                <polygon points="8,4 12,2 16,4 18,10 16,18 12,20 8,18 6,10" fill="none" stroke="currentColor" stroke-width="1.4" stroke-linejoin="round" opacity="0.5"/>
              </svg>
              <span class="app-title">Prism</span>
            </div>
            <div class="toolbar-actions">
              <button id="btn-new" title="Cmd+N">Nouveau</button>
              <button id="btn-open" title="Cmd+O">Ouvrir</button>
              <button id="btn-save" title="Cmd+S">Sauver</button>
              <span class="toolbar-sep"></span>
              <button id="btn-export-html" title="Cmd+E">HTML</button>
              <button id="btn-export-pdf">PDF</button>
              <button id="btn-export-epub">EPUB</button>
              <button id="btn-export-all" title="Cmd+Shift+E">Tout</button>
              <span class="toolbar-sep"></span>
              <button id="btn-toggle-sidebar" title="Cmd+B">☰</button>
              <button id="btn-toggle-preview" title="Cmd+P">⊟</button>
              <button id="btn-dark-mode" title="Cmd+D">◑</button>
              <button id="btn-zen" title="Cmd+Enter">⤢</button>
            </div>
          </div>

          <div class="main-area">
            <div class="sidebar hidden">
              <div class="sidebar-header">Explorateur</div>
              <div class="sidebar-content"></div>
            </div>

            <div class="panels">
              <div class="panel editor-panel">
                <div class="panel-header">
                  <span class="tab active" data-tab="asciidoc" data-group="editor">AsciiDoc</span>
                  <span class="tab" data-tab="html" data-group="editor">HTML</span>
                  <span class="tab" data-tab="style" data-group="editor">Style</span>
                </div>
                <div id="editor-asciidoc" class="editor-container"></div>
                <div id="editor-html" class="editor-container hidden"></div>
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
          </div>

          <div class="status-bar">
            <span id="status-file">Sans titre</span>
            <span id="status-git" style="display:none"></span>
            <span class="status-right">
              <span class="shortcut-hint">⌘S sauver</span>
              <span class="shortcut-hint">⌘B sidebar</span>
              <span class="shortcut-hint">⌘P aperçu</span>
              <span class="shortcut-hint">⌘D thème</span>
              <span class="shortcut-hint">⌘↵ zen</span>
            </span>
          </div>

          <script>#{EDITOR_JS}</script>
        </body>
        </html>
        HTML
      end

      private def self.css : String
        <<-CSS
        :root {
          --bg: #f7f7f8;
          --bg2: #ffffff;
          --bg3: #fafafa;
          --border: #e5e5e7;
          --border2: #d2d2d7;
          --text: #1d1d1f;
          --text2: #86868b;
          --text3: #6e6e73;
          --accent: #0071e3;
          --toolbar-bg: linear-gradient(180deg, #fafafa 0%, #f0f0f2 100%);
          --btn-bg: linear-gradient(180deg, #ffffff 0%, #f5f5f7 100%);
          --btn-hover: linear-gradient(180deg, #f5f5f7 0%, #e8e8ed 100%);
          --sidebar-bg: #f0f0f2;
        }

        body.dark {
          --bg: #1e1e1e;
          --bg2: #252526;
          --bg3: #2d2d2d;
          --border: #3c3c3c;
          --border2: #4a4a4a;
          --text: #d4d4d4;
          --text2: #808080;
          --text3: #999;
          --accent: #4fc1ff;
          --toolbar-bg: linear-gradient(180deg, #2d2d2d 0%, #252526 100%);
          --btn-bg: linear-gradient(180deg, #3c3c3c 0%, #333 100%);
          --btn-hover: linear-gradient(180deg, #4a4a4a 0%, #3c3c3c 100%);
          --sidebar-bg: #252526;
        }

        * { margin: 0; padding: 0; box-sizing: border-box; }

        body {
          font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
          background: var(--bg);
          color: var(--text);
          height: 100vh;
          display: flex;
          flex-direction: column;
          overflow: hidden;
        }

        /* --- Zen mode --- */
        body.zen .toolbar,
        body.zen .status-bar,
        body.zen .sidebar,
        body.zen .preview-panel,
        body.zen #divider,
        body.zen .panel-header { display: none !important; }
        body.zen .editor-container { border-radius: 0; }

        /* --- Toolbar --- */
        .toolbar {
          display: flex;
          align-items: center;
          justify-content: space-between;
          padding: 4px 10px;
          background: var(--toolbar-bg);
          border-bottom: 1px solid var(--border2);
          -webkit-app-region: drag;
          min-height: 30px;
        }

        .toolbar-left { display: flex; align-items: center; gap: 6px; }
        .app-title { font-size: 12px; font-weight: 600; color: var(--text3); letter-spacing: 0.5px; }

        .toolbar-actions {
          display: flex; align-items: center; gap: 3px;
          -webkit-app-region: no-drag;
        }
        .toolbar-sep { width: 1px; height: 16px; background: var(--border2); margin: 0 3px; }

        .toolbar-actions button {
          padding: 2px 8px;
          border: 1px solid var(--border2);
          border-radius: 4px;
          background: var(--btn-bg);
          color: var(--text);
          font-size: 11px;
          font-family: inherit;
          cursor: pointer;
          transition: all 0.12s;
          white-space: nowrap;
          line-height: 1.5;
        }
        .toolbar-actions button:hover { background: var(--btn-hover); }
        .toolbar-actions button:active { opacity: 0.8; }

        /* --- Main area --- */
        .main-area { display: flex; flex: 1; overflow: hidden; }

        /* --- Sidebar --- */
        .sidebar {
          width: 220px;
          background: var(--sidebar-bg);
          border-right: 1px solid var(--border);
          display: flex;
          flex-direction: column;
          overflow-y: auto;
          flex-shrink: 0;
        }
        .sidebar-header {
          padding: 8px 12px;
          font-size: 11px;
          font-weight: 600;
          color: var(--text2);
          text-transform: uppercase;
          letter-spacing: 0.5px;
          border-bottom: 1px solid var(--border);
        }
        .sidebar-content { flex: 1; overflow-y: auto; padding: 4px 0; }
        .sidebar-section { margin-bottom: 8px; }
        .sidebar-title {
          padding: 6px 12px 2px;
          font-size: 10px;
          font-weight: 600;
          color: var(--text2);
          text-transform: uppercase;
          letter-spacing: 0.3px;
        }
        .sidebar-item {
          padding: 4px 12px 4px 16px;
          font-size: 12px;
          cursor: pointer;
          color: var(--text);
          white-space: nowrap;
          overflow: hidden;
          text-overflow: ellipsis;
          transition: background 0.1s;
        }
        .sidebar-item:hover { background: var(--accent); color: white; border-radius: 3px; margin: 0 4px; padding-left: 12px; }
        .sidebar-hint { padding: 6px 12px; font-size: 11px; color: var(--text2); font-style: italic; }

        .hidden { display: none !important; }

        /* --- Panels --- */
        .panels { display: flex; flex: 1; overflow: hidden; }
        .panel { flex: 1; display: flex; flex-direction: column; min-width: 0; }

        .divider {
          width: 4px; cursor: col-resize; background: var(--border);
          transition: background 0.12s; flex-shrink: 0;
        }
        .divider:hover { background: var(--accent); }

        .panel-header {
          display: flex; padding: 0 10px;
          background: var(--bg3); border-bottom: 1px solid var(--border);
          font-size: 11px; color: var(--text2);
          min-height: 28px; align-items: stretch;
        }
        .tab {
          padding: 0 10px; cursor: pointer;
          border-bottom: 2px solid transparent;
          display: flex; align-items: center;
          transition: all 0.12s; user-select: none;
        }
        .tab.active { color: var(--accent); border-bottom-color: var(--accent); }
        .tab:hover:not(.active) { color: var(--text); }

        .editor-container { flex: 1; overflow: hidden; }
        .editor-container .cm-editor { height: 100%; }

        #preview { flex: 1; border: none; background: var(--bg2); }

        /* --- Status bar --- */
        .status-bar {
          display: flex; align-items: center; justify-content: space-between;
          padding: 1px 10px; background: var(--accent); color: white;
          font-size: 11px; min-height: 20px;
        }
        .status-right { display: flex; gap: 10px; }
        .shortcut-hint { opacity: 0.7; font-size: 10px; }
        #status-git { margin-left: 12px; opacity: 0.85; }

        /* --- Scrollbar --- */
        ::-webkit-scrollbar { width: 7px; height: 7px; }
        ::-webkit-scrollbar-track { background: transparent; }
        ::-webkit-scrollbar-thumb { background: rgba(128,128,128,0.3); border-radius: 4px; }
        ::-webkit-scrollbar-thumb:hover { background: rgba(128,128,128,0.5); }
        CSS
      end
    end
  end
end
