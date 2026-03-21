# frozen_string_literal: true

RSpec.describe DatabaseConsistency::Writers::Autofix::AssociationMissingIndex, :sqlite, :mysql, :postgresql do
  describe '#attributes' do
    subject(:attributes) { writer.attributes }

    context 'with a single column' do
      let(:report) do
        double('report', table_name: 'posts', columns: ['user_id'])
      end
      let(:writer) { described_class.new(report) }

      it 'formats the column as a symbol' do
        expect(attributes).to include(table_name: 'posts', columns: ':user_id')
      end

      it 'generates the correct index name' do
        expect(attributes).to include(index_name: 'index_posts_user_id')
      end
    end

    context 'with multiple columns' do
      let(:report) do
        double('report', table_name: 'posts', columns: ['user_id', 'type'])
      end
      let(:writer) { described_class.new(report) }

      it 'formats the columns as a %w array' do
        expect(attributes).to include(columns: '%w[user_id type]')
      end

      it 'generates the correct index name' do
        expect(attributes).to include(index_name: 'index_posts_user_id_type')
      end
    end

    context 'with a column containing parentheses' do
      let(:report) do
        double('report', table_name: 'posts', columns: ['lower(email)'])
      end
      let(:writer) { described_class.new(report) }

      it 'formats the column as a quoted string' do
        expect(attributes).to include(columns: "'lower(email)'")
      end
    end
  end

  describe '#fix!' do
    let(:report) do
      double('report', table_name: 'posts', columns: ['user_id'])
    end
    let(:writer) { described_class.new(report) }
    let(:file_path) { 'db/migrate/20230101000000_add_posts_user_id_index.rb' }

    before do
      allow(writer).to receive(:migration_path).with('add_posts_user_id_index').and_return(file_path)
      allow(writer).to receive(:migration_path_pattern).with('add_posts_user_id_index').and_return(
        'db/migrate/*_add_posts_user_id_index.rb'
      )
    end

    context 'when migration does not exist' do
      before do
        allow(Dir).to receive(:[]).with('db/migrate/*_add_posts_user_id_index.rb').and_return([])
        allow(File).to receive(:write)
      end

      it 'writes the migration file' do
        writer.fix!
        expect(File).to have_received(:write).with(
          file_path, include('add_index :posts, :user_id, name: :index_posts_user_id')
        )
      end
    end

    context 'when migration already exists' do
      before do
        allow(Dir).to receive(:[]).with('db/migrate/*_add_posts_user_id_index.rb').and_return(
          ['db/migrate/20230101000000_add_posts_user_id_index.rb']
        )
      end

      it 'does not write a file' do
        expect(File).not_to receive(:write)
        expect { writer.fix! }.to output(/Skipping migration/).to_stdout
      end
    end
  end
end
