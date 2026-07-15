# frozen_string_literal: true

module DatabaseConsistency
  module Writers
    module Simple
      class PolymorphicAssociationNullabilityMismatch < Base # :nodoc:
        private

        def template
          'polymorphic association columns (%<foreign_key>s and %<foreign_type>s) should have matching null constraints'
        end

        def unique_attributes
          {
            foreign_key: report.foreign_key,
            foreign_type: report.foreign_type
          }
        end

        alias attributes unique_attributes
      end
    end
  end
end
