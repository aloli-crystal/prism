require "webview"
require "crystal-asciidoctor"
require "crystal-asciidoctor-pdf/src/asciidoctor_pdf"
require "crystal-asciidoctor-epub3/src/asciidoctor_epub"
require "./prism/app"

module Prism
  VERSION = "0.2.0"

  def self.run
    app = App.new
    app.start
  end
end

Prism.run
