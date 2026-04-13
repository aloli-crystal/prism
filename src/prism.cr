require "webview"
require "crystal-asciidoctor"
require "crystal-asciidoctor-pdf/src/asciidoctor_pdf"
require "crystal-asciidoctor-epub3/src/asciidoctor_epub"
require "./prism/app"

module Prism
  VERSION = "1.0.0"

  def self.run
    # Support CLI : prm <fichier> ou prm <dossier>
    file_arg = ARGV.first? if ARGV.size > 0

    app = App.new(file_arg)
    app.start
  end
end

Prism.run
