require "json"

module Prism
  class Preferences
    PREFS_DIR  = Path.home / "Library" / "Application Support" / "Prism"
    PREFS_FILE = PREFS_DIR / "preferences.json"

    property editor_width_pct : Float64 = 50.0
    property dark_mode : Bool = false
    property last_directory : String = ""
    property window_width : Int32 = 1280
    property window_height : Int32 = 820
    property preview_visible : Bool = true
    property sidebar_visible : Bool = false

    def initialize
      load
    end

    def save
      Dir.mkdir_p(PREFS_DIR) unless Dir.exists?(PREFS_DIR)
      File.write(PREFS_FILE, to_json)
    end

    def to_json : String
      JSON.build do |json|
        json.object do
          json.field "editor_width_pct", @editor_width_pct
          json.field "dark_mode", @dark_mode
          json.field "last_directory", @last_directory
          json.field "window_width", @window_width
          json.field "window_height", @window_height
          json.field "preview_visible", @preview_visible
          json.field "sidebar_visible", @sidebar_visible
        end
      end
    end

    private def load
      return unless File.exists?(PREFS_FILE)
      data = JSON.parse(File.read(PREFS_FILE))
      @editor_width_pct = data["editor_width_pct"]?.try(&.as_f) || 50.0
      @dark_mode = data["dark_mode"]?.try(&.as_bool) || false
      @last_directory = data["last_directory"]?.try(&.as_s) || ""
      @window_width = data["window_width"]?.try(&.as_i) || 1280
      @window_height = data["window_height"]?.try(&.as_i) || 820
      @preview_visible = data["preview_visible"]?.try(&.as_bool?) || true
      @sidebar_visible = data["sidebar_visible"]?.try(&.as_bool?) || false
    rescue
    end
  end
end
