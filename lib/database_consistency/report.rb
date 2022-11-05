# frozen_string_literal: true

module DatabaseConsistency
  Report = Struct.new(
    :checker_name,
    :table_or_model_name,
    :column_or_attribute_name,
    :status,
    :message,
    :slug,
    keyword_init: true
  )
end
