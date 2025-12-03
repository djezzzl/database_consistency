# frozen_string_literal: true

module DatabaseConsistency
  module Writers
    module Simple
      class MissingDependentDestroy < Base # :nodoc:
        private

        def template
          'should have a corresponding has_one/has_many association with dependent option (destroy, delete, delete_all, nullify) or a foreign key with on_delete (cascade, nullify)' # rubocop:disable Layout/LineLength
        end

        def unique_attributes
          {
            model_name: report.model_name,
            attribute_name: report.attribute_name
          }
        end
      end
    end
  end
end
