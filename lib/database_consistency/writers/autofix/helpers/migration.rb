# frozen_string_literal: true

require 'time'

module DatabaseConsistency
  module Writers
    module Autofix
      module Helpers
        module Migration # :nodoc:
          def migration_path(name)
            last = migration_context.migrations.last
            version = ActiveRecord::Migration.next_migration_number(next_version_number(last&.version.to_i))

            "db/migrate/#{version}_#{name.underscore}.rb"
          end

          # Adds one second to a timestamp version, so a batch of migrations keeps valid times.
          def next_version_number(last_version)
            time = Time.strptime("#{last_version} +0000", '%Y%m%d%H%M%S %z').utc
            (time + 1).strftime('%Y%m%d%H%M%S').to_i
          rescue ArgumentError
            last_version + 1
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

          def migration_context
            if ActiveRecord::MigrationContext.instance_method(:initialize).arity == 1
              return ActiveRecord::MigrationContext.new(ActiveRecord::Migrator.migrations_paths)
            end

            if ActiveRecord::Base.connection.respond_to?(:schema_migration)
              return ActiveRecord::MigrationContext.new(
                ActiveRecord::Migrator.migrations_paths,
                ActiveRecord::Base.connection.schema_migration
              )
            end

            ActiveRecord::MigrationContext.new(ActiveRecord::Migrator.migrations_paths)
          end
        end
      end
    end
  end
end
