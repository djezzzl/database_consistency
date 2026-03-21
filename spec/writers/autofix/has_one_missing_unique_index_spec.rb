# frozen_string_literal: true

RSpec.describe DatabaseConsistency::Writers::Autofix::HasOneMissingUniqueIndex, :sqlite, :mysql, :postgresql do
  let(:report) do
    double('report', table_name: 'posts', columns: ['user_id'])
  end
  let(:writer) { described_class.new(report) }

  describe '#attributes' do
    subject(:attributes) { writer.attributes }

    it 'includes unique: true' do
      expect(attributes).to include(unique: true)
    end

    it 'includes table_name, columns, and index_name from the report' do
      expect(attributes).to include(table_name: 'posts', columns: ':user_id', index_name: 'index_posts_user_id')
    end
  end

  describe '#fix!' do
    let(:file_path) { 'db/migrate/20230101000000_add_posts_user_id_index.rb' }

    before do
      allow(writer).to receive(:migration_path).with('add_posts_user_id_index').and_return(file_path)
      allow(writer).to receive(:migration_path_pattern).with('add_posts_user_id_index').and_return(
        'db/migrate/*_add_posts_user_id_index.rb'
      )
      allow(Dir).to receive(:[]).with('db/migrate/*_add_posts_user_id_index.rb').and_return([])
      allow(File).to receive(:write)
    end

    it 'writes a migration with unique: true' do
      writer.fix!
      expect(File).to have_received(:write).with(
        file_path, include('add_index :posts, :user_id, name: :index_posts_user_id, unique: true')
      )
    end
  end
end
