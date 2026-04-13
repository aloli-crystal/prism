import { EditorView, basicSetup } from "codemirror"
import { EditorState } from "@codemirror/state"
import { StreamLanguage } from "@codemirror/language"
import { asciidoc } from "codemirror-asciidoc"
import { css } from "@codemirror/lang-css"
import { html } from "@codemirror/lang-html"

// --- Theme ---
const macosTheme = (dark) =>
  EditorView.theme(
    {
      "&": {
        fontSize: "13px",
        fontFamily: '"SF Mono", "Fira Code", Menlo, monospace',
        height: "100%",
        backgroundColor: dark ? "#1e1e1e" : "#ffffff",
        color: dark ? "#d4d4d4" : "#1d1d1f",
      },
      ".cm-content": { padding: "12px 0", caretColor: "#0071e3" },
      ".cm-cursor": { borderLeftColor: "#0071e3" },
      ".cm-activeLine": { backgroundColor: dark ? "#2a2a2a" : "#f0f4ff" },
      ".cm-gutters": {
        backgroundColor: dark ? "#1e1e1e" : "#fafafa",
        color: dark ? "#555" : "#c7c7cc",
        border: "none",
        borderRight: dark ? "1px solid #333" : "1px solid #e5e5e7",
      },
      ".cm-activeLineGutter": {
        backgroundColor: dark ? "#2a2a2a" : "#f0f4ff",
        color: dark ? "#888" : "#86868b",
      },
      ".cm-selectionBackground": {
        backgroundColor: dark ? "#264f78 !important" : "#b4d8fd !important",
      },
      "&.cm-focused .cm-selectionBackground": {
        backgroundColor: dark ? "#264f78 !important" : "#b4d8fd !important",
      },
    },
    { dark }
  )

// --- Default content ---
const defaultAsciidoc = `= Mon document
:author: Philippe
:toc:

== Introduction

Bienvenue dans *Prism*, l'éditeur AsciiDoc en Crystal.

== Fonctionnalités

* Coloration syntaxique AsciiDoc
* Prévisualisation live
* Export HTML, PDF et EPUB
* Éditeur de style CSS
* Intégration Git
`

const defaultCss = `body {
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
h2 { color: #2d3748; font-size: 1.3em; margin-top: 1.5em; margin-bottom: 0.5em; }
strong { color: #c0392b; }
em { color: #6e6e73; }
a { color: #0071e3; text-decoration: none; }
a:hover { text-decoration: underline; }
ul { padding-left: 1.5em; }
li { margin-bottom: 0.3em; }
code, pre {
  font-family: "SF Mono", Menlo, monospace;
  font-size: 0.9em;
  background: #f5f5f7;
  border-radius: 4px;
}
code { padding: 0.15em 0.4em; }
pre { padding: 1em; overflow-x: auto; border: 1px solid #e5e5e7; }
`

// --- State ---
let asciidocEditor, htmlEditor, styleEditor
let debounceTimer
let currentFilePath = ""
let isModified = false
let previewVisible = true
let sidebarVisible = false
let darkMode = false
let zenMode = false
let lastHtml = ""

// --- Editor creation ---
function createEditor(parent, lang, doc, onChange) {
  return new EditorView({
    state: EditorState.create({
      doc,
      extensions: [
        basicSetup,
        lang,
        macosTheme(darkMode),
        EditorView.updateListener.of((update) => {
          if (update.docChanged && onChange) onChange()
        }),
      ],
    }),
    parent,
  })
}

function replaceEditorContent(editor, text) {
  editor.dispatch({ changes: { from: 0, to: editor.state.doc.length, insert: text } })
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
  lastHtml = result

  // Sync HTML editor
  const htmlTab = document.querySelector('[data-tab="html"]')
  if (htmlTab && !htmlTab.classList.contains("editing")) {
    replaceEditorContent(htmlEditor, result)
  }

  renderPreview(result, style)
  markModified()
}

function renderPreview(h, style) {
  const preview = document.getElementById("preview")
  if (!preview) return
  const doc = preview.contentDocument
  const scrollTop = doc?.documentElement?.scrollTop || 0
  doc.open()
  doc.write(`<html><head><style>${style}</style></head><body>${h}</body></html>`)
  doc.close()
  // Restaurer la position de scroll
  doc.documentElement.scrollTop = scrollTop
}

function markModified() {
  if (!isModified) {
    isModified = true
    updateStatusBar()
  }
}

function updateStatusBar() {
  const el = document.getElementById("status-file")
  if (!el) return
  const name = currentFilePath ? currentFilePath.split("/").pop() : "Sans titre"
  el.textContent = name + (isModified ? " •" : "")
}

// --- Toggle panels ---
function togglePreview() {
  previewVisible = !previewVisible
  document.getElementById("divider").style.display = previewVisible ? "" : "none"
  document.querySelector(".preview-panel").style.display = previewVisible ? "" : "none"
  document.getElementById("btn-toggle-preview").textContent = previewVisible ? "⊟" : "⊞"
  if (previewVisible) updatePreview()
  savePref()
}

