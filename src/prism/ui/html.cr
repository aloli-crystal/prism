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
          <div class="menubar" id="menubar">
            <div class="menu-item">
              <span class="menu-label">
                <svg viewBox="0 0 24 24" width="12" height="12" style="vertical-align:-1px">
                  <polygon points="8,4 12,2 16,4 18,10 16,18 12,20 8,18 6,10" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linejoin="round" opacity="0.6"/>
                </svg>
                Prism
              </span>
              <div class="menu-dropdown">
                <div class="menu-entry" onclick="window.prism.about()">À propos de Prism</div>
                <div class="menu-divider"></div>
                <div class="menu-entry" id="btn-dark-mode">Thème clair/sombre<span class="menu-shortcut">⌘D</span></div>
                <div class="menu-entry" id="btn-zen">Mode zen<span class="menu-shortcut">⌘↵</span></div>
              </div>
            </div>
            <div class="menu-item">
              <span class="menu-label">Fichier</span>
              <div class="menu-dropdown">
                <div class="menu-entry" id="btn-new">Nouveau<span class="menu-shortcut">⌘N</span></div>
                <div class="menu-entry" id="btn-open">Ouvrir…<span class="menu-shortcut">⌘O</span></div>
                <div class="menu-entry" onclick="window.prism.openRecent()">Ouvrir récent…</div>
                <div class="menu-divider"></div>
                <div class="menu-entry" id="btn-save">Enregistrer<span class="menu-shortcut">⌘S</span></div>
                <div class="menu-entry" onclick="window.prism.saveAs()">Enregistrer sous…<span class="menu-shortcut">⇧⌘S</span></div>
              </div>
            </div>
            <div class="menu-item">
              <span class="menu-label">Édition</span>
              <div class="menu-dropdown">
                <div class="menu-entry" onclick="document.execCommand('undo')">Annuler<span class="menu-shortcut">⌘Z</span></div>
                <div class="menu-entry" onclick="document.execCommand('redo')">Rétablir<span class="menu-shortcut">⇧⌘Z</span></div>
                <div class="menu-divider"></div>
                <div class="menu-entry" onclick="document.execCommand('cut')">Couper<span class="menu-shortcut">⌘X</span></div>
                <div class="menu-entry" onclick="document.execCommand('copy')">Copier<span class="menu-shortcut">⌘C</span></div>
                <div class="menu-entry" onclick="document.execCommand('paste')">Coller<span class="menu-shortcut">⌘V</span></div>
                <div class="menu-divider"></div>
                <div class="menu-entry" onclick="window.prism.find()">Rechercher…<span class="menu-shortcut">⌘F</span></div>
              </div>
            </div>
            <div class="menu-item">
              <span class="menu-label">Insertion</span>
              <div class="menu-dropdown">
                <div class="menu-entry" data-format="bold">Gras<span class="menu-shortcut">⇧⌘B</span></div>
                <div class="menu-entry" data-format="italic">Italique<span class="menu-shortcut">⌘I</span></div>
                <div class="menu-entry" data-format="mono">Monospace</div>
                <div class="menu-divider"></div>
                <div class="menu-entry" data-format="h1">Titre 1</div>
                <div class="menu-entry" data-format="h2">Titre 2</div>
                <div class="menu-entry" data-format="h3">Titre 3</div>
                <div class="menu-divider"></div>
                <div class="menu-entry" data-format="ul">Liste à puces</div>
                <div class="menu-entry" data-format="ol">Liste numérotée</div>
                <div class="menu-entry" data-format="link">Lien</div>
                <div class="menu-entry" data-format="image">Image</div>
                <div class="menu-entry" data-format="code">Bloc de code</div>
                <div class="menu-entry" data-format="quote">Citation</div>
                <div class="menu-entry" data-format="table">Tableau</div>
                <div class="menu-entry" data-format="admonition">Note / Admonition</div>
              </div>
            </div>
            <div class="menu-item">
              <span class="menu-label">Affichage</span>
              <div class="menu-dropdown">
                <div class="menu-entry" id="btn-toggle-sidebar">Sidebar<span class="menu-shortcut">⌘B</span></div>
                <div class="menu-entry" id="btn-toggle-preview">Prévisualisation<span class="menu-shortcut">⌘P</span></div>
                <div class="menu-entry" id="btn-minimap">Minimap<span class="menu-shortcut">⌘M</span></div>
              </div>
            </div>
            <div class="menu-item">
              <span class="menu-label">Export</span>
              <div class="menu-dropdown">
                <div class="menu-entry" id="btn-export-html">HTML<span class="menu-shortcut">⌘E</span></div>
                <div class="menu-entry" id="btn-export-pdf">PDF</div>
                <div class="menu-entry" id="btn-export-epub">EPUB</div>
                <div class="menu-divider"></div>
                <div class="menu-entry" id="btn-export-all">Tout exporter<span class="menu-shortcut">⇧⌘E</span></div>
              </div>
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
        body.zen .menubar, body.zen .status-bar, body.zen .sidebar,
        body.zen .preview-panel, body.zen #divider, body.zen .panel-header,
        body.zen .format-bar, body.zen #breadcrumb, body.zen .minimap { display: none !important; }

        /* Menu bar (macOS style) */
        .menubar {
          display: flex; align-items: stretch;
          background: var(--toolbar-bg);
          border-bottom: 1px solid var(--border2);
          font-size: 13px; min-height: 28px;
          -webkit-app-region: drag;
          padding-left: 78px; /* espace pour les feux tricolores macOS */
        }
        .menu-item {
          position: relative;
          -webkit-app-region: no-drag;
        }
        .menu-label {
          display: flex; align-items: center; gap: 4px;
          padding: 4px 10px; cursor: default; color: var(--text);
          font-size: 13px; font-weight: 500; user-select: none;
          border-radius: 4px; margin: 2px 1px;
        }
        .menu-label:hover { background: var(--accent); color: white; }
        .menu-dropdown {
          display: none; position: absolute; top: 100%; left: 0;
          background: var(--bg2); border: 1px solid var(--border2);
          border-radius: 6px; min-width: 220px;
          box-shadow: 0 8px 30px rgba(0,0,0,0.15);
          padding: 4px 0; z-index: 1000;
        }
        .menu-item:hover .menu-dropdown,
        .menu-item.open .menu-dropdown { display: block; }
        .menu-entry {
          padding: 4px 14px; cursor: default; font-size: 13px;
          display: flex; justify-content: space-between; align-items: center;
          color: var(--text); border-radius: 4px; margin: 0 4px;
        }
        .menu-entry:hover { background: var(--accent); color: white; }
        .menu-shortcut { font-size: 12px; color: var(--text2); margin-left: 20px; }
        .menu-entry:hover .menu-shortcut { color: rgba(255,255,255,0.7); }
        .menu-divider { height: 1px; background: var(--border); margin: 4px 8px; }

        /* Toolbar sep (used in format bar) */
        .toolbar-sep { width: 1px; height: 14px; background: var(--border2); margin: 0 3px; }

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
        .editor-container { flex: 1; overflow: hidden; position: relative; }

        /* Visual (WYSIWYG) editor */
        .visual-editor {
          height: 100%; overflow-y: auto; padding: 1.5em;
          font-family: -apple-system, BlinkMacSystemFont, Georgia, serif;
          font-size: 14px; line-height: 1.7; color: var(--text);
          background: var(--bg2); outline: none;
          max-width: 52em; margin: 0 auto;
        }
        .visual-editor:focus { outline: none; }
        .visual-editor h1 { font-size: 1.8em; border-bottom: 2px solid var(--accent); padding-bottom: .3em; margin-bottom: .6em; }
        .visual-editor h2 { font-size: 1.3em; margin-top: 1.5em; margin-bottom: .5em; color: var(--text); }
        .visual-editor h3 { font-size: 1.1em; margin-top: 1.2em; margin-bottom: .4em; }
        .visual-editor ul, .visual-editor ol { padding-left: 1.5em; }
        .visual-editor li { margin-bottom: .3em; }
        .visual-editor a { color: var(--accent); }
        .visual-editor code { background: var(--bg3); padding: .15em .4em; border-radius: 3px; font-size: .9em; }
        .visual-editor pre { background: var(--bg3); padding: 1em; border-radius: 6px; overflow-x: auto; border: 1px solid var(--border); }
        .visual-editor blockquote { border-left: 3px solid var(--accent); padding-left: 1em; color: var(--text2); margin: 1em 0; }
        .visual-editor table { border-collapse: collapse; width: 100%; margin: 1em 0; }
        .visual-editor th, .visual-editor td { border: 1px solid var(--border); padding: .5em .8em; }
        .visual-editor th { background: var(--bg3); font-weight: 600; }
        .visual-editor img { max-width: 100%; }
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
