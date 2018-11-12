class CreateUsers < ActiveRecord::Migration[5.2]
  def change
    create_table :users do |t|
      t.string :email, null: false
      t.string :name, null: false
      t.string :phone
      t.string :address
      t.string :code, null: false
      t.string :slug, null: false

      t.integer :company_id, null: false

      t.integer :invitable_id, null: false
      t.string :invitable_type, null: false

      t.timestamps
    end
  end
end
