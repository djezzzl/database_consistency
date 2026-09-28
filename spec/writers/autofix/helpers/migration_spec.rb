# frozen_string_literal: true

RSpec.describe DatabaseConsistency::Writers::Autofix::Helpers::Migration, :sqlite, :mysql, :postgresql do
  let(:including_class) do
    Class.new do
      include DatabaseConsistency::Writers::Autofix::Helpers::Migration
    end
  end
  subject(:helper) { including_class.new }

  describe '#migration_path_pattern' do
    it 'returns a glob pattern for the migration name' do
      pattern = helper.migration_path_pattern('add_users_email_index')
      expect(pattern).to eq('db/migrate/*_add_users_email_index.rb')
    end

    it 'underscores camelcase names' do
      pattern = helper.migration_path_pattern('AddUsersEmailIndex')
      expect(pattern).to eq('db/migrate/*_add_users_email_index.rb')
    end
  end

  describe '#migration_configuration' do
    before do
      allow(ActiveRecord::Migration).to receive(:current_version).and_return('6.1')
    end

    it 'returns a hash with migration_name and migration_version' do
      result = helper.migration_configuration('add_users_email_index')
      expect(result[:migration_name]).to eq('AddUsersEmailIndex')
      expect(result[:migration_version]).to eq('6.1')
    end
  end

  describe '#migration_path' do
    before do
      migrations = double('migrations', last: nil)
      context = double('context', migrations: migrations)
      allow(helper).to receive(:migration_context).and_return(context)
      allow(ActiveRecord::Migration).to receive(:next_migration_number).with(1).and_return('20230101000001')
    end

    it 'returns the path for the new migration file' do
      path = helper.migration_path('add_users_email_index')
      expect(path).to eq('db/migrate/20230101000001_add_users_email_index.rb')
    end
  end
end
