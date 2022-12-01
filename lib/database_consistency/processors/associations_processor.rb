# frozen_string_literal: true

module DatabaseConsistency
  module Processors
    # The class to process associations
    class AssociationsProcessor < BaseProcessor
      CHECKERS = [
        Checkers::MissingIndexChecker,
        Checkers::ForeignKeyChecker,
        Checkers::ForeignKeyTypeChecker,
        Checkers::ForeignKeyCascadeChecker
      ].freeze

      private

      def check
        Helper.models.flat_map do |model|
          next unless configuration.enabled?(model.name.to_s)

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
