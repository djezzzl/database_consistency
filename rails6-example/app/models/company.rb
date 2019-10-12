class Company < ApplicationRecord
  has_one :user
  has_one :something # not exists

  class CustomValidator < ActiveModel::Validator
    def validate(record)
    end
  end

  validates_with CustomValidator
end
