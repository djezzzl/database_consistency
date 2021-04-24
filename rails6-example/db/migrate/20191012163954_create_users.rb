class CreateUsers < ActiveRecord::Migration[6.0]
  def change
    create_table :users do |t|
      t.string :email, null: false
      t.string :name, null: false
      t.string :phone
      t.string :address
      t.string :code, null: false
      t.string :slug, null: false
      t.integer :company_id, null: false, limit: 8
      t.integer :country_id, null: false
      t.integer :invitable_id, null: false
      t.string :invitable_type, null: false

      t.timestamps

      t.foreign_key :countries
      t.index :slug, unique: true
      t.index :phone
      t.index %i[phone slug]
    end
  end
end
