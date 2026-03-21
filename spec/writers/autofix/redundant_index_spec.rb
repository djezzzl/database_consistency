# frozen_string_literal: true

RSpec.describe DatabaseConsistency::Writers::Autofix::RedundantIndex, :sqlite, :mysql, :postgresql do
  let(:report) do
    double('report', index_name: 'index_users_on_email', table_name: 'users')
  end
  let(:writer) { described_class.new(report) }

  describe '#attributes' do
    subject(:attributes) { writer.attributes }

    it 'returns index_name and table_name from the report' do
      expect(attributes).to eq(index_name: 'index_users_on_email', table_name: 'users')
    end
  end

  describe '#fix!' do
    let(:file_path) { 'db/migrate/20230101000000_remove_index_users_on_email_index.rb' }

    before do
      allow(writer).to receive(:migration_path).with('remove_index_users_on_email_index').and_return(file_path)
      allow(writer).to receive(:migration_path_pattern).with('remove_index_users_on_email_index').and_return(
        'db/migrate/*_remove_index_users_on_email_index.rb'
      )
      allow(Dir).to receive(:[]).with('db/migrate/*_remove_index_users_on_email_index.rb').and_return([])
      allow(File).to receive(:write)
    end

    it 'writes a migration that removes the index' do
      writer.fix!
      expect(File).to have_received(:write).with(
        file_path,
        include("remove_index 'users', name: 'index_users_on_email'")
      )
    end
  end
end
