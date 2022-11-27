class CreateCompanies < ActiveRecord::Migration[6.0]
  def change
    create_table :companies do |t|
      t.boolean :available, null: false, default: false
      t.string :note, limit: 256
      t.string :type
      t.timestamps
    end
  end
end
