# frozen_string_literal: true

require 'yaml'

module DatabaseConsistency
  # The class to access configuration options
  class Configuration
    DEFAULT_PATH = '.database_consistency.yml'

    def initialize(filepaths = DEFAULT_PATH)
      @configuration = Array(filepaths).each_with_object({}) do |filepath, result|
        content =
          if filepath && File.exist?(filepath)
            data = load_yaml_config_file(filepath)
            data.is_a?(Hash) ? data : {}
          else
            {}
          end

        combine_configs!(result, content)
      end
    end

    def debug?
      log_level.to_s.match?(/DEBUG/i)
    end

    def colored?
      if ENV.key?('COLOR')
        ENV['COLOR'].match?(/1|true|yes/)
      else
        settings && settings['color']
      end
    end

    # @return [Boolean]
    def enabled?(*path)
      current = configuration

      path.each do |key|
        current = current[key.to_s]
        return true unless current.is_a?(Hash)

        next if current['enabled'].nil?

        return false unless current['enabled']
      end

      true
    end

    private

    attr_reader :configuration

    def load_yaml_config_file(filepath)
      if YAML.respond_to?(:safe_load_file)
        YAML.safe_load_file(filepath, aliases: true)
      else
        YAML.load_file(filepath)
      end
    end

    def combine_configs!(config, new_config)
      config.merge!(new_config) do |_key, val, new_val|
        if val.is_a?(Hash) && new_val.is_a?(Hash)
          combine_configs!(val, new_val)
        else
          new_val
        end
      end
    end

    def settings
      @settings ||= configuration['DatabaseConsistencySettings']
    end

    def log_level
      @log_level ||=
        if ENV.key?('LOG_LEVEL')
          ENV['LOG_LEVEL']
        else
          settings && settings['log_level']
        end
    end
  end
end
