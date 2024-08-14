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

      def check # rubocop:disable Metrics/MethodLength
        Helper.models.flat_map do |model|
          DebugContext.with(model: model.name) do
            next unless model_enabled?(model)

            Helper.first_level_associations(model).flat_map do |association|
              DebugContext.with(association: association.name) do
                enabled_checkers.flat_map do |checker_class|
                  DebugContext.with(checker: checker_class) do
                    checker = checker_class.new(model, association)
                    checker.report_if_enabled?(configuration)
                  end
                end
              end
            end
          end
        end.compact
      end
    end
  end
end
