module DatabaseConsistency
  # The class to begin
  class Processor
    COMPARATORS = {
      presence: DatabaseConsistency::Comparators::PresenceComparator
    }.freeze

    def begin
      Helper.load_environment!
      Formatters::SimpleFormatter.format(comparisons)
    end

    def comparisons
      Helper.models.each_with_object({}) do |model, hash|
        hash[model.name] = model.validators.flat_map do |validator|
          next unless (comparator = COMPARATORS[validator.kind])

          validator.attributes.map do |attribute|
            next unless (column = Helper.find_field(model, attribute.to_s))

            comparator.compare(validator, column)
          end
        end.compact
      end
    end
  end
end
