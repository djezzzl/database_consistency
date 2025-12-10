# frozen_string_literal: true

module DatabaseConsistency
  module Checkers
    # This class checks for models that need a dependent destroy association
    class MissingDependentDestroyChecker < AssociationChecker
      Report = ReportBuilder.define(
        DatabaseConsistency::Report,
        :model_name,
        :attribute_name
      )

      DEPENDENT_OPTIONS = %i[destroy delete delete_all nullify restrict_with_error restrict_with_exception].freeze

      private

      def preconditions
        association.belongs_to? && foreign_key_exists?
      end

      def check
        if dependent_destroy_exists? || cascade?
          report_template(:ok)
        else
          report_template(:fail, error_slug: :missing_dependent_destroy)
        end
      end

      def dependent_destroy_exists?
        association.klass.reflect_on_all_associations.any? do |association|
          %i[has_many has_one].include?(association.macro) &&
            DEPENDENT_OPTIONS.include?(association.options[:dependent]) &&
            association.table_name == model.table_name
        end
      end

      def foreign_key
        association.klass
                   .connection
                   .foreign_keys(model.table_name)
                   .find { |fk| fk.column == association.foreign_key.to_s }
      end

      def cascade?
        %i[cascade nullify].include? foreign_key.options[:on_delete]
      end

      def report_template(status, error_slug: nil)
        Report.new(
          status: status,
          error_message: nil,
          error_slug: error_slug,
          model_name: association.class_name,
          attribute_name: model.table_name,
          **report_attributes
        )
      end
    end
  end
end
