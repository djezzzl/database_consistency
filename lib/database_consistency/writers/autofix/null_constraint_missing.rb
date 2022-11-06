# frozen_string_literal: true

module DatabaseConsistency
  module Writers
    module Autofix
      class NullConstraintMissing < MigrationBase # :nodoc:
        private

        def migration_name
          "change_#{report.table_name}_#{report.column_name}_null_constraint"
        end

        def template_path
          File.join(__dir__, 'templates', 'null_constraint_missing.tt')
        end
      end
    end
  end
end
