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

    # Initialiser AppKit et créer le menu natif macOS AVANT la webview
    AppKit.init
    setup_native_menu

    app = App.new(file_arg)
    app.start
  end

  private def self.setup_native_menu
    AppKit::Menu.build("Prism") do |menu|
      menu.app_menu("Prism")

      menu.submenu("Fichier") do |m|
        m.item("Nouveau", key: "n")
        m.item("Ouvrir…", key: "o")
        m.separator
        m.item("Enregistrer", key: "s")
        m.item("Enregistrer sous…", key: "s", shift: true)
      end

      menu.edit_menu

      menu.submenu("Insertion") do |m|
        m.item("Gras", key: "b", shift: true)
        m.item("Italique", key: "i")
        m.item("Monospace")
        m.separator
        m.item("Titre 1")
        m.item("Titre 2")
        m.item("Titre 3")
        m.separator
        m.item("Liste à puces")
        m.item("Liste numérotée")
        m.item("Lien")
        m.item("Image")
        m.item("Bloc de code")
        m.item("Citation")
        m.item("Tableau")
        m.item("Admonition")
      end

      menu.submenu("Affichage") do |m|
        m.item("Sidebar", key: "b")
        m.item("Prévisualisation", key: "p")
        m.item("Minimap", key: "m")
        m.separator
        m.item("Thème clair/sombre", key: "d")
        m.item("Mode zen", key: "\r")
      end

      menu.submenu("Export") do |m|
        m.item("HTML", key: "e")
        m.item("PDF")
        m.item("EPUB")
        m.separator
        m.item("Tout exporter", key: "e", shift: true)
      end

      menu.window_menu
    end
  end
end

Prism.run
