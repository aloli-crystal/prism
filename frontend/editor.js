import { EditorView, basicSetup } from "codemirror"
import { EditorState, Compartment } from "@codemirror/state"
import { StreamLanguage } from "@codemirror/language"
import { asciidoc } from "codemirror-asciidoc"
import { css } from "@codemirror/lang-css"
import { search, openSearchPanel, closeSearchPanel } from "@codemirror/search"

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
      ".cm-content": { padding: "12px 0", caretColor: dark ? "#4fc1ff" : "#0071e3" },
      ".cm-cursor": { borderLeftColor: dark ? "#4fc1ff" : "#0071e3" },
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
      // Search panel style
      ".cm-panels": {
        backgroundColor: dark ? "#252526" : "#f5f5f7",
        borderBottom: dark ? "1px solid #333" : "1px solid #e5e5e7",
      },
      ".cm-searchMatch": {
        backgroundColor: dark ? "#515c6a" : "#ffeaa7",
        outline: dark ? "1px solid #6a7585" : "1px solid #fdcb6e",
      },
      ".cm-searchMatch-selected": {
        backgroundColor: dark ? "#264f78" : "#74b9ff",
      },
    },
    { dark }
  )

// --- Defaults ---
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
  line-height: 1.7; color: #1d1d1f;
  max-width: 42em; margin: 0 auto; padding: 1.5em;
}
h1 { color: #1d1d1f; font-size: 1.8em; border-bottom: 2px solid #0071e3; padding-bottom: .3em; margin-bottom: .6em; }
h2 { color: #2d3748; font-size: 1.3em; margin-top: 1.5em; margin-bottom: .5em; }
h3 { color: #4a5568; font-size: 1.1em; margin-top: 1.2em; margin-bottom: .4em; }
strong { color: #c0392b; }
em { color: #6e6e73; }
a { color: #0071e3; text-decoration: none; }
a:hover { text-decoration: underline; }
ul, ol { padding-left: 1.5em; }
li { margin-bottom: .3em; }
code, pre { font-family: "SF Mono", Menlo, monospace; font-size: .9em; background: #f5f5f7; border-radius: 4px; }
code { padding: .15em .4em; }
pre { padding: 1em; overflow-x: auto; border: 1px solid #e5e5e7; }
blockquote { border-left: 3px solid #0071e3; padding-left: 1em; color: #6e6e73; margin: 1em 0; }
table { border-collapse: collapse; width: 100%; margin: 1em 0; }
th, td { border: 1px solid #e5e5e7; padding: .5em .8em; text-align: left; }
th { background: #f5f5f7; font-weight: 600; }
`

// --- State ---
let asciidocEditor, styleEditor
let activeTab = "asciidoc"
let debounceTimer
let currentFilePath = ""
let isModified = false
let previewVisible = true
let sidebarVisible = false
let darkMode = false
let zenMode = false
let minimapVisible = true

// --- Editor ---
function createEditor(parent, lang, doc, onChange) {
  return new EditorView({
    state: EditorState.create({
      doc,
      extensions: [
        basicSetup,
        lang,
        macosTheme(darkMode),
        search({ top: true }),
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

// --- WYSIWYG formatting toolbar ---
function insertAround(editor, before, after) {
  const sel = editor.state.selection.main
  const selected = editor.state.sliceDoc(sel.from, sel.to)
  editor.dispatch({
    changes: { from: sel.from, to: sel.to, insert: before + selected + after },
    selection: { anchor: sel.from + before.length, head: sel.from + before.length + selected.length },
  })
  editor.focus()
}

function insertAtLineStart(editor, prefix) {
  const sel = editor.state.selection.main
  const line = editor.state.doc.lineAt(sel.from)
  editor.dispatch({
    changes: { from: line.from, to: line.from, insert: prefix },
  })
  editor.focus()
}

function applyFormat(format) {
  if (activeTab === "visual") {
    applyVisualFormat(format)
  } else {
    applyAsciidocFormat(format)
  }
  schedulePreview()
}

function applyAsciidocFormat(format) {
  const editor = asciidocEditor
  switch (format) {
    case "bold": insertAround(editor, "*", "*"); break
    case "italic": insertAround(editor, "_", "_"); break
    case "mono": insertAround(editor, "`", "`"); break
    case "h1": insertAtLineStart(editor, "= "); break
    case "h2": insertAtLineStart(editor, "== "); break
    case "h3": insertAtLineStart(editor, "=== "); break
    case "ul": insertAtLineStart(editor, "* "); break
    case "ol": insertAtLineStart(editor, ". "); break
    case "link": insertAround(editor, "https://", "[lien]"); break
    case "image": insertAround(editor, "image::", "[alt]"); break
    case "code": {
      const sel = editor.state.selection.main
      const text = editor.state.sliceDoc(sel.from, sel.to)
      if (text.includes("\n")) insertAround(editor, "[source]\n----\n", "\n----")
      else insertAround(editor, "`", "`")
      break
    }
    case "quote": insertAround(editor, "[quote]\n____\n", "\n____"); break
    case "table": {
      const tpl = `[cols="1,1", options="header"]\n|===\n| Col 1 | Col 2\n\n| A | B\n|===`
      insertAround(editor, tpl, "")
      break
    }
    case "admonition": insertAtLineStart(editor, "NOTE: "); break
  }
}

function applyVisualFormat(format) {
  // execCommand pour l'éditeur contenteditable
  const ve = document.getElementById("visual-editor")
  ve.focus()
  switch (format) {
    case "bold": document.execCommand("bold"); break
    case "italic": document.execCommand("italic"); break
    case "mono": document.execCommand("insertHTML", false, "<code>" + (window.getSelection().toString() || "code") + "</code>"); break
    case "h1": document.execCommand("formatBlock", false, "h1"); break
    case "h2": document.execCommand("formatBlock", false, "h2"); break
    case "h3": document.execCommand("formatBlock", false, "h3"); break
    case "ul": document.execCommand("insertUnorderedList"); break
    case "ol": document.execCommand("insertOrderedList"); break
    case "link": {
      const url = prompt("URL :")
      if (url) document.execCommand("createLink", false, url)
      break
    }
    case "quote": document.execCommand("formatBlock", false, "blockquote"); break
    case "admonition": document.execCommand("insertHTML", false, "<div class='admonition'><strong>NOTE:</strong> </div>"); break
  }
}

// --- Minimap ---
function updateMinimap() {
  const container = document.getElementById("minimap")
  if (!container || !minimapVisible) return

  const content = asciidocEditor.state.doc.toString()
  const lines = content.split("\n")
  const totalLines = lines.length
  const editorScroller = asciidocEditor.dom.querySelector(".cm-scroller")
  if (!editorScroller) return

  // Build minimap HTML
  let html = ""
  for (let i = 0; i < totalLines; i++) {
    const line = lines[i]
    let cls = "mm-line"
    if (/^={1,5}\s/.test(line)) cls += " mm-heading"
    else if (/^\*\s|^\.\s/.test(line)) cls += " mm-list"
    else if (/^-{4}|^\.{4}|^\|===/.test(line)) cls += " mm-block"
    else if (/^\/\//.test(line)) cls += " mm-comment"
    else if (line.trim() === "") cls += " mm-empty"

    const w = Math.min(100, Math.max(5, line.length * 1.2))
    html += `<div class="${cls}" style="width:${w}%"></div>`
  }
  container.querySelector(".mm-lines").innerHTML = html

  // Viewport indicator
  const scrollPct = editorScroller.scrollTop / (editorScroller.scrollHeight || 1)
  const viewPct = editorScroller.clientHeight / (editorScroller.scrollHeight || 1)
  const viewport = container.querySelector(".mm-viewport")
  viewport.style.top = (scrollPct * 100) + "%"
  viewport.style.height = Math.max(5, viewPct * 100) + "%"
}

function setupMinimap() {
  const container = document.getElementById("minimap")
  if (!container) return

  // Click to navigate
  container.addEventListener("click", (e) => {
    const rect = container.getBoundingClientRect()
    const pct = (e.clientY - rect.top) / rect.height
    const scroller = asciidocEditor.dom.querySelector(".cm-scroller")
    if (scroller) {
      scroller.scrollTop = pct * (scroller.scrollHeight - scroller.clientHeight)
    }
  })

  // Update on scroll
  const scroller = asciidocEditor.dom.querySelector(".cm-scroller")
  if (scroller) {
    scroller.addEventListener("scroll", () => {
      requestAnimationFrame(() => updateMinimap())
    })
  }

  // Update on content change
  setInterval(updateMinimap, 1000)
  updateMinimap()
}

// --- Breadcrumb ---
function updateBreadcrumb() {
  const el = document.getElementById("breadcrumb")
  if (!el) return

  const pos = asciidocEditor.state.selection.main.head
  const doc = asciidocEditor.state.doc
  const lineNo = doc.lineAt(pos).number
  const lines = doc.toString().split("\n")

  const crumbs = []
  for (let i = 0; i < lineNo; i++) {
    const m = lines[i].match(/^(={1,5})\s+(.+)/)
    if (m) {
      const level = m[1].length
      // Remove deeper or equal levels
      while (crumbs.length > 0 && crumbs[crumbs.length - 1].level >= level) crumbs.pop()
      crumbs.push({ level, title: m[2], line: i })
    }
  }

  if (crumbs.length === 0) {
    el.innerHTML = `<span class="bc-item">Document</span>`
  } else {
    el.innerHTML = crumbs
      .map((c) => `<span class="bc-item" onclick="window.prism.goToLine(${c.line})">${c.title}</span>`)
      .join(`<span class="bc-sep">›</span>`)
  }
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

  // Sync visual editor (si on n'est pas en train d'éditer dedans)
  const ve = document.getElementById("visual-editor")
  if (ve && activeTab !== "visual") {
    ve.innerHTML = result
  }

  renderPreview(result, style)
  markModified()
  updateBreadcrumb()
  updateMinimap()
}

function renderPreview(h, style) {
  const preview = document.getElementById("preview")
  if (!preview || !previewVisible) return
  const doc = preview.contentDocument
  const scrollTop = doc?.documentElement?.scrollTop || 0
  doc.open()
  doc.write(`<html><head><style>${style}</style></head><body>${h}</body></html>`)
  doc.close()
  doc.documentElement.scrollTop = scrollTop
}

function markModified() {
  if (!isModified) { isModified = true; updateStatusBar() }
}

function updateStatusBar() {
  const el = document.getElementById("status-file")
  if (!el) return
  const name = currentFilePath ? currentFilePath.split("/").pop() : "Sans titre"
  el.textContent = name + (isModified ? " •" : "")

  // Cursor position
  const pos = asciidocEditor.state.selection.main.head
  const line = asciidocEditor.state.doc.lineAt(pos)
  const col = pos - line.from + 1
  const posEl = document.getElementById("status-pos")
  if (posEl) posEl.textContent = `Ln ${line.number}, Col ${col}`
}

// --- Toggles ---
function togglePreview() {
  previewVisible = !previewVisible
  document.getElementById("divider").style.display = previewVisible ? "" : "none"
  document.querySelector(".preview-panel").style.display = previewVisible ? "" : "none"
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
  recreateEditors()
  savePref()
}

function toggleZenMode() {
  zenMode = !zenMode
  document.body.classList.toggle("zen", zenMode)
}

function toggleMinimap() {
  minimapVisible = !minimapVisible
  document.getElementById("minimap").classList.toggle("hidden", !minimapVisible)
  if (minimapVisible) updateMinimap()
}

function recreateEditors() {
  const adocContent = asciidocEditor.state.doc.toString()

  const cssContent = styleEditor.state.doc.toString()
  asciidocEditor.destroy(); styleEditor.destroy()
  asciidocEditor = createEditor(document.getElementById("editor-asciidoc"), StreamLanguage.define(asciidoc), adocContent, schedulePreview)
  styleEditor = createEditor(document.getElementById("editor-style"), css(), cssContent, schedulePreview)
  setupMinimap()
}

// --- Sidebar ---
async function loadSidebar() {
  const sidebar = document.querySelector(".sidebar-content")
  if (!sidebar) return
  let h = ""
  try {
    const recent = JSON.parse(await window.getRecentFiles(""))
    if (recent.length > 0) {
      h += `<div class="sidebar-section"><div class="sidebar-title">Récents</div>`
      for (const f of recent) {
        h += `<div class="sidebar-item" onclick="window.prism.openPath('${f}')">${f.split("/").pop()}</div>`
      }
      h += `</div>`
    }
  } catch (e) {}
  try {
    const info = JSON.parse(await window.getGitInfo(""))
    if (info.branch) {
      h += `<div class="sidebar-section"><div class="sidebar-title">Git — ${info.branch}</div>`
      if (!info.clean) h += `<div class="sidebar-hint">${info.modified} modifié(s)</div>`
      const files = JSON.parse(await window.getGitFileTree(""))
      for (const f of files) {
        h += `<div class="sidebar-item" onclick="window.prism.openPath('${f.path}')">${f.name}</div>`
      }
      h += `</div>`
    }
  } catch (e) {}
  if (!h) h = `<div class="sidebar-hint">Ouvrez un fichier pour commencer</div>`
  sidebar.innerHTML = h
}

// --- File operations ---
async function doOpen() {
  const result = await window.openFile("")
  if (result) handleOpenResult(result)
}

async function doOpenPath(path) {
  const result = await window.openFilePath(path)
  if (result) handleOpenResult(result)
}

function handleOpenResult(result) {
  const data = JSON.parse(result)
  if (data.error) { alert("Erreur : " + data.error); return }
  if (data.content === undefined) return
  currentFilePath = data.path || ""
  isModified = false
  replaceEditorContent(asciidocEditor, data.content)
  if (data.css) replaceEditorContent(styleEditor, data.css)
  updateStatusBar(); updateGitStatus(); updatePreview()
  if (sidebarVisible) loadSidebar()
}

async function doSave() {
  const c = asciidocEditor.state.doc.toString()
  const s = styleEditor.state.doc.toString()
  const result = await window.saveFile(c, s, currentFilePath)
  if (!result) return
  const data = JSON.parse(result)
  if (data.error) { alert("Erreur : " + data.error); return }
  if (data.path) currentFilePath = data.path
  isModified = false; updateStatusBar(); updateGitStatus()
}

async function doSaveAs() {
  const c = asciidocEditor.state.doc.toString()
  const s = styleEditor.state.doc.toString()
  const result = await window.saveFileAs(c, s)
  if (!result) return
  const data = JSON.parse(result)
  if (data.error) { alert("Erreur : " + data.error); return }
  if (data.path) currentFilePath = data.path
  isModified = false; updateStatusBar()
}

async function doNew() {
  if (isModified && !confirm("Fichier modifié. Continuer sans sauvegarder ?")) return
  await window.newFile("")
  currentFilePath = ""; isModified = false
  replaceEditorContent(asciidocEditor, defaultAsciidoc)
  replaceEditorContent(styleEditor, defaultCss)
  updateStatusBar(); updatePreview()
}

// --- Git ---
async function updateGitStatus() {
  const el = document.getElementById("status-git")
  if (!el) return
  try {
    const info = JSON.parse(await window.getGitInfo(""))
    if (info.branch) {
      el.textContent = `⎇ ${info.branch}` + (info.clean ? "" : ` +${info.modified}`)
      el.style.display = ""
    } else { el.style.display = "none" }
  } catch (e) { el.style.display = "none" }
}

// --- Exports ---
async function doExport(fn, label) {
  const c = asciidocEditor.state.doc.toString()
  const s = styleEditor.state.doc.toString()
  const result = await fn(c, s)
  if (!result) return
  const data = JSON.parse(result)
  if (data.error) { alert("Erreur " + label + " : " + data.error); return }
  if (data.success) alert(label + " exporté : " + (data.path || data.results?.join("\n")))
}

// --- Preferences ---
function savePref() {
  window.savePreferences(JSON.stringify({
    dark_mode: darkMode, preview_visible: previewVisible, sidebar_visible: sidebarVisible,
  }))
}

// --- Scroll sync ---
function setupScrollSync() {
  const scroller = asciidocEditor.dom.querySelector(".cm-scroller")
  if (!scroller) return
  scroller.addEventListener("scroll", () => {
    const preview = document.getElementById("preview")
    if (!preview || !previewVisible) return
    const pct = scroller.scrollTop / (scroller.scrollHeight - scroller.clientHeight || 1)
    const previewDoc = preview.contentDocument?.documentElement
    if (previewDoc) previewDoc.scrollTop = pct * (previewDoc.scrollHeight - previewDoc.clientHeight)
  })
}

// --- Go to line ---
function goToLine(lineIndex) {
  const line = asciidocEditor.state.doc.line(lineIndex + 1)
  asciidocEditor.dispatch({
    selection: { anchor: line.from },
    scrollIntoView: true,
  })
  asciidocEditor.focus()
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
    else if (mod && e.key === "b" && !e.shiftKey) { e.preventDefault(); toggleSidebar() }
    else if (mod && e.key === "e" && !e.shiftKey) { e.preventDefault(); doExport(window.exportHtml, "HTML") }
    else if (mod && e.shiftKey && e.key === "e") { e.preventDefault(); doExport(window.exportAll, "Tous") }
    else if (mod && e.key === "d") { e.preventDefault(); toggleDarkMode() }
    else if (mod && e.key === "m") { e.preventDefault(); toggleMinimap() }
    else if (e.key === "Escape" && zenMode) { toggleZenMode() }
    else if (mod && e.key === "Enter") { e.preventDefault(); toggleZenMode() }
    // Formatting shortcuts (when in AsciiDoc tab)
    else if (mod && e.key === "b" && e.shiftKey) { e.preventDefault(); applyFormat("bold") }
    else if (mod && e.key === "i") { e.preventDefault(); applyFormat("italic") }
  })
}

// --- Visual editor ---
async function updateVisualEditor() {
  const content = asciidocEditor.state.doc.toString()
  const style = styleEditor.state.doc.toString()
  const result = await window.convertAsciidoc(content)
  const ve = document.getElementById("visual-editor")
  ve.innerHTML = result
  // Appliquer le style utilisateur
  let styleEl = ve.parentElement.querySelector(".visual-user-style")
  if (!styleEl) {
    styleEl = document.createElement("style")
    styleEl.className = "visual-user-style"
    ve.parentElement.prepend(styleEl)
  }
  styleEl.textContent = style.replace(/body\b/g, ".visual-editor")
}

// --- Menu helpers ---
function showAbout() {
  alert("Prism v1.0.0\nEditeur AsciiDoc en Crystal\nhttps://github.com/aloli-crystal/prism")
}

async function openRecent() {
  // Ouvrir la sidebar sur les fichiers récents
  if (!sidebarVisible) toggleSidebar()
}

function doFind() {
  openSearchPanel(asciidocEditor)
}

// --- CLI load ---
function loadFromCli(jsonStr) {
  try { handleOpenResult(jsonStr) } catch (e) {}
}

// --- Init ---
window.addEventListener("DOMContentLoaded", async () => {
  try {
    const prefs = JSON.parse(await window.getPreferences(""))
    darkMode = prefs.dark_mode || false
    previewVisible = prefs.preview_visible !== false
    sidebarVisible = prefs.sidebar_visible || false
    if (darkMode) document.body.classList.add("dark")
  } catch (e) {}

  asciidocEditor = createEditor(document.getElementById("editor-asciidoc"), StreamLanguage.define(asciidoc), defaultAsciidoc, schedulePreview)
  styleEditor = createEditor(document.getElementById("editor-style"), css(), defaultCss, schedulePreview)

  // Visual editor: sync changes back on blur
  const ve = document.getElementById("visual-editor")
  ve.addEventListener("input", () => { markModified() })

  // Tabs
  document.querySelectorAll(".tab[data-group]").forEach((tab) => {
    tab.addEventListener("click", () => {
      const group = tab.dataset.group
      document.querySelectorAll(`.tab[data-group="${group}"]`).forEach((t) => t.classList.remove("active"))
      tab.classList.add("active")
      const target = tab.dataset.tab
      if (group === "editor") {
        activeTab = target
        document.getElementById("editor-asciidoc").classList.toggle("hidden", target !== "asciidoc")
        document.getElementById("editor-visual").classList.toggle("hidden", target !== "visual")
        document.getElementById("editor-style").classList.toggle("hidden", target !== "style")
        if (target === "asciidoc") asciidocEditor.requestMeasure()
        else if (target === "visual") updateVisualEditor()
        else styleEditor.requestMeasure()
      }
    })
  })

  // Format bar
  document.querySelectorAll("[data-format]").forEach((btn) => {
    btn.addEventListener("click", () => applyFormat(btn.dataset.format))
  })

  // Toolbar buttons
  // Les actions sont déclenchées par le menu natif macOS via les raccourcis clavier
  // et par la barre de formatage via data-format

  if (!previewVisible) togglePreview()
  if (sidebarVisible) { document.querySelector(".sidebar").classList.remove("hidden"); loadSidebar() }

  setupDivider(); setupShortcuts(); updateStatusBar(); updatePreview()
  setTimeout(() => { setupScrollSync(); setupMinimap() }, 500)

  // Breadcrumb update on cursor move
  asciidocEditor.dom.addEventListener("click", updateBreadcrumb)
  asciidocEditor.dom.addEventListener("keyup", updateBreadcrumb)
})

// --- Divider ---
function setupDivider() {
  const divider = document.getElementById("divider")
  const panels = document.querySelector(".panels")
  const editorPanel = document.querySelector(".editor-panel")
  let dragging = false
  divider.addEventListener("mousedown", (e) => { dragging = true; document.body.style.cursor = "col-resize"; document.body.style.userSelect = "none"; e.preventDefault() })
  document.addEventListener("mousemove", (e) => {
    if (!dragging) return
    const rect = panels.getBoundingClientRect()
    const sidebarW = sidebarVisible ? document.querySelector(".sidebar").offsetWidth : 0
    const pct = ((e.clientX - rect.left - sidebarW) / (rect.width - sidebarW)) * 100
    editorPanel.style.flex = "none"; editorPanel.style.width = Math.max(20, Math.min(80, pct)) + "%"
  })
  document.addEventListener("mouseup", () => { if (dragging) { dragging = false; document.body.style.cursor = ""; document.body.style.userSelect = "" } })
}

// Expose
window.prism = { updatePreview, togglePreview, toggleSidebar, openPath: doOpenPath, goToLine, loadFromCli, about: showAbout, find: doFind, saveAs: doSaveAs, openRecent }
