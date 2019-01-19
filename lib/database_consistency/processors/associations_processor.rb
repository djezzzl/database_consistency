# frozen_string_literal: true

module DatabaseConsistency
  module Processors
    # The class to process associations
    class AssociationsProcessor < BaseProcessor
      CHECKERS = [
        Checkers::MissingIndexChecker
      ].freeze

      private

      def check
        Helper.models.flat_map do |model|
          model.reflect_on_all_associations.flat_map do |association|
            CHECKERS.map do |checker_class|
              checker = checker_class.new(model, association)
              checker.report if checker.enabled?(configuration)
            end
          end
        end.compact
      end
    end
  end
end
