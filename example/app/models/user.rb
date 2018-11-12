class User < ApplicationRecord
  validates :email, :phone, presence: true
  validates :name, :address, presence: true, allow_nil: true
  validates :slug, inclusion: {in: %w[short full]}

  belongs_to :company
  belongs_to :invitable, polymorphic: true
end
