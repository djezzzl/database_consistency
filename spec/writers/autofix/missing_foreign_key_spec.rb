# frozen_string_literal: true

RSpec.describe DatabaseConsistency::Writers::Autofix::MissingForeignKey, :sqlite, :mysql, :postgresql do
  let(:report) do
    double('report', foreign_table: 'orders', foreign_key: 'user_id', primary_table: 'users', primary_key: 'id')
  end
  let(:writer) { described_class.new(report) }

  describe '#attributes' do
    subject(:attributes) { writer.attributes }

    it 'returns foreign_table, foreign_key, primary_table, and primary_key from the report' do
      expect(attributes).to eq(
        foreign_table: 'orders',
        foreign_key: 'user_id',
        primary_table: 'users',
        primary_key: 'id'
      )
    end
  end

  describe '#fix!' do
    let(:file_path) { 'db/migrate/20230101000000_add_users_id_orders_user_id_fk.rb' }

    before do
      allow(writer).to receive(:migration_path).with('add_users_id_orders_user_id_fk').and_return(file_path)
      allow(writer).to receive(:migration_path_pattern).with('add_users_id_orders_user_id_fk').and_return(
        'db/migrate/*_add_users_id_orders_user_id_fk.rb'
      )
      allow(Dir).to receive(:[]).with('db/migrate/*_add_users_id_orders_user_id_fk.rb').and_return([])
      allow(File).to receive(:write)
      allow(ActiveRecord::Migration).to receive(:current_version).and_return('4.2')
    end

    it 'writes a migration that adds the foreign key constraint' do
      writer.fix!
      expect(File).to have_received(:write).with(
        file_path,
        include('add_foreign_key :orders, :users, column: :user_id, primary_key: :id')
      )
    end
  end
end