function toggleSidebar() {
  sidebarVisible = !sidebarVisible
  document.querySelector(".sidebar").classList.toggle("hidden", !sidebarVisible)
  savePref()
  if (sidebarVisible) loadSidebar()
}

function toggleDarkMode() {
  darkMode = !darkMode
  document.body.classList.toggle("dark", darkMode)
  // Recréer les éditeurs avec le bon thème
  recreateEditors()
  savePref()
}

function toggleZenMode() {
  zenMode = !zenMode
  document.body.classList.toggle("zen", zenMode)
}

function recreateEditors() {
  const adocContent = asciidocEditor.state.doc.toString()
  const htmlContent = htmlEditor.state.doc.toString()
  const cssContent = styleEditor.state.doc.toString()

  asciidocEditor.destroy()
  htmlEditor.destroy()
  styleEditor.destroy()

  asciidocEditor = createEditor(
    document.getElementById("editor-asciidoc"),
    StreamLanguage.define(asciidoc), adocContent, schedulePreview
  )
  htmlEditor = createEditor(
    document.getElementById("editor-html"),
    html(), htmlContent, null
  )
  styleEditor = createEditor(
    document.getElementById("editor-style"),
    css(), cssContent, schedulePreview
  )
}

// --- Sidebar (Git + Recent files) ---
async function loadSidebar() {
  const sidebar = document.querySelector(".sidebar-content")
  if (!sidebar) return

  let html = ""

  // Recent files
  try {
    const recent = JSON.parse(await window.getRecentFiles(""))
    if (recent.length > 0) {
      html += `<div class="sidebar-section"><div class="sidebar-title">Fichiers récents</div>`
      for (const f of recent) {
        const name = f.split("/").pop()
        html += `<div class="sidebar-item" data-path="${f}" onclick="window.prism.openPath('${f}')">${name}</div>`
      }
      html += `</div>`
    }
  } catch (e) {}

  // Git
  try {
    const info = JSON.parse(await window.getGitInfo(""))
    if (info.branch) {
      html += `<div class="sidebar-section"><div class="sidebar-title">Git — ${info.branch}</div>`
      if (!info.clean) {
        html += `<div class="sidebar-hint">${info.modified} modifié(s), ${info.untracked} non suivi(s)</div>`
      } else {
        html += `<div class="sidebar-hint">Aucune modification</div>`
      }

      // Fichiers .adoc du dépôt
      const files = JSON.parse(await window.getGitFileTree(""))
      for (const f of files) {
        html += `<div class="sidebar-item" onclick="window.prism.openPath('${f.path}')">${f.name}</div>`
      }
      html += `</div>`
    }
  } catch (e) {}

  if (!html) html = `<div class="sidebar-hint">Ouvrez un fichier pour voir le dépôt Git</div>`
  sidebar.innerHTML = html
}

// --- File operations ---
async function doOpen() {
  const result = await window.openFile("")
  if (!result) return
  handleOpenResult(result)
}

async function doOpenPath(path) {
  const result = await window.openFilePath(path)
  if (!result) return
  handleOpenResult(result)
}

function handleOpenResult(result) {
  const data = JSON.parse(result)
  if (data.error) { alert("Erreur : " + data.error); return }
  if (data.content === undefined) return

  currentFilePath = data.path || ""
  isModified = false
  replaceEditorContent(asciidocEditor, data.content)
  if (data.css) replaceEditorContent(styleEditor, data.css)

  updateStatusBar()
  updateGitStatus()
  updatePreview()
  if (sidebarVisible) loadSidebar()
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
  updateGitStatus()
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
  if (isModified && !confirm("Fichier modifié. Continuer sans sauvegarder ?")) return
  await window.newFile("")
  currentFilePath = ""
  isModified = false
  replaceEditorContent(asciidocEditor, defaultAsciidoc)
  replaceEditorContent(styleEditor, defaultCss)
  updateStatusBar()
  updatePreview()
}

// --- Git status ---
async function updateGitStatus() {
  const el = document.getElementById("status-git")
  if (!el) return
  try {
    const info = JSON.parse(await window.getGitInfo(""))
    if (info.branch) {
      el.textContent = `⎇ ${info.branch}` + (info.clean ? "" : ` (+${info.modified})`)
      el.style.display = ""
    } else {
      el.style.display = "none"
    }
  } catch (e) {
    el.style.display = "none"
  }
}

// --- Exports ---
async function doExport(fn, label) {
  const content = asciidocEditor.state.doc.toString()
  const style = styleEditor.state.doc.toString()
  const result = await fn(content, style)
  if (!result) return
  const data = JSON.parse(result)
  if (data.error) { alert("Erreur " + label + " : " + data.error); return }
  if (data.success) alert(label + " exporté : " + (data.path || data.results?.join("\n")))
}

