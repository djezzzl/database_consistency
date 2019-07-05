class Company < ApplicationRecord
  has_one :user
  has_one :something # not exists
end
