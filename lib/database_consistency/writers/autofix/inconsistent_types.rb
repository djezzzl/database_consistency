# frozen_string_literal: true

module DatabaseConsistency
  module Writers
    module Autofix
      class InconsistentTypes < MigrationBase # :nodoc:
        def attributes
          {
            table_to_change: report.table_to_change,
            type_to_set: report.type_to_set,
            fk_name: report.fk_name,
            change_columns: change_columns
          }
        end

        private

        # Types such as "character varying" have characters that are not valid in a migration name.
        def migration_name
          "change_#{report.table_to_change}_#{fk_names.join('_')}_to_#{types.join('_')}".gsub(/\W+/, '_').chomp('_')
        end

        def template_path
          File.join(__dir__, 'templates', 'inconsistent_types.tt')
        end

        # Symbol literals keep names such as "billing.orders" and "character varying" valid Ruby.
        def change_columns
          fk_names.zip(types).reject { |_fk_name, type| type.nil? }.map do |fk_name, type|
            "    change_column #{symbol(report.table_to_change)}, #{symbol(fk_name)}, #{symbol(type)}"
          end.join("\n")
        end

        def symbol(name)
          name.to_sym.inspect
        end

        # Composite keys are joined with "+" and have one type for each column.
        def fk_names
          report.fk_name.split('+')
        end

        def types
          Array(report.type_to_set)
        end
      end
    end
  end
end
