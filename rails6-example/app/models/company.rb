class Company < ApplicationRecord
  has_one :user, required: true
  has_one :something # not exists
  belongs_to :anything # not exists

  enum type: %i[enterprise small]

  class CustomValidator < ActiveModel::Validator
    def validate(record)
    end
  end

  validates_with CustomValidator
end
