# frozen_string_literal: true

module DatabaseConsistency
  module Writers
    module Simple
      class PolymorphicAssociationNullabilityMismatch < Base # :nodoc:
        private

        def template
          'polymorphic association columns (%<foreign_key>s and %<foreign_type>s) should have matching null constraints'
        end

        def attributes
          {
            foreign_key: report.foreign_key,
            foreign_type: report.foreign_type
          }
        end

        def unique_attributes
          {
            table_or_model_name: report.table_or_model_name,
            column_or_attribute_name: report.column_or_attribute_name,
            foreign_key: report.foreign_key,
            foreign_type: report.foreign_type
          }
        end
      end
    end
  end
end
