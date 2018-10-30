module DatabaseConsistency
  # The module contains formatters
  module Writers
    # The simplest formatter
    class SimpleWriter < BaseWriter
      def write
        puts format
      end

      def format
        results.map do |model_name, comparisons|
          comparisons.map do |comparison|
            next unless write?(comparison[:status])
            line(model_name, comparison)
          end.tap(&:compact!).map(&:lstrip).join("\n")
        end.join("\n")
      end

      def line(model_name, comparison)
        <<-TEXT
          #{comparison[:status]} #{comparison[:message]} #{model_name} #{comparison[:validator].inspect} #{comparison[:column].inspect}
        TEXT
      end
    end
  end
end
