# frozen_string_literal: true

module DatabaseConsistency
  # The module contains helper methods
  module Helper
    module_function

    # Returns list of models to check
    def models
      ActiveRecord::Base.descendants.delete_if(&:abstract_class?)
    end

    # Return list of not inherited models
    def parent_models
      models.group_by(&:table_name).each_value.map do |models|
        models.min_by { |model| models.include?(model.superclass) ? 1 : 0 }
      end
    end

    # Loads all models
    def load_environment!
      Rails.application.eager_load! if defined?(Rails)
    end

    # Find a database field with name equals to attribute
    def find_column(model, attribute)
      attribute_str = attribute.to_s
      model.columns.select.find { |field| field.name == attribute_str }
    end

    # @return [Boolean]
    def check_inclusion?(array, element)
      array.include?(element.to_s) || array.include?(element.to_sym)
    end
  end
end
