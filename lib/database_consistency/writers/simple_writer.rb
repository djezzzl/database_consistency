# frozen_string_literal: true

module DatabaseConsistency
  # The module contains formatters
  module Writers
    # The simplest formatter
    class SimpleWriter < BaseWriter
      SIMPLE_WRITER_NAMESPACE = 'DatabaseConsistency::Writers::Simple'

      def write
        results.select(&method(:write?))
               .map(&method(:writer))
               .uniq(&:unique_key)
               .each do |writer|
          puts writer.msg
        end
      end

      private

      def write?(report)
        report.status == :fail || config.debug?
      end

      def writer(report)
        klass = writer_klass(report)

        klass.new(report, config: config)
      end

      def writer_klass(report)
        return Simple::ErrorMessage if report.error_slug.nil?

        "#{SIMPLE_WRITER_NAMESPACE}::#{report.error_slug.to_s.camelize}".constantize
      rescue NameError
        Simple::ErrorMessage
      end
    end
  end
end
