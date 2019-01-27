class CreateCompanies < ActiveRecord::Migration[5.2]
  def change
    create_table :companies do |t|
      t.boolean :available, null: false, default: false
      t.timestamps
    end
  end
end
