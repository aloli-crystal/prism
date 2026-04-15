module Prism
  module UI
    module Html
      EDITOR_JS = {{ read_file("assets/editor.bundle.js") }}

      def self.page : String
        <<-HTML
        <!DOCTYPE html>
        <html lang="fr">
        <head><meta charset="UTF-8"><style>#{css}</style></head>
        <body>
          <!-- Le menu est natif macOS via crystal-appkit -->

          <div id="breadcrumb"><span class="bc-item">Document</span></div>

          <div class="format-bar">
            <button data-format="bold" title="Gras ⇧⌘B"><b>G</b></button>
            <button data-format="italic" title="Italique ⌘I"><i>I</i></button>
            <button data-format="mono" title="Mono">M</button>
            <span class="sep"></span>
            <button data-format="h1">H1</button>
            <button data-format="h2">H2</button>
            <button data-format="h3">H3</button>
            <span class="sep"></span>
            <button data-format="ul">•</button>
            <button data-format="ol">1.</button>
            <button data-format="link">Lien</button>
            <button data-format="code">Code</button>
            <button data-format="quote">Citation</button>
            <button data-format="table">Tableau</button>
            <button data-format="admonition">Note</button>
          </div>

          <div class="main-area">
            <div class="sidebar hidden">
              <div class="sb-header">Explorateur</div>
              <div class="sidebar-content"></div>
            </div>

            <div class="panels">
              <div class="panel editor-panel">
                <div class="tabs">
                  <span class="tab active" data-tab="asciidoc" data-group="editor">Source</span>
                  <span class="tab" data-tab="visual" data-group="editor">Visuel</span>
                  <span class="tab" data-tab="style" data-group="editor">Style</span>
                </div>
                <div class="editor-with-minimap">
                  <div class="editor-area">
                    <div id="editor-asciidoc" class="editor-container"></div>
                    <div id="editor-visual" class="editor-container hidden">
                      <div id="visual-editor" class="visual-editor" contenteditable="true"></div>
                    </div>
                    <div id="editor-style" class="editor-container hidden"></div>
                  </div>
                  <div id="minimap" class="minimap hidden">
                    <div class="mm-lines"></div>
                    <div class="mm-viewport"></div>
                  </div>
                </div>
              </div>

              <div class="divider" id="divider"></div>

              <div class="panel preview-panel">
                <div class="tabs"><span>Aperçu</span></div>
                <iframe id="preview" sandbox="allow-same-origin"></iframe>
              </div>
            </div>
          </div>

          <div class="status-bar">
            <span id="status-file">Sans titre</span>
            <span id="status-git" style="display:none"></span>
            <span class="status-r"><span id="status-pos">1:1</span></span>
          </div>

          <script>#{EDITOR_JS}</script>
        </body>
        </html>
        HTML
      end

      private def self.css : String
        <<-CSS
        :root {
          --bg: #fafafa; --bg2: #ffffff; --bg3: #f5f5f5;
          --border: #ebebeb; --text: #2e2e2e; --text2: #999; --text3: #777;
          --accent: #528bff; --sidebar-bg: #f2f2f2;
        }
        body.dark {
          --bg: #1e1e1e; --bg2: #1e1e1e; --bg3: #252526;
          --border: #2d2d2d; --text: #c8c8c8; --text2: #555; --text3: #777;
          --accent: #528bff; --sidebar-bg: #1a1a1a;
        }
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
          font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
          background: var(--bg); color: var(--text);
          height: 100vh; display: flex; flex-direction: column; overflow: hidden;
          font-size: 13px;
        }

        /* Zen */
        body.zen .status-bar, body.zen .sidebar, body.zen .preview-panel,
        body.zen #divider, body.zen .tabs, body.zen .format-bar,
        body.zen #breadcrumb, body.zen .minimap { display: none !important; }

        /* Breadcrumb */
        #breadcrumb {
          display: flex; align-items: center; gap: 2px;
          padding: 3px 16px; font-size: 12px; color: var(--text2);
          min-height: 24px; overflow: hidden;
          border-bottom: 1px solid var(--border);
        }
        .bc-item { cursor: pointer; padding: 1px 4px; border-radius: 3px; }
        .bc-item:hover { background: var(--accent); color: white; }
        .bc-sep { color: var(--border); margin: 0 2px; font-size: 10px; }

        /* Format bar */
        .format-bar {
          display: flex; align-items: center; gap: 1px;
          padding: 3px 16px; border-bottom: 1px solid var(--border);
        }
        .format-bar button {
          padding: 2px 8px; border: none; border-radius: 4px;
          background: transparent; color: var(--text3); font-size: 12px;
          font-family: inherit; cursor: pointer; transition: all .1s;
        }
        .format-bar button:hover { background: var(--accent); color: white; }
        .sep { width: 1px; height: 12px; background: var(--border); margin: 0 6px; }

        /* Main */
        .main-area { display: flex; flex: 1; overflow: hidden; }

        /* Sidebar */
        .sidebar {
          width: 200px; background: var(--sidebar-bg);
          border-right: 1px solid var(--border);
          display: flex; flex-direction: column; flex-shrink: 0;
        }
        .sb-header { padding: 10px 14px; font-size: 11px; font-weight: 600; color: var(--text2); text-transform: uppercase; letter-spacing: .5px; }
        .sidebar-content { flex: 1; overflow-y: auto; }
        .sb-section { margin-bottom: 4px; }
        .sb-title { padding: 8px 14px 2px; font-size: 10px; font-weight: 600; color: var(--text2); text-transform: uppercase; }
        .sb-item {
          padding: 4px 14px 4px 20px; font-size: 12px; cursor: pointer; color: var(--text);
          white-space: nowrap; overflow: hidden; text-overflow: ellipsis;
        }
        .sb-item:hover { background: var(--accent); color: white; border-radius: 3px; margin: 0 4px; padding-left: 16px; }
        .sb-hint { padding: 8px 14px; font-size: 11px; color: var(--text2); }
        .hidden { display: none !important; }

        /* Panels */
        .panels { display: flex; flex: 1; overflow: hidden; }
        .panel { flex: 1; display: flex; flex-direction: column; min-width: 0; }
        .divider { width: 1px; cursor: col-resize; background: var(--border); flex-shrink: 0; }
        .divider:hover { background: var(--accent); width: 2px; }

        /* Tabs (Zed-style: minimal, no border) */
        .tabs {
          display: flex; padding: 0 12px;
          font-size: 12px; color: var(--text2);
          min-height: 28px; align-items: stretch;
          border-bottom: 1px solid var(--border);
        }
        .tab {
          padding: 0 12px; cursor: pointer;
          border-bottom: 2px solid transparent;
          display: flex; align-items: center;
          transition: color .1s; user-select: none;
        }
        .tab.active { color: var(--text); border-bottom-color: var(--accent); }
        .tab:hover:not(.active) { color: var(--text); }

        /* Editor */
        .editor-with-minimap { flex: 1; display: flex; overflow: hidden; }
        .editor-area { flex: 1; display: flex; flex-direction: column; overflow: hidden; }
        .editor-container { flex: 1; overflow: hidden; }
        .editor-container .cm-editor { height: 100%; }

        /* Visual editor */
        .visual-editor {
          height: 100%; overflow-y: auto; padding: 2em;
          font-family: -apple-system, BlinkMacSystemFont, Georgia, serif;
          font-size: 15px; line-height: 1.75; color: var(--text);
          background: var(--bg2); outline: none;
          max-width: 48em; margin: 0 auto;
        }
        .visual-editor:focus { outline: none; }
        .visual-editor h1 { font-size: 1.8em; font-weight: 600; margin-bottom: .6em; padding-bottom: .3em; border-bottom: 1px solid var(--border); }
        .visual-editor h2 { font-size: 1.3em; font-weight: 600; margin-top: 1.5em; margin-bottom: .4em; }
        .visual-editor h3 { font-size: 1.1em; font-weight: 600; margin-top: 1.2em; }
        .visual-editor ul, .visual-editor ol { padding-left: 1.5em; }
        .visual-editor a { color: var(--accent); }
        .visual-editor code { background: var(--bg3); padding: .1em .35em; border-radius: 3px; font-size: .9em; }
        .visual-editor pre { background: var(--bg3); padding: 1em; border-radius: 6px; }
        .visual-editor blockquote { border-left: 2px solid var(--border); padding-left: 1em; color: var(--text2); }
        .visual-editor table { border-collapse: collapse; width: 100%; }
        .visual-editor th, .visual-editor td { border: 1px solid var(--border); padding: .4em .7em; }
        .visual-editor th { background: var(--bg3); }

        /* Minimap */
        .minimap {
          width: 50px; background: var(--bg);
          position: relative; overflow: hidden; flex-shrink: 0; cursor: pointer;
          border-left: 1px solid var(--border);
        }
        .mm-lines { padding: 4px 2px; }
        .mm-line { height: 1.5px; margin-bottom: .5px; background: var(--text2); opacity: .15; border-radius: 1px; }
        .mm-h { opacity: .5; background: var(--accent); height: 2px; }
        .mm-l { opacity: .2; }
        .mm-e { opacity: 0; height: 1px; }
        .mm-viewport {
          position: absolute; left: 0; right: 0;
          background: var(--accent); opacity: .08;
          border: 1px solid var(--accent); border-radius: 2px;
          pointer-events: none;
        }

        #preview { flex: 1; border: none; background: var(--bg2); }

        /* Status bar (Zed-style: thin, subtle) */
        .status-bar {
          display: flex; align-items: center; justify-content: space-between;
          padding: 0 12px; background: var(--bg3);
          border-top: 1px solid var(--border);
          font-size: 11px; color: var(--text2); min-height: 22px;
        }
        .status-r { display: flex; gap: 12px; }
        #status-git { margin-left: 12px; }

        /* Scrollbar */
        ::-webkit-scrollbar { width: 6px; height: 6px; }
        ::-webkit-scrollbar-track { background: transparent; }
        ::-webkit-scrollbar-thumb { background: rgba(128,128,128,.2); border-radius: 3px; }
        ::-webkit-scrollbar-thumb:hover { background: rgba(128,128,128,.35); }
        CSS
      end
    end
  end
end
