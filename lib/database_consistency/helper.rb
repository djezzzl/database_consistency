# frozen_string_literal: true

module DatabaseConsistency
  # The module contains helper methods
  module Helper
    module_function

    def welcome_message!
      puts 'Thank you for using the gem. Any contribution is welcome https://github.com/djezzzl/database_consistency!'
      puts '(c) Evgeniy Demin <lawliet.djez@gmail.com>'
    end

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

    # @return [Boolean]
    def check_inclusion?(array, element)
      array.include?(element.to_s) || array.include?(element.to_sym)
    end
  end
end
