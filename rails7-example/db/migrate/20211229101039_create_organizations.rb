class CreateOrganizations < ActiveRecord::Migration[6.0]
  def change
    create_table :organizations, id: :bigint do |t|
      t.belongs_to :company, null: false, foreign_key: true, type: :bigint
      t.timestamps
    end
  end
end
