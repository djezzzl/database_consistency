require "rails/generators/active_record"

module DatabaseConsistency
  module Generators
    # blabla
    class MigrationGenerator < Rails::Generators::Base
      include ActiveRecord::Generators::Migration
      source_root File.join(__dir__, "templates")

      argument :checker, type: :string, banner: 'Checker Name'

      def copy_migrations
        # binding.pry
        # TODO: Run `Processors.reports(configuration)`
        # migration_template "migration.rb", "db/migrate/blablabla.rb", migration_version: migration_version
      end

      def migration_version
        "[#{ActiveRecord::VERSION::MAJOR}.#{ActiveRecord::VERSION::MINOR}]"
      end
    end
  end
end
