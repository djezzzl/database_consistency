# frozen_string_literal: true

RSpec.describe DatabaseConsistency::Writers::Autofix::Helpers::Migration, :sqlite, :mysql, :postgresql do
  let(:helper) { Class.new { include DatabaseConsistency::Writers::Autofix::Helpers::Migration }.new }

  describe '#migration_path' do
    subject(:migration_path) { helper.migration_path('add_index') }

    before do
      migrations = last_version ? [double('migration', version: last_version)] : []
      allow(helper).to receive(:migration_context).and_return(double('context', migrations: migrations))
      allow(ActiveRecord::Migration).to receive(:next_migration_number) { |number| format('%.14d', number) }
    end

    context 'when the last version is at the end of a minute' do
      let(:last_version) { 20_230_101_000_059 }

      it 'uses the start of the next minute' do
        expect(migration_path).to eq('db/migrate/20230101000100_add_index.rb')
      end
    end

    context 'when the last version is at the end of a day' do
      let(:last_version) { 20_231_231_235_959 }

      it 'uses the start of the next day' do
        expect(migration_path).to eq('db/migrate/20240101000000_add_index.rb')
      end
    end

    context 'when the last version is not a timestamp' do
      let(:last_version) { 5 }

      it 'adds one' do
        expect(migration_path).to eq('db/migrate/00000000000006_add_index.rb')
      end
    end

    context 'when there are no migrations' do
      let(:last_version) { nil }

      it 'starts at one' do
        expect(migration_path).to eq('db/migrate/00000000000001_add_index.rb')
      end
    end
  end
end