// --- Preferences ---
function savePref() {
  window.savePreferences(JSON.stringify({
    dark_mode: darkMode,
    preview_visible: previewVisible,
    sidebar_visible: sidebarVisible,
  }))
}

// --- Scroll sync ---
function setupScrollSync() {
  const editorDom = asciidocEditor.dom
  editorDom.addEventListener("scroll", () => {
    const preview = document.getElementById("preview")
    if (!preview || !previewVisible) return
    const editorScrollable = editorDom.querySelector(".cm-scroller")
    if (!editorScrollable) return
    const pct = editorScrollable.scrollTop / (editorScrollable.scrollHeight - editorScrollable.clientHeight || 1)
    const previewDoc = preview.contentDocument?.documentElement
    if (previewDoc) {
      previewDoc.scrollTop = pct * (previewDoc.scrollHeight - previewDoc.clientHeight)
    }
  })
}

// --- Keyboard shortcuts ---
function setupShortcuts() {
  document.addEventListener("keydown", (e) => {
    const mod = e.metaKey || e.ctrlKey

    if (mod && e.key === "s" && !e.shiftKey) { e.preventDefault(); doSave() }
    else if (mod && e.key === "s" && e.shiftKey) { e.preventDefault(); doSaveAs() }
    else if (mod && e.key === "o") { e.preventDefault(); doOpen() }
    else if (mod && e.key === "n") { e.preventDefault(); doNew() }
    else if (mod && e.key === "p" && !e.shiftKey) { e.preventDefault(); togglePreview() }
    else if (mod && e.key === "b") { e.preventDefault(); toggleSidebar() }
    else if (mod && e.key === "e" && !e.shiftKey) { e.preventDefault(); doExport(window.exportHtml, "HTML") }
    else if (mod && e.shiftKey && e.key === "e") { e.preventDefault(); doExport(window.exportAll, "Tous les formats") }
    else if (mod && e.key === "d") { e.preventDefault(); toggleDarkMode() }
    else if (e.key === "Escape" && zenMode) { toggleZenMode() }
    else if (mod && e.key === "Enter") { e.preventDefault(); toggleZenMode() }
  })
}

// --- Divider ---
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
    const sidebarW = sidebarVisible ? document.querySelector(".sidebar").offsetWidth : 0
    const pct = ((e.clientX - rect.left - sidebarW) / (rect.width - sidebarW)) * 100
    const clamped = Math.max(20, Math.min(80, pct))
    editorPanel.style.flex = "none"
    editorPanel.style.width = clamped + "%"
  })
  document.addEventListener("mouseup", () => {
    if (dragging) { dragging = false; document.body.style.cursor = ""; document.body.style.userSelect = "" }
  })
}

// --- Init ---
window.addEventListener("DOMContentLoaded", async () => {
  // Load preferences
  try {
    const prefs = JSON.parse(await window.getPreferences(""))
    darkMode = prefs.dark_mode || false
    previewVisible = prefs.preview_visible !== false
    sidebarVisible = prefs.sidebar_visible || false
    if (darkMode) document.body.classList.add("dark")
  } catch (e) {}

  // Create editors
  asciidocEditor = createEditor(
    document.getElementById("editor-asciidoc"),
    StreamLanguage.define(asciidoc), defaultAsciidoc, schedulePreview
  )
  htmlEditor = createEditor(
    document.getElementById("editor-html"),
    html(), "", null
  )
  styleEditor = createEditor(
    document.getElementById("editor-style"),
    css(), defaultCss, schedulePreview
  )

  // Tabs
  document.querySelectorAll(".tab[data-group]").forEach((tab) => {
    tab.addEventListener("click", () => {
      const group = tab.dataset.group
      document.querySelectorAll(`.tab[data-group="${group}"]`).forEach((t) => t.classList.remove("active"))
      tab.classList.add("active")
      const target = tab.dataset.tab
      if (group === "editor") {
        document.getElementById("editor-asciidoc").classList.toggle("hidden", target !== "asciidoc")
        document.getElementById("editor-html").classList.toggle("hidden", target !== "html")
        document.getElementById("editor-style").classList.toggle("hidden", target !== "style")
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
  document.getElementById("btn-export-all").addEventListener("click", () => doExport(window.exportAll, "Tous"))
  document.getElementById("btn-toggle-preview").addEventListener("click", togglePreview)
  document.getElementById("btn-toggle-sidebar").addEventListener("click", toggleSidebar)
  document.getElementById("btn-dark-mode").addEventListener("click", toggleDarkMode)
  document.getElementById("btn-zen").addEventListener("click", toggleZenMode)

  // Apply initial state
  if (!previewVisible) togglePreview()
  if (sidebarVisible) {
    document.querySelector(".sidebar").classList.remove("hidden")
    loadSidebar()
  }

  setupDivider()
  setupShortcuts()
  updateStatusBar()
  updatePreview()

  // Scroll sync after first render
  setTimeout(setupScrollSync, 500)
})

// Expose
window.prism = { updatePreview, togglePreview, toggleSidebar, openPath: doOpenPath }
