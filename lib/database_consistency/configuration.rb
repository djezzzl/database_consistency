# frozen_string_literal: true

require 'yaml'

module DatabaseConsistency
  # The class to access configuration options
  class Configuration
    CONFIGURATION_PATH = '.database_consistency.yml'

    def initialize(filepath = CONFIGURATION_PATH)
      @configuration = if filepath && File.exist?(filepath)
                         data = YAML.load_file(filepath)
                         data.is_a?(Hash) ? data : {}
                       else
                         {}
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
