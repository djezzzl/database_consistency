module DatabaseConsistency
  # The class to process missing validators
  class DatabaseProcessor
    VERIFIERS = [
      ColumnVerifiers::PresenceMissingVerifier
    ].freeze

    def reports
      Helper.parent_models.flat_map do |model|
        model.columns.flat_map do |column|
          VERIFIERS.map do |verifier|
            verifier.verify(model, column)
          end
        end
      end.compact
    end
  end
end
