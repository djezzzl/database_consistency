require 'yaml'

module DatabaseConsistency
  # The class to access configuration options
  class Configuration
    def initialize(filepath = nil)
      @configuration = if filepath
                         YAML.load_file(filepath)
                       else
                         {}
                       end
    end

    def enabled?(processor)
      name = processor.to_s.split('::').last
      @configuration[name].nil? || @configuration[name] == true
    end
  end
end
