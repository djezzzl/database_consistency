module DatabaseConsistency
  # The class to process all comparators
  class ValidatorsProcessor
    COMPARATORS = {
      presence: DatabaseConsistency::Comparators::PresenceComparator
    }.freeze

    def reports
      Helper.parent_models.flat_map do |model|
        model.validators.flat_map do |validator|
          next unless (comparator = COMPARATORS[validator.kind])

          validator.attributes.map do |attribute|
            next unless (column = Helper.find_field(model, attribute.to_s))

            comparator.compare(validator, model, column)
          end
        end
      end.compact
    end
  end
end
