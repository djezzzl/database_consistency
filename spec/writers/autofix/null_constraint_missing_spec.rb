# frozen_string_literal: true

RSpec.describe DatabaseConsistency::Writers::Autofix::NullConstraintMissing, :sqlite, :mysql, :postgresql do
  let(:report) do
    double('report', table_name: 'users', column_name: 'email')
  end
  let(:writer) { described_class.new(report) }

  describe '#attributes' do
    subject(:attributes) { writer.attributes }

    it 'returns table_name and column_name from the report' do
      expect(attributes).to eq(table_name: 'users', column_name: 'email')
    end
  end

  describe '#fix!' do
    let(:file_path) { 'db/migrate/20230101000000_change_users_email_null_constraint.rb' }

    before do
      allow(writer).to receive(:migration_path).with('change_users_email_null_constraint').and_return(file_path)
      allow(writer).to receive(:migration_path_pattern).with('change_users_email_null_constraint').and_return(
        'db/migrate/*_change_users_email_null_constraint.rb'
      )
    end

    context 'when migration does not exist' do
      before do
        allow(Dir).to receive(:[]).with('db/migrate/*_change_users_email_null_constraint.rb').and_return([])
        allow(File).to receive(:write)
      end

      it 'writes the migration file' do
        writer.fix!
        expect(File).to have_received(:write).with(file_path, include('change_column_null :users, :email, false'))
      end

      it 'includes a migration class in the generated content' do
        writer.fix!
        expect(File).to have_received(:write).with(file_path, match(/class \w+ < ActiveRecord::Migration/))
      end
    end

    context 'when migration already exists' do
      before do
        allow(Dir).to receive(:[]).with('db/migrate/*_change_users_email_null_constraint.rb').and_return(
          ['db/migrate/20230101000000_change_users_email_null_constraint.rb']
        )
      end

      it 'does not write a file' do
        expect(File).not_to receive(:write)
        expect { writer.fix! }.to output(/Skipping migration/).to_stdout
      end
    end
  end
end
