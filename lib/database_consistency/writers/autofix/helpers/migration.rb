# frozen_string_literal: true

module DatabaseConsistency
  module Writers
    module Autofix
      module Helpers
        module Migration # :nodoc:
          def migration_path(name)
            migration_paths  = ActiveRecord::Migrator.migrations_paths
            schema_migration = ActiveRecord::Base.connection.schema_migration

            last = ActiveRecord::MigrationContext.new(migration_paths, schema_migration).migrations.last
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
