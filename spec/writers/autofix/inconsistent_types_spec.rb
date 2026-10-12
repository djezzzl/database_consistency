# frozen_string_literal: true

RSpec.describe DatabaseConsistency::Writers::Autofix::InconsistentTypes, :sqlite, :mysql, :postgresql do
  let(:report) do
    double('report', table_to_change: 'orders', type_to_set: ['bigint'], fk_name: 'user_id')
  end
  let(:writer) { described_class.new(report) }

  describe '#attributes' do
    subject(:attributes) { writer.attributes }

    it 'returns the report values and the change_column lines' do
      expect(attributes).to eq(
        table_to_change: 'orders',
        type_to_set: ['bigint'],
        fk_name: 'user_id',
        change_columns: '    change_column :orders, :user_id, :bigint'
      )
    end
  end

  describe '#fix!' do
    let(:migration_name) { 'change_orders_user_id_to_bigint' }
    let(:file_path) { "db/migrate/20230101000000_#{migration_name}.rb" }

    before do
      allow(writer).to receive(:migration_path).with(migration_name).and_return(file_path)
      allow(writer).to receive(:migration_path_pattern).with(migration_name).and_return(
        "db/migrate/*_#{migration_name}.rb"
      )
      allow(Dir).to receive(:[]).with("db/migrate/*_#{migration_name}.rb").and_return([])
      allow(File).to receive(:write)
      allow(ActiveRecord::Migration).to receive(:current_version).and_return('4.2')
    end

    it 'writes a migration that changes the column type' do
      writer.fix!
      expect(File).to have_received(:write).with(
        file_path, include('change_column :orders, :user_id, :bigint')
      )
    end

    context 'when the type is a string, as from PrimaryKeyTypeChecker' do
      let(:report) do
        double('report', table_to_change: 'orders', type_to_set: 'bigserial', fk_name: 'id')
      end
      let(:migration_name) { 'change_orders_id_to_bigserial' }

      it 'writes a migration that changes the column type' do
        writer.fix!
        expect(File).to have_received(:write).with(
          file_path, include('change_column :orders, :id, :bigserial')
        )
      end
    end

    context 'when the type has a space' do
      let(:report) do
        double('report', table_to_change: 'orders', type_to_set: ['character varying'], fk_name: 'user_id')
      end
      let(:migration_name) { 'change_orders_user_id_to_character_varying' }

      it 'writes a valid migration name and type' do
        writer.fix!
        expect(File).to have_received(:write).with(file_path, include('class ChangeOrdersUserIdToCharacterVarying'))
        expect(File).to have_received(:write).with(file_path, include(':user_id, :"character varying"'))
      end
    end

    context 'when the foreign key is composite' do
      let(:report) do
        double('report', table_to_change: 'orders', type_to_set: %w[bigint integer], fk_name: 'user_id+shop_id')
      end
      let(:migration_name) { 'change_orders_user_id_shop_id_to_bigint_integer' }

      it 'changes each column' do
        writer.fix!
        expect(File).to have_received(:write).with(file_path, include('change_column :orders, :user_id, :bigint'))
        expect(File).to have_received(:write).with(file_path, include('change_column :orders, :shop_id, :integer'))
      end
    end

    context 'when there are fewer types than foreign key columns' do
      let(:report) do
        double('report', table_to_change: 'orders', type_to_set: ['bigint'], fk_name: 'user_id+shop_id')
      end
      let(:migration_name) { 'change_orders_user_id_shop_id_to_bigint' }

      it 'changes only the columns that have a type' do
        writer.fix!
        expect(File).to have_received(:write).with(file_path, include('change_column :orders, :user_id, :bigint'))
        expect(File).to have_received(:write).with(file_path, satisfy { |migration| !migration.include?(':shop_id') })
      end
    end

    context 'when the table name has a schema' do
      let(:report) do
        double('report', table_to_change: 'billing.orders', type_to_set: ['bigint'], fk_name: 'user_id')
      end
      let(:migration_name) { 'change_billing_orders_user_id_to_bigint' }

      it 'writes the table name as a quoted symbol' do
        writer.fix!
        expect(File).to have_received(:write).with(file_path, include('change_column :"billing.orders", :user_id'))
      end
    end
  end
end
