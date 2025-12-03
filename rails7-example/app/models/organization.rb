class Organization < ApplicationRecord
  has_many :users
  belongs_to :company
end
