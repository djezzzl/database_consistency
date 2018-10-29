module DatabaseConsistency
  # This class outputs the comparison result
  class Comparison
    attr_reader :validator, :column

    private_class_method :new

    def initialize(validator, column)
      @validator = validator
      @column = column
    end

    def result(status, message = nil)
      {
        column:    column,
        validator: validator,
        status:    status
      }.tap { |hash| hash[:message] = message if message }
    end

    def self.for(validator, column)
      new(validator, column)
    end
  end
end
