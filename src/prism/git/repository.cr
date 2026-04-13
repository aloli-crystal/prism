module Prism
  module Git
    class Repository
      getter root : String
      getter? valid : Bool

      def initialize(path : String)
        @root = find_root(path)
        @valid = !@root.empty?
      end

      # Arborescence des fichiers du dépôt
      def file_tree : String
        return "[]" unless valid?
        output = run("ls-files", "--full-name")
        files = output.split("\n").reject(&.empty?)
        build_tree(files).to_json
      end

      # Fichiers .adoc du dépôt
      def adoc_files : String
        return "[]" unless valid?
        output = run("ls-files", "--full-name", "*.adoc", "*.asciidoc", "*.asc")
        files = output.split("\n").reject(&.empty?)
        files.map { |f| {path: File.join(@root, f), name: f} }.to_json
      end

      # État Git d'un fichier
      def file_status(path : String) : String
        return "" unless valid?
        relative = path.sub(@root + "/", "")
        output = run("status", "--porcelain", relative)
        return "clean" if output.strip.empty?
        code = output[0..1].strip
        case code
        when "M"  then "modified"
        when "A"  then "added"
        when "D"  then "deleted"
        when "??" then "untracked"
        when "MM" then "modified"
        else           code
        end
      end

      # Historique d'un fichier
      def file_log(path : String, limit : Int32 = 20) : String
        return "[]" unless valid?
        relative = path.sub(@root + "/", "")
        output = run("log", "--pretty=format:%H|||%an|||%as|||%s", "-n", limit.to_s, "--", relative)
        entries = output.split("\n").reject(&.empty?).map do |line|
          parts = line.split("|||")
          {
            hash:    parts[0]? || "",
            author:  parts[1]? || "",
            date:    parts[2]? || "",
            message: parts[3]? || "",
          }
        end
        entries.to_json
      end

      # Diff d'un fichier avec un commit
      def file_diff(path : String, commit : String = "HEAD") : String
        return "" unless valid?
        relative = path.sub(@root + "/", "")
        run("diff", commit, "--", relative)
      end

      # Branche courante
      def current_branch : String
        return "" unless valid?
        run("branch", "--show-current").strip
      end

      # Status global
      def status_summary : String
        return "{}" unless valid?
        output = run("status", "--porcelain")
        lines = output.split("\n").reject(&.empty?)
        modified = lines.count { |l| l.starts_with?(" M") || l.starts_with?("M ") }
        added = lines.count { |l| l.starts_with?("A ") }
        untracked = lines.count { |l| l.starts_with?("??") }
        {
          branch:    current_branch,
          modified:  modified,
          added:     added,
          untracked: untracked,
          clean:     lines.empty?,
        }.to_json
      end

      private def find_root(path : String) : String
        dir = File.directory?(path) ? path : File.dirname(path)
        output = IO::Memory.new
        status = Process.run("git", ["-C", dir, "rev-parse", "--show-toplevel"],
          output: output, error: Process::Redirect::Close)
        status.success? ? output.to_s.strip : ""
      rescue
        ""
      end

      private def run(*args : String) : String
        output = IO::Memory.new
        Process.run("git", ["-C", @root] + args.to_a,
          output: output, error: Process::Redirect::Close)
        output.to_s
      rescue
        ""
      end

      private def build_tree(files : Array(String)) : Array(NamedTuple(name: String, path: String, type: String, children: Array(NamedTuple(name: String, path: String, type: String, children: Array(Nil))?)))
        # Simplification : retourner une liste plate pour le moment
        # Le frontend construira l'arborescence
        files.map do |f|
          full_path = File.join(@root, f)
          {name: f, path: full_path, type: File.directory?(full_path) ? "dir" : "file", children: [] of Nil}
        end
      end
    end
  end
end
