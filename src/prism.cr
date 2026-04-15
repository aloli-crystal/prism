require "webview"
require "crystal-asciidoctor"
require "crystal-asciidoctor-pdf/src/asciidoctor_pdf"
require "crystal-asciidoctor-epub3/src/asciidoctor_epub"
require "crystal-appkit"
require "./prism/app"

module Prism
  VERSION = "1.0.0"

  def self.run
    file_arg = ARGV.first? if ARGV.size > 0

    AppKit.init

    app = App.new(file_arg)

    # Créer le menu natif avec les action IDs
    setup_native_menu

    # Connecter les actions du menu natif au webview
    AppKit::Menu.on_action do |action_id|
      app.handle_menu_action(action_id)
    end

    app.start
  end

  private def self.setup_native_menu
    AppKit::Menu.build("Prism") do |menu|
      menu.app_menu("Prism")

      menu.submenu("Fichier") do |m|
        m.item("Nouveau", key: "n", action: "new")
        m.item("Ouvrir…", key: "o", action: "open")
        m.separator
        m.item("Enregistrer", key: "s", action: "save")
        m.item("Enregistrer sous…", key: "s", shift: true, action: "saveAs")
      end

      menu.edit_menu

      menu.submenu("Insertion") do |m|
        m.item("Gras", key: "b", shift: true, action: "fmt:bold")
        m.item("Italique", key: "i", action: "fmt:italic")
        m.item("Monospace", action: "fmt:mono")
        m.separator
        m.item("Titre 1", action: "fmt:h1")
        m.item("Titre 2", action: "fmt:h2")
        m.item("Titre 3", action: "fmt:h3")
        m.separator
        m.item("Liste à puces", action: "fmt:ul")
        m.item("Liste numérotée", action: "fmt:ol")
        m.item("Lien", action: "fmt:link")
        m.item("Image", action: "fmt:image")
        m.item("Bloc de code", action: "fmt:code")
        m.item("Citation", action: "fmt:quote")
        m.item("Tableau", action: "fmt:table")
        m.item("Admonition", action: "fmt:admonition")
      end

      menu.submenu("Affichage") do |m|
        m.item("Sidebar", key: "b", action: "toggleSidebar")
        m.item("Prévisualisation", key: "p", action: "togglePreview")
        m.item("Minimap", key: "m", action: "toggleMinimap")
        m.separator
        m.item("Thème clair/sombre", key: "d", action: "toggleDark")
        m.item("Mode zen", action: "toggleZen")
      end

      menu.submenu("Export") do |m|
        m.item("HTML", key: "e", action: "exportHtml")
        m.item("PDF", action: "exportPdf")
        m.item("EPUB", action: "exportEpub")
        m.separator
        m.item("Tout exporter", key: "e", shift: true, action: "exportAll")
      end

      menu.window_menu
    end
  end
end

Prism.run
