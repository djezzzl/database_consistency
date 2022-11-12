# frozen_string_literal: true

module DatabaseConsistency
  module Writers
    module Simple
      class InconsistentTypes < Base # :nodoc:
        private

        def template
          "foreign key %<fk_name>s with type %<fk_type>s doesn't cover primary key %<pk_name>s with type %<pk_type>s"
        end

        def attributes
          {
            fk_name: report.fk_name,
            fk_type: report.fk_type,
            pk_name: report.pk_name,
            pk_type: report.pk_type
          }
        end
      end
    end
  end
end
