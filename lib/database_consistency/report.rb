module DatabaseConsistency
  # This class outputs the report result
  class Report
    attr_reader :opts

    def initialize(opts = {})
      @opts = opts
    end

    def result(status, message)
      {
        status: status,
        message: message
      }.tap { |hash| hash[:opts] = opts unless opts.empty? }
    end
  end
end
