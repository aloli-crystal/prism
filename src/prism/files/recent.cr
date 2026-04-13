require "json"

module Prism
  class RecentFiles
    PREFS_DIR  = Path.home / "Library" / "Application Support" / "Prism"
    PREFS_FILE = PREFS_DIR / "recent_files.json"
    MAX_RECENT = 10

    getter list : Array(String)

    def initialize
      @list = load
    end

    def add(path : String)
      @list.reject! { |p| p == path }
      @list.unshift(path)
      @list = @list.first(MAX_RECENT)
      save
    end

    def remove(path : String)
      @list.reject! { |p| p == path }
      save
    end

    def to_json : String
      # Filtrer les fichiers qui n'existent plus
      valid = @list.select { |p| File.exists?(p) }
      valid.to_json
    end

    private def load : Array(String)
      return [] of String unless File.exists?(PREFS_FILE)
      Array(String).from_json(File.read(PREFS_FILE))
    rescue
      [] of String
    end

    private def save
      Dir.mkdir_p(PREFS_DIR) unless Dir.exists?(PREFS_DIR)
      File.write(PREFS_FILE, @list.to_json)
    end
  end
end
