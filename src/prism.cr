require "webview"
require "./prism/app"

module Prism
  VERSION = "0.1.0"

  def self.run
    app = App.new
    app.start
  end
end

Prism.run
