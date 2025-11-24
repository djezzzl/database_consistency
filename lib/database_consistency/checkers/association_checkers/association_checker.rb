# frozen_string_literal: true

module DatabaseConsistency
  module Checkers
    # The base class for association checkers
    class AssociationChecker < BaseChecker
      attr_reader :model, :association

      def self.processor
        Processors::AssociationsProcessor
      end

      def initialize(model, association)
        super()
        @model = model
        @association = association
      end

      def column_or_attribute_name
        @column_or_attribute_name ||= association.name.to_s
      end

      def table_or_model_name
        @table_or_model_name ||= model.name.to_s
      end

      def foreign_key_exists? # rubocop:disable Metrics/AbcSize
        model.connection.foreign_keys(model.table_name).any? do |foreign_key|
          (Helper.extract_columns(association.foreign_key.to_s) - Array.wrap(foreign_key.column)).empty? &&
            foreign_key.to_table == association.klass.table_name
        end
      end
    end
  end
end
