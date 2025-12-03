class CreateOrganizations < ActiveRecord::Migration[6.0]
  def change
    create_table :organizations, id: :bigserial do |t|
      t.belongs_to :company, null: false, foreign_key: true, type: :bigint
      t.timestamps
    end
  end
end
