class User < ApplicationRecord
  validates :email, :phone, presence: true, allow_nil: true
  validates :email, :phone, presence: true
  validates :name, :address, presence: true, allow_nil: true
  validates :slug, inclusion: {in: %w[short full]}

  validates :slug, uniqueness: true
  validates :name, uniqueness: { scope: :email }

  validates :tmp, presence: true

  belongs_to :something, class_name: 'Company', foreign_key: :company_id
  belongs_to :company, required: false
  belongs_to :country
  belongs_to :invitable, polymorphic: true
  belongs_to :organization
end
