# frozen_string_literal: true

module DatabaseConsistency
  module Writers
    module Simple
      class NullConstraintAssociationMissesValidator < Base # :nodoc:
        private

        def template
          'column is NOT NULL but does not have a presence validator for association %<association_name>s'
        end

        def attributes
          {
            association_name: report.association_name
          }
        end

        def unique_attributes
          {
            table_or_model_name: report.table_or_model_name,
            column_or_attribute_name: report.column_or_attribute_name
          }
        end
      end
    end
  end
end
