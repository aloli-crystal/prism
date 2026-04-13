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
              <svg class="app-logo" viewBox="0 0 24 24" width="14" height="14">
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
              <button id="btn-minimap" title="Cmd+M">▮</button>
              <button id="btn-dark-mode" title="Cmd+D">◑</button>
              <button id="btn-zen" title="Cmd+Enter">⤢</button>
            </div>
          </div>

          <div id="breadcrumb"><span class="bc-item">Document</span></div>

          <div class="format-bar">
            <button data-format="bold" title="Gras (Cmd+Shift+B)"><b>G</b></button>
            <button data-format="italic" title="Italique (Cmd+I)"><i>I</i></button>
            <button data-format="mono" title="Monospace">M</button>
            <span class="toolbar-sep"></span>
            <button data-format="h1" title="Titre 1">H1</button>
            <button data-format="h2" title="Titre 2">H2</button>
            <button data-format="h3" title="Titre 3">H3</button>
            <span class="toolbar-sep"></span>
            <button data-format="ul" title="Liste">•</button>
            <button data-format="ol" title="Liste numérotée">1.</button>
            <button data-format="link" title="Lien">🔗</button>
            <button data-format="image" title="Image">🖼</button>
            <button data-format="code" title="Code">{ }</button>
            <button data-format="quote" title="Citation">❝</button>
            <button data-format="table" title="Tableau">⊞</button>
            <button data-format="admonition" title="Note">ℹ</button>
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
                <div class="editor-with-minimap">
                  <div class="editor-area">
                    <div id="editor-asciidoc" class="editor-container"></div>
                    <div id="editor-html" class="editor-container hidden"></div>
                    <div id="editor-style" class="editor-container hidden"></div>
                  </div>
                  <div id="minimap" class="minimap">
                    <div class="mm-lines"></div>
                    <div class="mm-viewport"></div>
                  </div>
                </div>
              </div>

              <div class="divider" id="divider"></div>

              <div class="panel preview-panel">
                <div class="panel-header"><span>Prévisualisation</span></div>
                <iframe id="preview" sandbox="allow-same-origin"></iframe>
              </div>
            </div>
          </div>

          <div class="status-bar">
            <span id="status-file">Sans titre</span>
            <span id="status-git" style="display:none"></span>
            <span class="status-right">
              <span id="status-pos">Ln 1, Col 1</span>
              <span class="shortcut-hint">⌘F chercher</span>
              <span class="shortcut-hint">⌘S sauver</span>
              <span class="shortcut-hint">⌘P aperçu</span>
              <span class="shortcut-hint">⌘M minimap</span>
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
          --bg: #f7f7f8; --bg2: #ffffff; --bg3: #fafafa;
          --border: #e5e5e7; --border2: #d2d2d7;
          --text: #1d1d1f; --text2: #86868b; --text3: #6e6e73;
          --accent: #0071e3;
          --toolbar-bg: linear-gradient(180deg, #fafafa 0%, #f0f0f2 100%);
          --btn-bg: linear-gradient(180deg, #ffffff 0%, #f5f5f7 100%);
          --btn-hover: linear-gradient(180deg, #f5f5f7 0%, #e8e8ed 100%);
          --sidebar-bg: #f0f0f2;
        }
        body.dark {
          --bg: #1e1e1e; --bg2: #252526; --bg3: #2d2d2d;
          --border: #3c3c3c; --border2: #4a4a4a;
          --text: #d4d4d4; --text2: #808080; --text3: #999;
          --accent: #4fc1ff;
          --toolbar-bg: linear-gradient(180deg, #2d2d2d 0%, #252526 100%);
          --btn-bg: linear-gradient(180deg, #3c3c3c 0%, #333 100%);
          --btn-hover: linear-gradient(180deg, #4a4a4a 0%, #3c3c3c 100%);
          --sidebar-bg: #252526;
        }
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
          font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
          background: var(--bg); color: var(--text);
          height: 100vh; display: flex; flex-direction: column; overflow: hidden;
        }

        /* Zen */
        body.zen .toolbar, body.zen .status-bar, body.zen .sidebar,
        body.zen .preview-panel, body.zen #divider, body.zen .panel-header,
        body.zen .format-bar, body.zen #breadcrumb, body.zen .minimap { display: none !important; }

        /* Toolbar */
        .toolbar {
          display: flex; align-items: center; justify-content: space-between;
          padding: 3px 10px; background: var(--toolbar-bg);
          border-bottom: 1px solid var(--border2);
          -webkit-app-region: drag; min-height: 28px;
        }
        .toolbar-left { display: flex; align-items: center; gap: 6px; }
        .app-title { font-size: 12px; font-weight: 600; color: var(--text3); letter-spacing: .5px; }
        .toolbar-actions { display: flex; align-items: center; gap: 2px; -webkit-app-region: no-drag; }
        .toolbar-sep { width: 1px; height: 14px; background: var(--border2); margin: 0 3px; }
        .toolbar-actions button, .format-bar button {
          padding: 2px 7px; border: 1px solid var(--border2); border-radius: 4px;
          background: var(--btn-bg); color: var(--text); font-size: 11px;
          font-family: inherit; cursor: pointer; transition: all .1s; white-space: nowrap; line-height: 1.4;
        }
        .toolbar-actions button:hover, .format-bar button:hover { background: var(--btn-hover); }
        .toolbar-actions button:active, .format-bar button:active { opacity: .7; }

        /* Breadcrumb */
        #breadcrumb {
          display: flex; align-items: center; gap: 2px;
          padding: 2px 12px; background: var(--bg3);
          border-bottom: 1px solid var(--border);
          font-size: 11px; color: var(--text2); min-height: 22px; overflow: hidden;
        }
        .bc-item { cursor: pointer; padding: 1px 4px; border-radius: 3px; white-space: nowrap; }
        .bc-item:hover { background: var(--accent); color: white; }
        .bc-sep { color: var(--border2); margin: 0 1px; }

        /* Format bar */
        .format-bar {
          display: flex; align-items: center; gap: 2px;
          padding: 2px 10px; background: var(--bg3);
          border-bottom: 1px solid var(--border);
          min-height: 26px;
        }
        .format-bar button { font-size: 11px; min-width: 24px; text-align: center; }

        /* Main */
        .main-area { display: flex; flex: 1; overflow: hidden; }

        /* Sidebar */
        .sidebar {
          width: 200px; background: var(--sidebar-bg);
          border-right: 1px solid var(--border);
          display: flex; flex-direction: column; overflow-y: auto; flex-shrink: 0;
        }
        .sidebar-header {
          padding: 6px 10px; font-size: 10px; font-weight: 600;
          color: var(--text2); text-transform: uppercase; letter-spacing: .5px;
          border-bottom: 1px solid var(--border);
        }
        .sidebar-content { flex: 1; overflow-y: auto; padding: 2px 0; }
        .sidebar-section { margin-bottom: 6px; }
        .sidebar-title { padding: 4px 10px 1px; font-size: 10px; font-weight: 600; color: var(--text2); text-transform: uppercase; }
        .sidebar-item {
          padding: 3px 10px 3px 14px; font-size: 11px; cursor: pointer; color: var(--text);
          white-space: nowrap; overflow: hidden; text-overflow: ellipsis; transition: background .1s;
        }
        .sidebar-item:hover { background: var(--accent); color: white; border-radius: 3px; margin: 0 3px; padding-left: 11px; }
        .sidebar-hint { padding: 4px 10px; font-size: 10px; color: var(--text2); font-style: italic; }
        .hidden { display: none !important; }

        /* Panels */
        .panels { display: flex; flex: 1; overflow: hidden; }
        .panel { flex: 1; display: flex; flex-direction: column; min-width: 0; }
        .divider { width: 4px; cursor: col-resize; background: var(--border); transition: background .1s; flex-shrink: 0; }
        .divider:hover { background: var(--accent); }
        .panel-header {
          display: flex; padding: 0 10px; background: var(--bg3);
          border-bottom: 1px solid var(--border);
          font-size: 11px; color: var(--text2); min-height: 26px; align-items: stretch;
        }
        .tab {
          padding: 0 10px; cursor: pointer; border-bottom: 2px solid transparent;
          display: flex; align-items: center; transition: all .1s; user-select: none;
        }
        .tab.active { color: var(--accent); border-bottom-color: var(--accent); }
        .tab:hover:not(.active) { color: var(--text); }

        /* Editor + Minimap */
        .editor-with-minimap { flex: 1; display: flex; overflow: hidden; }
        .editor-area { flex: 1; display: flex; flex-direction: column; overflow: hidden; }
        .editor-container { flex: 1; overflow: hidden; }
        .editor-container .cm-editor { height: 100%; }

        /* Minimap */
        .minimap {
          width: 60px; background: var(--bg3);
          border-left: 1px solid var(--border);
          position: relative; overflow: hidden; flex-shrink: 0; cursor: pointer;
        }
        .mm-lines { padding: 4px 2px; }
        .mm-line { height: 2px; margin-bottom: 0.5px; background: var(--text2); opacity: 0.2; border-radius: 1px; }
        .mm-heading { opacity: 0.7; background: var(--accent); height: 2.5px; }
        .mm-list { opacity: 0.3; }
        .mm-block { opacity: 0.5; background: var(--text3); }
        .mm-comment { opacity: 0.15; }
        .mm-empty { opacity: 0; height: 1.5px; }
        .mm-viewport {
          position: absolute; left: 0; right: 0;
          background: var(--accent); opacity: 0.12;
          border: 1px solid var(--accent); border-radius: 2px;
          pointer-events: none; transition: top .1s;
        }

        #preview { flex: 1; border: none; background: var(--bg2); }

        /* Status bar */
        .status-bar {
          display: flex; align-items: center; justify-content: space-between;
          padding: 1px 10px; background: var(--accent); color: white;
          font-size: 10px; min-height: 20px;
        }
        .status-right { display: flex; gap: 10px; }
        .shortcut-hint { opacity: .6; }
        #status-git { margin-left: 10px; opacity: .85; }
        #status-pos { opacity: .85; }

        /* Scrollbar */
        ::-webkit-scrollbar { width: 6px; height: 6px; }
        ::-webkit-scrollbar-track { background: transparent; }
        ::-webkit-scrollbar-thumb { background: rgba(128,128,128,.25); border-radius: 3px; }
        ::-webkit-scrollbar-thumb:hover { background: rgba(128,128,128,.4); }
        CSS
      end
    end
  end
end
