# frozen_string_literal: true

module DatabaseConsistency
  module Writers
    module Autofix
      class MissingForeignKey < MigrationBase # :nodoc:
        private

        def migration_name
          "add_#{report.primary_table}_#{report.primary_key}_#{report.foreign_table}_#{report.foreign_key}_fk"
        end

        def template_path
          File.join(__dir__, 'templates', 'missing_foreign_key.tt')
        end
      end
    end
  end
end
