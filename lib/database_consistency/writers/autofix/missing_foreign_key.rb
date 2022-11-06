# frozen_string_literal: true

module DatabaseConsistency
  module Writers
    module Autofix
      class MissingForeignKey < MigrationBase # :nodoc:
        private

        def migration_name
          "add_#{report.primary_table}_#{report.foreign_table}_foreign_key"
        end

        def template_path
          File.join(__dir__, 'templates', 'missing_foreign_key.tt')
        end
      end
    end
  end
end
