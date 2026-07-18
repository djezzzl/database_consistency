# frozen_string_literal: true

module DatabaseConsistency
  module Checkers
    # This class checks that polymorphic association columns have matching null constraints
    class PolymorphicAssociationNullabilityChecker < AssociationChecker
      Report = ReportBuilder.define(
        DatabaseConsistency::Report,
        :foreign_key,
        :foreign_type
      )

      private

      def preconditions
        association.belongs_to? && association.polymorphic? && foreign_key_column && foreign_type_column
      end

      def check
        if foreign_key_column.null == foreign_type_column.null
          report_template(:ok)
        else
          report_template(:fail, error_slug: :polymorphic_association_nullability_mismatch)
        end
      end

      def report_template(status, error_slug: nil)
        Report.new(
          status: status,
          error_slug: error_slug,
          error_message: nil,
          foreign_key: association.foreign_key.to_s,
          foreign_type: association.foreign_type.to_s,
          **report_attributes
        )
      end

      def foreign_key_column
        @foreign_key_column ||= model.columns_hash[association.foreign_key.to_s]
      end

      def foreign_type_column
        @foreign_type_column ||= model.columns_hash[association.foreign_type.to_s]
      end
    end
  end
end
