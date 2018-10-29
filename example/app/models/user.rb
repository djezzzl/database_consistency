class User < ApplicationRecord
  validates :email, :phone, presence: true
  validates :name, :address, presence: true, allow_nil: true
end
