module DatabaseConsistency
  # This module formats output of comparison result
  module ComparisonResult
    module_function

    def format(status, message = nil)
      { status: status }.tap { |hash| hash[:message] = message if message }
    end
  end
end
