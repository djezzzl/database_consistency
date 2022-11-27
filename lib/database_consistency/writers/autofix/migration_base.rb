# frozen_string_literal: true

module DatabaseConsistency
  module Writers
    module Autofix
      class MigrationBase < Base # :nodoc:
        include Helpers::Migration

        def fix!
          File.write(migration_path(migration_name), migration)
        end

        def attributes
          {}
        end

        private

        def migration
          attributes.merge(migration_configuration(migration_name)).reduce(File.read(template_path)) do |str, (k, v)|
            str.gsub("%<#{k}>s", v.to_s)
          end
        end
      end
    end
  end
end
