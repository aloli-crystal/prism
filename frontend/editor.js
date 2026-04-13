import { EditorView, basicSetup } from "codemirror"
import { EditorState } from "@codemirror/state"
import { StreamLanguage } from "@codemirror/language"
import { asciidoc } from "codemirror-asciidoc"
import { css } from "@codemirror/lang-css"
import { html } from "@codemirror/lang-html"
import { keymap } from "@codemirror/view"

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

== Fonctionnalités

* Édition AsciiDoc avec coloration syntaxique
* Prévisualisation live du rendu
* Export HTML, PDF et EPUB
* Éditeur de feuille de style personnalisable
* Édition HTML bidirectionnelle

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

strong { color: #c0392b; }
em { color: #6e6e73; }

a { color: #0071e3; text-decoration: none; }
a:hover { text-decoration: underline; }

ul { padding-left: 1.5em; }
li { margin-bottom: 0.3em; }

code, pre {
  font-family: "SF Mono", "Fira Code", Menlo, monospace;
  font-size: 0.9em;
  background: #f5f5f7;
  border-radius: 4px;
}

code { padding: 0.15em 0.4em; }

pre {
  padding: 1em;
  overflow-x: auto;
  border: 1px solid #e5e5e7;
}
`

// --- State ---
let asciidocEditor, htmlEditor, styleEditor
let debounceTimer
let currentFilePath = ""
let isModified = false
let previewVisible = true
let lastHtmlFromAsciidoc = ""

// --- Editor creation ---

function createEditor(parent, lang, doc, onChange) {
  const extensions = [
    basicSetup,
    lang,
    macosLightTheme,
    EditorView.updateListener.of((update) => {
      if (update.docChanged && onChange) onChange()
    }),
  ]
  return new EditorView({
    state: EditorState.create({ doc, extensions }),
    parent,
  })
}

// --- Preview ---

function schedulePreview() {
  clearTimeout(debounceTimer)
  debounceTimer = setTimeout(updatePreview, 300)
}

async function updatePreview() {
  const content = asciidocEditor.state.doc.toString()
  const style = styleEditor.state.doc.toString()
  const result = await window.convertAsciidoc(content)
  lastHtmlFromAsciidoc = result

  // Update HTML editor if it's not the source of the change
  if (document.querySelector('[data-tab="html"]') &&
      !document.querySelector('[data-tab="html"]').classList.contains("editing")) {
    htmlEditor.dispatch({
      changes: { from: 0, to: htmlEditor.state.doc.length, insert: result }
    })
  }

  renderPreview(result, style)
  markModified()
}

function renderPreview(htmlContent, style) {
  const preview = document.getElementById("preview")
  if (!preview) return
  const doc = preview.contentDocument
  doc.open()
  doc.write(
    "<html><head><style>" + style + "</style></head><body>" + htmlContent + "</body></html>"
  )
  doc.close()
}

function markModified() {
  if (!isModified) {
    isModified = true
    updateStatusBar()
  }
}

function updateStatusBar() {
  const status = document.getElementById("status-file")
  if (!status) return
  const name = currentFilePath ? currentFilePath.split("/").pop() : "Sans titre"
  status.textContent = name + (isModified ? " (modifié)" : "")
}

// --- Preview toggle ---

function togglePreview() {
  previewVisible = !previewVisible
  const divider = document.getElementById("divider")
  const previewPanel = document.querySelector(".preview-panel")
  const toggleBtn = document.getElementById("btn-toggle-preview")

  if (previewVisible) {
    divider.style.display = ""
    previewPanel.style.display = ""
    toggleBtn.textContent = "Masquer aperçu"
    updatePreview()
  } else {
    divider.style.display = "none"
    previewPanel.style.display = "none"
    toggleBtn.textContent = "Afficher aperçu"
  }
}

// --- Divider drag ---

function setupDivider() {
  const divider = document.getElementById("divider")
  const panels = document.querySelector(".panels")
  const editorPanel = document.querySelector(".editor-panel")
  let dragging = false

  divider.addEventListener("mousedown", (e) => {
    dragging = true
    document.body.style.cursor = "col-resize"
    document.body.style.userSelect = "none"
    e.preventDefault()
  })

  document.addEventListener("mousemove", (e) => {
    if (!dragging) return
    const rect = panels.getBoundingClientRect()
    const pct = ((e.clientX - rect.left) / rect.width) * 100
    const clamped = Math.max(20, Math.min(80, pct))
    editorPanel.style.flex = "none"
    editorPanel.style.width = clamped + "%"
  })

  document.addEventListener("mouseup", () => {
    if (dragging) {
      dragging = false
      document.body.style.cursor = ""
      document.body.style.userSelect = ""
    }
  })
}

// --- File operations ---

async function doOpen() {
  const result = await window.openFile("")
  if (!result) return
  const data = JSON.parse(result)
  if (data.error) { alert("Erreur : " + data.error); return }
  if (!data.content && data.content !== "") return

  currentFilePath = data.path || ""
  isModified = false

  // Set AsciiDoc content
  asciidocEditor.dispatch({
    changes: { from: 0, to: asciidocEditor.state.doc.length, insert: data.content }
  })

  // Set CSS if present
  if (data.css) {
    styleEditor.dispatch({
      changes: { from: 0, to: styleEditor.state.doc.length, insert: data.css }
    })
  }

  updateStatusBar()
  updatePreview()
}

async function doSave() {
  const content = asciidocEditor.state.doc.toString()
  const style = styleEditor.state.doc.toString()
  const result = await window.saveFile(content, style, currentFilePath)
  if (!result) return
  const data = JSON.parse(result)
  if (data.error) { alert("Erreur : " + data.error); return }
  if (data.path) currentFilePath = data.path
  isModified = false
  updateStatusBar()
}

async function doSaveAs() {
  const content = asciidocEditor.state.doc.toString()
  const style = styleEditor.state.doc.toString()
  const result = await window.saveFileAs(content, style)
  if (!result) return
  const data = JSON.parse(result)
  if (data.error) { alert("Erreur : " + data.error); return }
  if (data.path) currentFilePath = data.path
  isModified = false
  updateStatusBar()
}

async function doNew() {
  if (isModified && !confirm("Le fichier a été modifié. Créer un nouveau fichier sans sauvegarder ?")) return
  await window.newFile("")
  currentFilePath = ""
  isModified = false
  asciidocEditor.dispatch({
    changes: { from: 0, to: asciidocEditor.state.doc.length, insert: defaultAsciidoc }
  })
  styleEditor.dispatch({
    changes: { from: 0, to: styleEditor.state.doc.length, insert: defaultCss }
  })
  updateStatusBar()
  updatePreview()
}

// --- Exports ---

async function doExport(fn, label) {
  const content = asciidocEditor.state.doc.toString()
  const style = styleEditor.state.doc.toString()
  const result = await fn(content, style)
  if (!result) return
  const data = JSON.parse(result)
  if (data.error) { alert("Erreur export " + label + " : " + data.error); return }
  if (data.success) alert(label + " exporté : " + data.path)
}

// --- Keyboard shortcuts ---

function setupShortcuts() {
  document.addEventListener("keydown", (e) => {
    const mod = e.metaKey || e.ctrlKey

    if (mod && e.key === "s" && !e.shiftKey) {
      e.preventDefault()
      doSave()
    } else if (mod && e.key === "s" && e.shiftKey) {
      e.preventDefault()
      doSaveAs()
    } else if (mod && e.key === "o") {
      e.preventDefault()
      doOpen()
    } else if (mod && e.key === "n") {
      e.preventDefault()
      doNew()
    } else if (mod && e.key === "p") {
      e.preventDefault()
      togglePreview()
    } else if (mod && e.key === "e") {
      e.preventDefault()
      doExport(window.exportHtml, "HTML")
    }
  })
}

// --- Initialization ---

window.addEventListener("DOMContentLoaded", () => {
  // Create editors
  asciidocEditor = createEditor(
    document.getElementById("editor-asciidoc"),
    StreamLanguage.define(asciidoc),
    defaultAsciidoc,
    () => { schedulePreview() }
  )

  htmlEditor = createEditor(
    document.getElementById("editor-html"),
    html(),
    "",
    null // HTML changes don't auto-update for now (V0.2: read-only-ish)
  )

  styleEditor = createEditor(
    document.getElementById("editor-style"),
    css(),
    defaultCss,
    () => { schedulePreview() }
  )

  // Tabs
  document.querySelectorAll(".tab").forEach((tab) => {
    tab.addEventListener("click", () => {
      const group = tab.dataset.group
      if (!group) return
      document.querySelectorAll(`.tab[data-group="${group}"]`).forEach((t) => t.classList.remove("active"))
      tab.classList.add("active")
      const target = tab.dataset.tab

      if (group === "editor") {
        document.getElementById("editor-asciidoc").classList.toggle("hidden", target !== "asciidoc")
        document.getElementById("editor-html").classList.toggle("hidden", target !== "html")
        document.getElementById("editor-style").classList.toggle("hidden", target !== "style")
        // Refresh visible editor
        if (target === "asciidoc") asciidocEditor.requestMeasure()
        else if (target === "html") htmlEditor.requestMeasure()
        else styleEditor.requestMeasure()
      }
    })
  })

  // Toolbar buttons
  document.getElementById("btn-new").addEventListener("click", doNew)
  document.getElementById("btn-open").addEventListener("click", doOpen)
  document.getElementById("btn-save").addEventListener("click", doSave)
  document.getElementById("btn-export-html").addEventListener("click", () => doExport(window.exportHtml, "HTML"))
  document.getElementById("btn-export-pdf").addEventListener("click", () => doExport(window.exportPdf, "PDF"))
  document.getElementById("btn-export-epub").addEventListener("click", () => doExport(window.exportEpub, "EPUB"))
  document.getElementById("btn-toggle-preview").addEventListener("click", togglePreview)

  // Divider
  setupDivider()

  // Shortcuts
  setupShortcuts()

  // Status bar
  updateStatusBar()

  // First render
  updatePreview()
})

// Expose
window.prism = { updatePreview, togglePreview }
