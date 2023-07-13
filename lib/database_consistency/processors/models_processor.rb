# frozen_string_literal: true

module DatabaseConsistency
  module Processors
    # The class to process models
    class ModelsProcessor < BaseProcessor
      CHECKERS = [
        Checkers::MissingTableChecker
      ].freeze

      private

      def check
        Helper.project_models.flat_map do |model|
          next unless configuration.enabled?('DatabaseConsistencyDatabases', Helper.database_name(model)) &&
                      configuration.enabled?(model.name.to_s)

          enabled_checkers.flat_map do |checker_class|
            checker = checker_class.new(model)
            checker.report_if_enabled?(configuration)
          end
        end.compact
      end
    end
  end
end
