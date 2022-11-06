# frozen_string_literal: true

module DatabaseConsistency
  module Writers
    module Autofix
      class MissingForeignKey < Base # :nodoc:
        include Helpers::Migration

        TEMPLATE_PATH = File.join(__dir__, 'templates', 'missing_foreign_key.tt')

        def fix!
          File.write(migration_path(migration_name), migration)
        end

        private

        def migration_name
          "add_#{report.primary_table}_#{report.foreign_table}_foreign_key"
        end

        def migration
          File.read(TEMPLATE_PATH) % report.attributes.merge(migration_configuration(migration_name))
        end
      end
    end
  end
end
