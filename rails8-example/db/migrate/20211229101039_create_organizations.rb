class CreateOrganizations < ActiveRecord::Migration[6.0]
  def change
    create_table :organizations, id: :bigserial do |t|
      t.timestamps
    end
  end
end
