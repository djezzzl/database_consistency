# frozen_string_literal: true

module DatabaseConsistency
  module Writers
    module Autofix
      class RedundantIndex < MigrationBase # :nodoc:
        private

        def migration_name
          "remove_#{report.index_name}_index"
        end

        def template_path
          File.join(__dir__, 'templates', 'redundant_index.tt')
        end
      end
    end
  end
end
