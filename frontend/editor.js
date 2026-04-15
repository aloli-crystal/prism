import { EditorView, basicSetup } from "codemirror"
import { EditorState } from "@codemirror/state"
import { StreamLanguage } from "@codemirror/language"
import { asciidoc } from "codemirror-asciidoc"
import { css } from "@codemirror/lang-css"
import { search, openSearchPanel } from "@codemirror/search"

// --- Theme (Zed-inspired: minimal, clean) ---
const zedTheme = (dark) =>
  EditorView.theme(
    {
      "&": {
        fontSize: "13.5px",
        fontFamily: '"SF Mono", "Fira Code", Menlo, monospace',
        height: "100%",
        backgroundColor: dark ? "#1e1e1e" : "#fafafa",
        color: dark ? "#c8c8c8" : "#2e2e2e",
      },
      ".cm-content": { padding: "16px 0", caretColor: dark ? "#528bff" : "#0071e3", lineHeight: "1.65" },
      ".cm-cursor": { borderLeftColor: dark ? "#528bff" : "#0071e3", borderLeftWidth: "2px" },
      ".cm-activeLine": { backgroundColor: dark ? "#ffffff06" : "#00000005" },
      ".cm-gutters": {
        backgroundColor: "transparent",
        color: dark ? "#444" : "#c0c0c0",
        border: "none",
        paddingRight: "8px",
      },
      ".cm-activeLineGutter": { backgroundColor: "transparent", color: dark ? "#666" : "#999" },
      ".cm-selectionBackground": { backgroundColor: dark ? "#264f78 !important" : "#d7e8fc !important" },
      "&.cm-focused .cm-selectionBackground": { backgroundColor: dark ? "#264f78 !important" : "#d7e8fc !important" },
      ".cm-panels": { backgroundColor: dark ? "#252526" : "#f5f5f5", border: "none" },
      ".cm-searchMatch": { backgroundColor: dark ? "#515c6a" : "#fff3b0", outline: "none" },
      ".cm-searchMatch-selected": { backgroundColor: dark ? "#264f78" : "#a8d4ff" },
      ".cm-line": { paddingLeft: "4px" },
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
  line-height: 1.75; color: #2e2e2e;
  max-width: 44em; margin: 0 auto; padding: 2em;
}
h1 { font-size: 1.8em; font-weight: 600; margin-bottom: .6em; padding-bottom: .4em; border-bottom: 1px solid #e0e0e0; }
h2 { font-size: 1.3em; font-weight: 600; margin-top: 1.8em; margin-bottom: .5em; }
h3 { font-size: 1.1em; font-weight: 600; margin-top: 1.4em; margin-bottom: .4em; }
strong { font-weight: 600; }
a { color: #0071e3; text-decoration: none; }
a:hover { text-decoration: underline; }
ul, ol { padding-left: 1.5em; }
li { margin-bottom: .4em; }
code, pre { font-family: "SF Mono", Menlo, monospace; font-size: .9em; }
code { background: #f0f0f0; padding: .15em .4em; border-radius: 3px; }
pre { background: #f5f5f5; padding: 1em; border-radius: 6px; overflow-x: auto; }
blockquote { border-left: 2px solid #d0d0d0; padding-left: 1em; color: #666; margin: 1em 0; }
table { border-collapse: collapse; width: 100%; margin: 1em 0; }
th, td { border: 1px solid #e0e0e0; padding: .5em .8em; }
th { background: #f5f5f5; font-weight: 600; }
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
let minimapVisible = false // Hidden by default (Zed style)

// --- Editor ---
function createEditor(parent, lang, doc, onChange) {
  return new EditorView({
    state: EditorState.create({
      doc,
      extensions: [basicSetup, lang, zedTheme(darkMode), search({ top: true }),
        EditorView.updateListener.of((u) => { if (u.docChanged && onChange) onChange() }),
      ],
    }),
    parent,
  })
}

function replaceContent(editor, text) {
  editor.dispatch({ changes: { from: 0, to: editor.state.doc.length, insert: text } })
}

// --- AsciiDoc formatting (source mode) ---
function insertAround(before, after) {
  const e = asciidocEditor, sel = e.state.selection.main
  const txt = e.state.sliceDoc(sel.from, sel.to)
  e.dispatch({
    changes: { from: sel.from, to: sel.to, insert: before + txt + after },
    selection: { anchor: sel.from + before.length, head: sel.from + before.length + txt.length },
  })
  e.focus()
}

function insertAtLine(prefix) {
  const e = asciidocEditor, line = e.state.doc.lineAt(e.state.selection.main.from)
  e.dispatch({ changes: { from: line.from, to: line.from, insert: prefix } })
  e.focus()
}

function applyFormat(fmt) {
  if (activeTab === "visual") { applyVisualFormat(fmt); return }
  switch (fmt) {
    case "bold": insertAround("*", "*"); break
    case "italic": insertAround("_", "_"); break
    case "mono": insertAround("`", "`"); break
    case "h1": insertAtLine("= "); break
    case "h2": insertAtLine("== "); break
    case "h3": insertAtLine("=== "); break
    case "ul": insertAtLine("* "); break
    case "ol": insertAtLine(". "); break
    case "link": insertAround("https://", "[lien]"); break
    case "image": insertAround("image::", "[alt]"); break
    case "code": {
      const sel = asciidocEditor.state.selection.main
      const t = asciidocEditor.state.sliceDoc(sel.from, sel.to)
      t.includes("\n") ? insertAround("[source]\n----\n", "\n----") : insertAround("`", "`")
      break
    }
    case "quote": insertAround("[quote]\n____\n", "\n____"); break
    case "table": insertAround(`[cols="1,1", options="header"]\n|===\n| Col 1 | Col 2\n\n| A | B\n|===`, ""); break
    case "admonition": insertAtLine("NOTE: "); break
  }
  schedulePreview()
}

function applyVisualFormat(fmt) {
  const ve = document.getElementById("visual-editor")
  ve.focus()
  switch (fmt) {
    case "bold": document.execCommand("bold"); break
    case "italic": document.execCommand("italic"); break
    case "mono": document.execCommand("insertHTML", false, "<code>" + (window.getSelection().toString() || "code") + "</code>"); break
    case "h1": document.execCommand("formatBlock", false, "h1"); break
    case "h2": document.execCommand("formatBlock", false, "h2"); break
    case "h3": document.execCommand("formatBlock", false, "h3"); break
    case "ul": document.execCommand("insertUnorderedList"); break
    case "ol": document.execCommand("insertOrderedList"); break
    case "link": { const u = prompt("URL :"); if (u) document.execCommand("createLink", false, u); break }
    case "quote": document.execCommand("formatBlock", false, "blockquote"); break
  }
}

// --- HTML → AsciiDoc converter ---
function htmlToAsciidoc(el) {
  let out = ""
  for (const node of el.childNodes) {
    if (node.nodeType === 3) { out += node.textContent; continue }
    if (node.nodeType !== 1) continue
    const tag = node.tagName.toLowerCase()
    const inner = node.innerHTML ? htmlToAsciidocInline(node) : ""
    const text = node.textContent || ""
    switch (tag) {
      case "h1": out += "\n= " + text + "\n"; break
      case "h2": out += "\n== " + text + "\n"; break
      case "h3": out += "\n=== " + text + "\n"; break
      case "h4": out += "\n==== " + text + "\n"; break
      case "p": out += "\n" + htmlToAsciidocInline(node) + "\n"; break
      case "strong": case "b": out += "*" + text + "*"; break
      case "em": case "i": out += "_" + text + "_"; break
      case "code": out += "`" + text + "`"; break
      case "pre": out += "\n----\n" + text + "\n----\n"; break
      case "blockquote": out += "\n____\n" + htmlToAsciidoc(node) + "\n____\n"; break
      case "ul": out += "\n" + htmlToAsciidocList(node, "*") + "\n"; break
      case "ol": out += "\n" + htmlToAsciidocList(node, ".") + "\n"; break
      case "a": out += node.href ? node.href + "[" + text + "]" : text; break
      case "br": out += " +\n"; break
      case "div": out += "\n" + htmlToAsciidoc(node) + "\n"; break
      default: out += htmlToAsciidoc(node); break
    }
  }
  return out
}

function htmlToAsciidocInline(el) {
  let out = ""
  for (const node of el.childNodes) {
    if (node.nodeType === 3) { out += node.textContent; continue }
    if (node.nodeType !== 1) continue
    const tag = node.tagName.toLowerCase()
    const text = node.textContent || ""
    switch (tag) {
      case "strong": case "b": out += "*" + text + "*"; break
      case "em": case "i": out += "_" + text + "_"; break
      case "code": out += "`" + text + "`"; break
      case "a": out += (node.href || "") + "[" + text + "]"; break
      default: out += text; break
    }
  }
  return out
}

function htmlToAsciidocList(el, marker) {
  let out = ""
  for (const li of el.children) {
    if (li.tagName.toLowerCase() === "li") out += marker + " " + li.textContent.trim() + "\n"
  }
  return out
}

// --- Visual editor ---
async function updateVisualEditor() {
  const content = asciidocEditor.state.doc.toString()
  const style = styleEditor.state.doc.toString()
  const result = await window.convertAsciidoc(content)
  const ve = document.getElementById("visual-editor")
  // Retirer le TOC auto-généré (pas éditable)
  const tmp = document.createElement("div")
  tmp.innerHTML = result
  const toc = tmp.querySelector("#toc")
  if (toc) toc.remove()
  ve.innerHTML = tmp.innerHTML
  let styleEl = ve.parentElement.querySelector(".visual-user-style")
  if (!styleEl) { styleEl = document.createElement("style"); styleEl.className = "visual-user-style"; ve.parentElement.prepend(styleEl) }
  styleEl.textContent = style.replace(/body\b/g, "#visual-editor")
}

function syncVisualToAsciidoc() {
  const ve = document.getElementById("visual-editor")
  if (!ve) return
  const adoc = htmlToAsciidoc(ve).trim()
  replaceContent(asciidocEditor, adoc)
  schedulePreview()
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
  if (activeTab !== "visual") { document.getElementById("visual-editor").innerHTML = result }
  renderPreview(result, style)
  markModified()
  updateBreadcrumb()
  updateMinimap()
}

function renderPreview(h, style) {
  const p = document.getElementById("preview")
  if (!p || !previewVisible) return
  const d = p.contentDocument, st = d?.documentElement?.scrollTop || 0
  d.open(); d.write(`<html><head><style>${style}</style></head><body>${h}</body></html>`); d.close()
  d.documentElement.scrollTop = st
}

function markModified() { if (!isModified) { isModified = true; updateStatus() } }

function updateStatus() {
  const el = document.getElementById("status-file")
  if (!el) return
  el.textContent = (currentFilePath ? currentFilePath.split("/").pop() : "Sans titre") + (isModified ? " •" : "")
  const pos = asciidocEditor.state.selection.main.head
  const line = asciidocEditor.state.doc.lineAt(pos)
  const posEl = document.getElementById("status-pos")
  if (posEl) posEl.textContent = `${line.number}:${pos - line.from + 1}`
}

// --- Breadcrumb ---
function updateBreadcrumb() {
  const el = document.getElementById("breadcrumb")
  if (!el) return
  const pos = asciidocEditor.state.selection.main.head
  const lines = asciidocEditor.state.doc.toString().split("\n")
  const lineNo = asciidocEditor.state.doc.lineAt(pos).number
  const crumbs = []
  for (let i = 0; i < lineNo; i++) {
    const m = lines[i].match(/^(={1,5})\s+(.+)/)
    if (m) {
      while (crumbs.length > 0 && crumbs[crumbs.length - 1].level >= m[1].length) crumbs.pop()
      crumbs.push({ level: m[1].length, title: m[2], line: i })
    }
  }
  el.innerHTML = crumbs.length === 0
    ? `<span class="bc-item">Document</span>`
    : crumbs.map((c) => `<span class="bc-item" onclick="window.prism.goToLine(${c.line})">${c.title}</span>`).join(`<span class="bc-sep">›</span>`)
}

// --- Minimap ---
function updateMinimap() {
  const c = document.getElementById("minimap")
  if (!c || !minimapVisible) return
  const lines = asciidocEditor.state.doc.toString().split("\n")
  const scroller = asciidocEditor.dom.querySelector(".cm-scroller")
  if (!scroller) return
  let h = ""
  for (const line of lines) {
    let cls = "mm-line"
    if (/^={1,5}\s/.test(line)) cls += " mm-h"
    else if (/^\*\s|^\.\s/.test(line)) cls += " mm-l"
    else if (line.trim() === "") cls += " mm-e"
    h += `<div class="${cls}" style="width:${Math.min(100, Math.max(5, line.length * 1.2))}%"></div>`
  }
  c.querySelector(".mm-lines").innerHTML = h
  const pct = scroller.scrollTop / (scroller.scrollHeight || 1)
  const vp = scroller.clientHeight / (scroller.scrollHeight || 1)
  const v = c.querySelector(".mm-viewport")
  v.style.top = (pct * 100) + "%"
  v.style.height = Math.max(5, vp * 100) + "%"
}

function setupMinimap() {
  const c = document.getElementById("minimap")
  if (!c) return
  c.addEventListener("click", (e) => {
    const pct = (e.clientY - c.getBoundingClientRect().top) / c.offsetHeight
    const s = asciidocEditor.dom.querySelector(".cm-scroller")
    if (s) s.scrollTop = pct * (s.scrollHeight - s.clientHeight)
  })
  const s = asciidocEditor.dom.querySelector(".cm-scroller")
  if (s) s.addEventListener("scroll", () => requestAnimationFrame(updateMinimap))
}

// --- Toggles ---
function togglePreview() { previewVisible = !previewVisible; applyLayout(); if (previewVisible) updatePreview(); savePref() }
function toggleSidebar() { sidebarVisible = !sidebarVisible; applyLayout(); if (sidebarVisible) loadSidebar(); savePref() }
function toggleDark() { darkMode = !darkMode; document.body.classList.toggle("dark", darkMode); recreate(); savePref() }
function toggleZen() { zenMode = !zenMode; document.body.classList.toggle("zen", zenMode) }
function toggleMinimap() { minimapVisible = !minimapVisible; applyLayout(); if (minimapVisible) updateMinimap() }

function applyLayout() {
  document.getElementById("divider").style.display = previewVisible ? "" : "none"
  document.querySelector(".preview-panel").style.display = previewVisible ? "" : "none"
  document.querySelector(".sidebar").classList.toggle("hidden", !sidebarVisible)
  document.getElementById("minimap").classList.toggle("hidden", !minimapVisible)
}

function recreate() {
  const a = asciidocEditor.state.doc.toString(), c = styleEditor.state.doc.toString()
  asciidocEditor.destroy(); styleEditor.destroy()
  asciidocEditor = createEditor(document.getElementById("editor-asciidoc"), StreamLanguage.define(asciidoc), a, schedulePreview)
  styleEditor = createEditor(document.getElementById("editor-style"), css(), c, schedulePreview)
  setupMinimap()
}

// --- Sidebar ---
async function loadSidebar() {
  const sb = document.querySelector(".sidebar-content")
  if (!sb) return
  let h = ""
  try {
    const r = JSON.parse(await window.getRecentFiles(""))
    if (r.length > 0) {
      h += `<div class="sb-section"><div class="sb-title">Récents</div>`
      for (const f of r) h += `<div class="sb-item" onclick="window.prism.openPath('${f}')">${f.split("/").pop()}</div>`
      h += `</div>`
    }
  } catch (e) {}
  try {
    const info = JSON.parse(await window.getGitInfo(""))
    if (info.branch) {
      h += `<div class="sb-section"><div class="sb-title">Git — ${info.branch}</div>`
      const files = JSON.parse(await window.getGitFileTree(""))
      for (const f of files) h += `<div class="sb-item" onclick="window.prism.openPath('${f.path}')">${f.name}</div>`
      h += `</div>`
    }
  } catch (e) {}
  if (!h) h = `<div class="sb-hint">Ouvrez un fichier pour commencer</div>`
  sb.innerHTML = h
}

// --- File ops ---
async function doOpen() { const r = await window.openFile(""); if (r) handleOpen(r) }
async function doOpenPath(p) { const r = await window.openFilePath(p); if (r) handleOpen(r) }
function handleOpen(r) {
  const d = JSON.parse(r); if (d.error) { alert(d.error); return }; if (d.content === undefined) return
  currentFilePath = d.path || ""; isModified = false
  replaceContent(asciidocEditor, d.content); if (d.css) replaceContent(styleEditor, d.css)
  updateStatus(); updateGit(); updatePreview(); if (sidebarVisible) loadSidebar()
}
async function doSave() {
  const r = await window.saveFile(asciidocEditor.state.doc.toString(), styleEditor.state.doc.toString(), currentFilePath)
  if (!r) return; const d = JSON.parse(r); if (d.error) { alert(d.error); return }
  if (d.path) currentFilePath = d.path; isModified = false; updateStatus(); updateGit()
}
async function doSaveAs() {
  const r = await window.saveFileAs(asciidocEditor.state.doc.toString(), styleEditor.state.doc.toString())
  if (!r) return; const d = JSON.parse(r); if (d.error) { alert(d.error); return }
  if (d.path) currentFilePath = d.path; isModified = false; updateStatus()
}
async function doNew() {
  if (isModified && !confirm("Fichier modifié. Continuer ?")) return
  await window.newFile(""); currentFilePath = ""; isModified = false
  replaceContent(asciidocEditor, defaultAsciidoc); replaceContent(styleEditor, defaultCss)
  updateStatus(); updatePreview()
}

// --- Git ---
async function updateGit() {
  const el = document.getElementById("status-git"); if (!el) return
  try { const i = JSON.parse(await window.getGitInfo("")); el.textContent = i.branch ? `${i.branch}${i.clean ? "" : " +" + i.modified}` : ""; el.style.display = i.branch ? "" : "none" } catch (e) { el.style.display = "none" }
}

// --- Export ---
async function doExport(fn, label) {
  const r = await fn(asciidocEditor.state.doc.toString(), styleEditor.state.doc.toString())
  if (!r) return; const d = JSON.parse(r)
  if (d.error) alert("Erreur " + label + ": " + d.error)
  else if (d.success) alert(label + " exporté: " + (d.path || d.results?.join("\n")))
}

// --- Prefs ---
function savePref() { window.savePreferences(JSON.stringify({ dark_mode: darkMode, preview_visible: previewVisible, sidebar_visible: sidebarVisible })) }

// --- Scroll sync ---
function setupScroll() {
  const s = asciidocEditor.dom.querySelector(".cm-scroller")
  if (!s) return
  s.addEventListener("scroll", () => {
    const p = document.getElementById("preview")
    if (!p || !previewVisible) return
    const pct = s.scrollTop / (s.scrollHeight - s.clientHeight || 1)
    const pd = p.contentDocument?.documentElement
    if (pd) pd.scrollTop = pct * (pd.scrollHeight - pd.clientHeight)
  })
}

function goToLine(i) {
  const l = asciidocEditor.state.doc.line(i + 1)
  asciidocEditor.dispatch({ selection: { anchor: l.from }, scrollIntoView: true }); asciidocEditor.focus()
}

// --- Menu action handler (called from native macOS menu via Crystal) ---
function menuAction(id) {
  if (id.startsWith("fmt:")) { applyFormat(id.slice(4)); return }
  switch (id) {
    case "new": doNew(); break
    case "open": doOpen(); break
    case "save": doSave(); break
    case "saveAs": doSaveAs(); break
    case "toggleSidebar": toggleSidebar(); break
    case "togglePreview": togglePreview(); break
    case "toggleMinimap": toggleMinimap(); break
    case "toggleDark": toggleDark(); break
    case "toggleZen": toggleZen(); break
    case "exportHtml": doExport(window.exportHtml, "HTML"); break
    case "exportPdf": doExport(window.exportPdf, "PDF"); break
    case "exportEpub": doExport(window.exportEpub, "EPUB"); break
    case "exportAll": doExport(window.exportAll, "Tous"); break
  }
}

// --- Keyboard shortcuts ---
function setupKeys() {
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
    else if (mod && e.key === "d") { e.preventDefault(); toggleDark() }
    else if (mod && e.key === "m") { e.preventDefault(); toggleMinimap() }
    else if (e.key === "Escape" && zenMode) { toggleZen() }
    else if (mod && e.key === "Enter") { e.preventDefault(); toggleZen() }
    else if (mod && e.key === "b" && e.shiftKey) { e.preventDefault(); applyFormat("bold") }
    else if (mod && e.key === "i") { e.preventDefault(); applyFormat("italic") }
  })
}

// --- Divider ---
function setupDivider() {
  const dv = document.getElementById("divider"), panels = document.querySelector(".panels"), ep = document.querySelector(".editor-panel")
  let drag = false
  dv.addEventListener("mousedown", (e) => { drag = true; document.body.style.cursor = "col-resize"; document.body.style.userSelect = "none"; e.preventDefault() })
  document.addEventListener("mousemove", (e) => {
    if (!drag) return
    const r = panels.getBoundingClientRect(), sw = sidebarVisible ? document.querySelector(".sidebar").offsetWidth : 0
    ep.style.flex = "none"; ep.style.width = Math.max(20, Math.min(80, ((e.clientX - r.left - sw) / (r.width - sw)) * 100)) + "%"
  })
  document.addEventListener("mouseup", () => { if (drag) { drag = false; document.body.style.cursor = ""; document.body.style.userSelect = "" } })
}

function loadFromCli(j) { try { handleOpen(j) } catch (e) {} }

// --- Init ---
window.addEventListener("DOMContentLoaded", async () => {
  try {
    const p = JSON.parse(await window.getPreferences(""))
    darkMode = p.dark_mode || false; previewVisible = p.preview_visible !== false; sidebarVisible = p.sidebar_visible || false
    if (darkMode) document.body.classList.add("dark")
  } catch (e) {}

  asciidocEditor = createEditor(document.getElementById("editor-asciidoc"), StreamLanguage.define(asciidoc), defaultAsciidoc, schedulePreview)
  styleEditor = createEditor(document.getElementById("editor-style"), css(), defaultCss, schedulePreview)

  // Tabs
  document.querySelectorAll(".tab[data-group]").forEach((tab) => {
    tab.addEventListener("click", () => {
      const g = tab.dataset.group
      document.querySelectorAll(`.tab[data-group="${g}"]`).forEach((t) => t.classList.remove("active"))
      tab.classList.add("active")
      const target = tab.dataset.tab
      if (g === "editor") {
        // Sync visual→asciidoc when leaving visual tab
        if (activeTab === "visual" && target !== "visual") syncVisualToAsciidoc()
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
  document.querySelectorAll("[data-format]").forEach((b) => b.addEventListener("click", () => applyFormat(b.dataset.format)))

  applyLayout()
  if (sidebarVisible) loadSidebar()
  setupDivider(); setupKeys(); updateStatus(); updatePreview()
  setTimeout(() => { setupScroll(); setupMinimap() }, 500)
  asciidocEditor.dom.addEventListener("click", updateBreadcrumb)
  asciidocEditor.dom.addEventListener("keyup", () => { updateBreadcrumb(); updateStatus() })
})

window.prism = { updatePreview, togglePreview, toggleSidebar, openPath: doOpenPath, goToLine, loadFromCli, menuAction, about: () => alert("Prism v1.0\nÉditeur AsciiDoc en Crystal"), find: () => openSearchPanel(asciidocEditor), saveAs: doSaveAs, openRecent: () => { if (!sidebarVisible) toggleSidebar() } }
