# frozen_string_literal: true

module DatabaseConsistency
  module Writers
    module Simple
      class MissingForeignKeyCascade < Base # :nodoc:
        private

        def template
          'should have a foreign key %<cascade_option>s in the database'
        end

        def attributes
          {
            cascade_option: cascade_option_text
          }
        end

        # nil stands for a foreign key without an on_delete option
        def cascade_option_text
          options = report.cascade_option.compact.map { |option| "with on_delete: :#{option}" }
          options << 'without on_delete' if report.cascade_option.include?(nil)
          options.join(' or ')
        end

        def unique_attributes
          {
            foreign_table: report.foreign_table,
            foreign_key: report.foreign_key,
            primary_table: report.primary_table,
            primary_key: report.primary_key,
            cascade_option: report.cascade_option
          }
        end
      end
    end
  end
end
