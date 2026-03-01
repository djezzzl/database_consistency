# frozen_string_literal: true

module DatabaseConsistency
  # The module contains file system helper methods for locating project source files.
  module FilesHelper
    module_function

    # Returns all unique project source file paths (non-gem Ruby files from loaded constants).
    # Memoized so the file system walk happens once per database_consistency run.
    def project_source_files
      @project_source_files ||=
        if Module.respond_to?(:const_source_location)
          collect_source_files
        else
          []
        end
    end

    def collect_source_files
      files = []
      ObjectSpace.each_object(Module) { |mod| files << source_file_path(mod) }
      files.compact.uniq
    end

    def source_file_path(mod)
      return unless (name = mod.name)

      file, = Module.const_source_location(name)
      return unless file && File.exist?(file)
      return if excluded_source_file?(file)

      file
    rescue NameError, ArgumentError
      nil
    end

    def excluded_source_file?(file)
      return true if defined?(Bundler) && file.include?(Bundler.bundle_path.to_s)
      return true if defined?(Gem) && file.include?(Gem::RUBYGEMS_DIR)

      excluded_by_ruby_stdlib?(file)
    end

    def excluded_by_ruby_stdlib?(file)
      return false unless defined?(RbConfig)

      file.include?(RbConfig::CONFIG['rubylibdir']) ||
        file.include?(RbConfig::CONFIG['bindir']) ||
        file.include?(RbConfig::CONFIG['sbindir'])
    end
  end
end
