# frozen_string_literal: true

module DatabaseConsistency
  module Checkers
    # This class checks that a model pointing to a view has a primary_key set and that column exists
    class ViewPrimaryKeyChecker < ModelChecker
      private

      def preconditions
        ActiveRecord::VERSION::MAJOR >= 5 &&
          !model.abstract_class? &&
          model.connection.view_exists?(model.table_name)
      end

      # Table of possible statuses
      # | primary_key set | column exists | status |
      # | --------------- | ------------- | ------ |
      # | no              | -             | fail   |
      # | yes             | no            | fail   |
      # | yes             | yes           | ok     |
      def check
        if model.primary_key.blank?
          report_template(:fail, error_slug: :view_missing_primary_key)
        elsif !primary_key_column_exists?
          report_template(:fail, error_slug: :view_primary_key_column_missing)
        else
          report_template(:ok)
        end
      end

      def primary_key_column_exists?
        Array(model.primary_key).all? { |key| model.column_names.include?(key.to_s) }
      end
    end
  end
end
