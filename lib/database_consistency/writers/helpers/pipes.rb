module DatabaseConsistency
  module Writers
    module Helpers
      module Pipes # :nodoc:
        module_function

        def unique(reports)
          reports.uniq(&:attributes)
        end
      end
    end
  end
end
