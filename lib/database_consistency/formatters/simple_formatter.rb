module DatabaseConsistency
  # The module contains formatters
  module Formatters
    # The simplest formatter
    module SimpleFormatter
      module_function

      # @param [Hash] output
      # @return [String]
      def format(output)
        output.map do |model_name, comparisons|
          comparisons.map do |comparison|
            <<-TEXT
              #{model_name} #{comparison[:status]} #{comparison[:message]} #{comparison[:validator].inspect} #{comparison[:column].inspect}
            TEXT
          end.map(&:lstrip).join("\n")
        end.join("\n")
      end
    end
  end
end
