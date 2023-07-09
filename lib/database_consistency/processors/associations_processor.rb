# frozen_string_literal: true

module DatabaseConsistency
  module Processors
    # The class to process associations
    class AssociationsProcessor < BaseProcessor
      CHECKERS = [
        Checkers::MissingIndexChecker,
        Checkers::ForeignKeyChecker,
        Checkers::ForeignKeyTypeChecker,
        Checkers::ForeignKeyCascadeChecker,
        Checkers::MissingAssociationClassChecker
      ].freeze

      private

      def check # rubocop:disable Metrics/AbcSize
        Helper.models.flat_map do |model|
          next unless configuration.enabled?('DatabaseConsistencyDatabases', Helper.database_name(model)) &&
                      configuration.enabled?(model.name.to_s)

          Helper.first_level_associations(model).flat_map do |association|
            enabled_checkers.flat_map do |checker_class|
              checker = checker_class.new(model, association)
              checker.report_if_enabled?(configuration)
            end
          end
        end.compact
      end
    end
  end
end
