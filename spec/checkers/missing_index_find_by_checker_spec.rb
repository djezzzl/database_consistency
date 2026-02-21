# frozen_string_literal: true

RSpec.describe DatabaseConsistency::Checkers::MissingIndexFindByChecker, :sqlite, :mysql, :postgresql do
  subject(:checker) { described_class.new(model, column) }

  let(:model) { klass }
  let(:klass) { define_class }
  let(:column) { klass.columns.find { |c| c.name == 'email' } }

  before do
    define_database_with_entity do |t|
      t.string :email
    end
  end

  context 'when the model source file cannot be found' do
    before do
      allow(Module).to receive(:const_source_location).and_return([nil, nil])
    end

    it 'skips the check' do
      expect(checker.report).to be_nil
    end
  end

  context 'when const_source_location is not available' do
    before do
      allow(Module).to receive(:respond_to?).with(:const_source_location).and_return(false)
      allow(Module).to receive(:respond_to?).with(anything).and_call_original
    end

    it 'skips the check' do
      expect(checker.report).to be_nil
    end
  end

  context 'when column is not referenced in any find_by call in the model source' do
    let(:source_file) do
      Tempfile.new(['model', '.rb']).tap do |f|
        f.write("class Entity < ApplicationRecord\nend")
        f.flush
        f.close
      end
    end

    before do
      allow(Module).to receive(:const_source_location).and_return([source_file.path, 1])
    end

    after { source_file.unlink }

    it 'skips the check' do
      expect(checker.report).to be_nil
    end
  end

  context 'when column is used via dynamic finder (find_by_column_name)' do
    let(:source_file) do
      Tempfile.new(['model', '.rb']).tap do |f|
        f.write("class Entity < ApplicationRecord\n  find_by_email(params[:email])\nend")
        f.flush
        f.close
      end
    end

    before do
      allow(Module).to receive(:const_source_location).and_return([source_file.path, 1])
    end

    after { source_file.unlink }

    context 'when index is missing' do
      specify do
        expect(checker.report).to have_attributes(
          checker_name: 'MissingIndexFindByChecker',
          table_or_model_name: klass.name,
          column_or_attribute_name: 'email',
          status: :fail,
          error_slug: :missing_index_find_by,
          error_message: nil
        )
      end
    end

    context 'when index is present' do
      before do
        define_database_with_entity do |t|
          t.string :email, index: true
        end
      end

      specify do
        expect(checker.report).to have_attributes(
          checker_name: 'MissingIndexFindByChecker',
          table_or_model_name: klass.name,
          column_or_attribute_name: 'email',
          status: :ok,
          error_slug: nil,
          error_message: nil
        )
      end
    end
  end

  context 'when column is used via hash-style finder (find_by(column: ...))' do
    let(:source_file) do
      Tempfile.new(['model', '.rb']).tap do |f|
        f.write("class Entity < ApplicationRecord\n  find_by(email: params[:email])\nend")
        f.flush
        f.close
      end
    end

    before do
      allow(Module).to receive(:const_source_location).and_return([source_file.path, 1])
    end

    after { source_file.unlink }

    context 'when index is missing' do
      specify do
        expect(checker.report).to have_attributes(
          checker_name: 'MissingIndexFindByChecker',
          table_or_model_name: klass.name,
          column_or_attribute_name: 'email',
          status: :fail,
          error_slug: :missing_index_find_by,
          error_message: nil
        )
      end
    end
  end

  context 'when column is used via string-key finder (find_by("column" => ...))' do
    let(:source_file) do
      Tempfile.new(['model', '.rb']).tap do |f|
        f.write("class Entity < ApplicationRecord\n  find_by(\"email\" => params[:email])\nend")
        f.flush
        f.close
      end
    end

    before do
      allow(Module).to receive(:const_source_location).and_return([source_file.path, 1])
    end

    after { source_file.unlink }

    context 'when index is missing' do
      specify do
        expect(checker.report).to have_attributes(
          checker_name: 'MissingIndexFindByChecker',
          table_or_model_name: klass.name,
          column_or_attribute_name: 'email',
          status: :fail,
          error_slug: :missing_index_find_by,
          error_message: nil
        )
      end
    end
  end

  context 'when column is the primary key' do
    let(:column) { klass.columns.find { |c| c.name == klass.primary_key } }

    let(:source_file) do
      Tempfile.new(['model', '.rb']).tap do |f|
        f.write("class Entity < ApplicationRecord\n  find_by_id(params[:id])\nend")
        f.flush
        f.close
      end
    end

    before do
      define_database do
        create_table :entities do |t|
          t.string :email
        end
      end

      allow(Module).to receive(:const_source_location).and_return([source_file.path, 1])
    end

    after { source_file.unlink }

    it 'skips the check' do
      expect(checker.report).to be_nil
    end
  end
end
