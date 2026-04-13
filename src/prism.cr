require "webview"
require "crystal-asciidoctor"
require "./prism/app"

module Prism
  VERSION = "0.2.0"

  def self.run
    app = App.new
    app.start
  end
end

Prism.run
