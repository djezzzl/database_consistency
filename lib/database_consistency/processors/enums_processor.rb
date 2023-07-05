# frozen_string_literal: true

module DatabaseConsistency
  module Processors
    # The class to process enums
    class EnumsProcessor < BaseProcessor
      CHECKERS = [
        Checkers::EnumTypeChecker
      ].freeze

      private

      def check # rubocop:disable Metrics/AbcSize
        Helper.models.flat_map do |model|
          next unless configuration.enabled?('DatabaseConsistencyDatabases', Helper.database_name(model)) &&
                      configuration.enabled?(model.name.to_s)

          model.defined_enums.keys.flat_map do |enum|
            enabled_checkers.flat_map do |checker_class|
              checker = checker_class.new(model, enum)
              checker.report_if_enabled?(configuration)
            end
          end
        end.compact
      end
    end
  end
end
