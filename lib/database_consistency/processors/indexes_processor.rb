# frozen_string_literal: true

module DatabaseConsistency
  module Processors
    # The class to process indexes
    class IndexesProcessor < BaseProcessor
      CHECKERS = [
        Checkers::UniqueIndexChecker,
        Checkers::RedundantIndexChecker
      ].freeze

      private

      def check # rubocop:disable Metrics/AbcSize
        Helper.parent_models.flat_map do |model|
          next unless configuration.enabled?(model.name.to_s)

          indexes = ActiveRecord::Base.connection.indexes(model.table_name)

          indexes.flat_map do |index|
            enabled_checkers.map do |checker_class|
              checker = checker_class.new(model, index)
              checker.report_if_enabled?(configuration)
            end
          end
        end.compact
      end
    end
  end
end
