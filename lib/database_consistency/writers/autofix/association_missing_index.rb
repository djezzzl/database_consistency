# frozen_string_literal: true

module DatabaseConsistency
  module Writers
    module Autofix
      class AssociationMissingIndex < MigrationBase # :nodoc:
        def attributes
          {
            table_name: report.table_name,
            columns: columns,
            index_name: index_name
          }
        end

        private

        def migration_name
          "add_#{report.table_name}_#{columns_key}_index"
        end

        def template_path
          File.join(__dir__, 'templates', 'association_missing_index.tt')
        end

        def columns
          "%w[#{report.columns.join(' ')}]"
        end

        def columns_key
          report.columns.join('_')
        end

        def index_name
          "index_#{report.table_name}_#{columns_key}".first(63)
        end
      end
    end
  end
end
