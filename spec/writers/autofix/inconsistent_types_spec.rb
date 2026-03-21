# frozen_string_literal: true

RSpec.describe DatabaseConsistency::Writers::Autofix::InconsistentTypes, :sqlite, :mysql, :postgresql do
  let(:report) do
    double('report', table_to_change: 'orders', type_to_set: 'bigint', fk_name: 'user_id')
  end
  let(:writer) { described_class.new(report) }

  describe '#attributes' do
    subject(:attributes) { writer.attributes }

    it 'returns table_to_change, type_to_set, and fk_name from the report' do
      expect(attributes).to eq(table_to_change: 'orders', type_to_set: 'bigint', fk_name: 'user_id')
    end
  end

  describe '#fix!' do
    let(:file_path) { 'db/migrate/20230101000000_change_orders_user_id_to_bigint.rb' }

    before do
      allow(writer).to receive(:migration_path).with('change_orders_user_id_to_bigint').and_return(file_path)
      allow(writer).to receive(:migration_path_pattern).with('change_orders_user_id_to_bigint').and_return(
        'db/migrate/*_change_orders_user_id_to_bigint.rb'
      )
      allow(Dir).to receive(:[]).with('db/migrate/*_change_orders_user_id_to_bigint.rb').and_return([])
      allow(File).to receive(:write)
    end

    it 'writes a migration that changes the column type' do
      writer.fix!
      expect(File).to have_received(:write).with(
        file_path, include('change_column :orders, :user_id, :bigint')
      )
    end
  end
end
