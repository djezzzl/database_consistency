# frozen_string_literal: true

require 'yaml'

module DatabaseConsistency
  # The class to access configuration options
  class Configuration
    CONFIGURATION_PATH = '.database_consistency.yml'

    def initialize(filepath = CONFIGURATION_PATH)
      @configuration = if filepath && File.exist?(filepath)
                         YAML.load_file(filepath, fallback: {})
                       else
                         {}
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
  end
end
