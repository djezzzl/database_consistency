# frozen_string_literal: true

module DatabaseConsistency
  module Writers
    module Autofix
      module Helpers
        module Migration # :nodoc:
          def migration_path(name)
            migration_context = ActiveRecord::Tasks::DatabaseTasks.migration_connection_pool.migration_context

            last = migration_context.migrations.last
            version = ActiveRecord::Migration.next_migration_number(last&.version.to_i + 1)

            "db/migrate/#{version}_#{name.underscore}.rb"
          end

          def migration_path_pattern(name)
            "db/migrate/*_#{name.underscore}.rb"
          end

          def migration_configuration(name)
            {
              migration_name: name.camelcase,
              migration_version: ActiveRecord::Migration.current_version
            }
          end
        end
      end
    end
  end
end
