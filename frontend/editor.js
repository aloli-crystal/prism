import { EditorView, basicSetup } from "codemirror"
import { EditorState } from "@codemirror/state"
import { StreamLanguage } from "@codemirror/language"
import { asciidoc } from "codemirror-asciidoc"
import { css } from "@codemirror/lang-css"

// Theme clair style macOS
const macosLightTheme = EditorView.theme({
  "&": {
    fontSize: "13px",
    fontFamily: '"SF Mono", "Fira Code", Menlo, monospace',
    height: "100%",
    backgroundColor: "#ffffff",
  },
  ".cm-content": {
    padding: "12px 0",
    caretColor: "#0071e3",
  },
  ".cm-cursor": {
    borderLeftColor: "#0071e3",
  },
  ".cm-activeLine": {
    backgroundColor: "#f0f4ff",
  },
  ".cm-gutters": {
    backgroundColor: "#fafafa",
    color: "#c7c7cc",
    border: "none",
    borderRight: "1px solid #e5e5e7",
  },
  ".cm-activeLineGutter": {
    backgroundColor: "#f0f4ff",
    color: "#86868b",
  },
  ".cm-selectionBackground": {
    backgroundColor: "#b4d8fd !important",
  },
  "&.cm-focused .cm-selectionBackground": {
    backgroundColor: "#b4d8fd !important",
  },
  ".cm-matchingBracket": {
    backgroundColor: "#e0f0ff",
    outline: "1px solid #90cdf4",
  },
})

const defaultAsciidoc = `= Mon document
:author: Philippe
:toc:

== Introduction

Ceci est un *prototype* de l'éditeur _Prism_.

Un éditeur AsciiDoc en pur Crystal avec prévisualisation live.

== Fonctionnalités prévues

* Édition AsciiDoc avec coloration syntaxique
* Prévisualisation live du rendu
* Export HTML, PDF et EPUB
* Éditeur de feuille de style personnalisable

== Exemple de code

Un bloc de code :

 puts "Hello from Prism!"

== Conclusion

Ce prototype utilise https://github.com/naqvis/webview[webview] pour l'interface native et les shards https://github.com/aloli-crystal[aloli-crystal] pour le pipeline AsciiDoc.
`

const defaultCss = `/* Personnalisez le rendu ici */

body {
  font-family: -apple-system, BlinkMacSystemFont, Georgia, serif;
  line-height: 1.7;
  color: #1d1d1f;
  max-width: 42em;
  margin: 0 auto;
  padding: 1.5em;
}

h1 {
  color: #1d1d1f;
  font-size: 1.8em;
  border-bottom: 2px solid #0071e3;
  padding-bottom: 0.3em;
  margin-bottom: 0.6em;
}

h2 {
  color: #2d3748;
  font-size: 1.3em;
  margin-top: 1.5em;
  margin-bottom: 0.5em;
}

strong {
  color: #c0392b;
}

em {
  color: #6e6e73;
}

a {
  color: #0071e3;
  text-decoration: none;
}

a:hover {
  text-decoration: underline;
}

ul {
  padding-left: 1.5em;
}

li {
  margin-bottom: 0.3em;
}

code, pre {
  font-family: "SF Mono", "Fira Code", Menlo, monospace;
  font-size: 0.9em;
  background: #f5f5f7;
  border-radius: 4px;
}

code {
  padding: 0.15em 0.4em;
}

pre {
  padding: 1em;
  overflow-x: auto;
  border: 1px solid #e5e5e7;
}
`

let asciidocEditor, styleEditor
let debounceTimer

function createAsciidocEditor(parent) {
  asciidocEditor = new EditorView({
    state: EditorState.create({
      doc: defaultAsciidoc,
      extensions: [
        basicSetup,
        StreamLanguage.define(asciidoc),
        macosLightTheme,
        EditorView.updateListener.of((update) => {
          if (update.docChanged) {
            schedulePreview()
          }
        }),
      ],
    }),
    parent,
  })
}

function createStyleEditor(parent) {
  styleEditor = new EditorView({
    state: EditorState.create({
      doc: defaultCss,
      extensions: [
        basicSetup,
        css(),
        macosLightTheme,
        EditorView.updateListener.of((update) => {
          if (update.docChanged) {
            schedulePreview()
          }
        }),
      ],
    }),
    parent,
  })
}

function schedulePreview() {
  clearTimeout(debounceTimer)
  debounceTimer = setTimeout(updatePreview, 300)
}

async function updatePreview() {
  const content = asciidocEditor.state.doc.toString()
  const style = styleEditor.state.doc.toString()
  const html = await window.convertAsciidoc(content)
  const preview = document.getElementById("preview")
  const doc = preview.contentDocument
  doc.open()
  doc.write(
    "<html><head><style>" + style + "</style></head><body>" + html + "</body></html>"
  )
  doc.close()
}

// Initialisation au chargement
window.addEventListener("DOMContentLoaded", () => {
  createAsciidocEditor(document.getElementById("editor-asciidoc"))
  createStyleEditor(document.getElementById("editor-style"))

  // Onglets
  document.querySelectorAll(".tab").forEach((tab) => {
    tab.addEventListener("click", () => {
      document.querySelectorAll(".tab").forEach((t) => t.classList.remove("active"))
      tab.classList.add("active")
      const target = tab.dataset.tab
      document.getElementById("editor-asciidoc").classList.toggle("hidden", target !== "asciidoc")
      document.getElementById("editor-style").classList.toggle("hidden", target !== "style")
      // Refresh l'editeur visible pour eviter les glitchs
      if (target === "asciidoc") asciidocEditor.requestMeasure()
      else styleEditor.requestMeasure()
    })
  })

  // Export buttons
  document.getElementById("btn-export-pdf").addEventListener("click", async () => {
    const result = await window.exportPdf(asciidocEditor.state.doc.toString(), styleEditor.state.doc.toString())
    alert(result)
  })

  document.getElementById("btn-export-epub").addEventListener("click", async () => {
    const result = await window.exportEpub(asciidocEditor.state.doc.toString(), styleEditor.state.doc.toString())
    alert(result)
  })

  // Premier rendu
  updatePreview()
})

// Expose pour usage depuis Crystal
window.prism = { updatePreview }
