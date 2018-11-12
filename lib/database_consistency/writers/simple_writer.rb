module DatabaseConsistency
  # The module contains formatters
  module Writers
    # The simplest formatter
    class SimpleWriter < BaseWriter
      def write
        puts format
      end

      def format
        results.map do |result|
          next unless write?(result[:status])

          line(result)
        end.tap(&:compact!).map(&:lstrip).delete_if(&:empty?).join(delimiter)
      end

      def delimiter
        debug? ? "\n\n" : "\n"
      end

      def line(result)
        "#{result[:status]} #{result[:message]}".tap do |str|
          str.concat " #{result[:opts].inspect}" if debug?
        end
      end
    end
  end
end
