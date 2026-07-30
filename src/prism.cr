require "webview"
require "asciicrystal"
require "asciicrystal-pdf/src/asciicrystal_pdf"
require "asciicrystal-epub3/src/asciicrystal_epub"
require "appkit"
require "./prism/app"

module Prism
  # Lue au compile-time depuis `shard.yml` via le macro `read_file`.
  # Cf. note mémoire `feedback_shard_version_macro.md` (mémoire ALOLI).
  VERSION = {{
              (read_file("#{__DIR__}/../shard.yml")
                .lines
                .find(&.starts_with?("version:")) || "version: 0.0.0")
                .gsub(/^version:\s*/, "")
                .chomp
            }}

  USAGE = <<-USAGE
    Usage : prism [FICHIER.adoc]

    Éditeur AsciiDoc / Markdown natif macOS — webview embarqué pour
    la prévisualisation, menus AppKit natifs, export HTML / PDF / EPUB
    via le pipeline asciicrystal.

    Sans argument, ouvre l'éditeur sur un nouveau document.
    Avec argument, ouvre le fichier passé en paramètre.

    Options :
      -h, --help        Affiche cette aide et quitte
      -v, --version     Affiche la version et quitte

    Raccourcis (in-app) :
      ⌘N  Nouveau                 ⌘O  Ouvrir
      ⌘S  Enregistrer              ⇧⌘S Enregistrer sous
      ⌘B  Gras                    ⌘I  Italique
      ⌘E  Export HTML              ⇧⌘E Tout exporter
      ⌘P  Prévisualisation         ⌘D  Thème clair/sombre
    USAGE

  def self.run
    # Court-circuit avant init AppKit pour les flags méta : un GUI
    # ne devrait pas s'ouvrir juste pour `--help` ou `--version`
    # (sinon impossible à scripter, à diagnostiquer en CI, etc.).
    if ARGV.includes?("-h") || ARGV.includes?("--help") || ARGV.first? == "help"
      puts USAGE
      return
    end
    if ARGV.includes?("-v") || ARGV.includes?("--version")
      puts "prism #{VERSION}"
      return
    end

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
