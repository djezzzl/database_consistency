# frozen_string_literal: true

require 'tempfile'

RSpec.describe DatabaseConsistency::Checkers::MissingIndexFindByChecker, :sqlite, :mysql, :postgresql do
  subject(:checker) { described_class.new(model, column) }

  let(:model) { klass }
  let(:klass) { define_class }
  let(:column) { klass.columns.find { |c| c.name == 'email' } }

  context 'when Prism is not available' do
    before do
      define_database_with_entity do |t|
        t.string :email
      end
      hide_const('Prism')
    end

    it 'skips the check' do
      expect(checker.report).to be_nil
    end
  end

  context 'when no project source files are found' do
    before do
      define_database_with_entity do |t|
        t.string :email
      end
      allow(ObjectSpace).to receive(:each_object).with(Module)
    end

    it 'skips the check' do
      expect(checker.report).to be_nil
    end
  end

  context 'when const_source_location is not available' do
    before do
      define_database_with_entity do |t|
        t.string :email
      end
      allow(Module).to receive(:respond_to?).with(:const_source_location).and_return(false)
      allow(Module).to receive(:respond_to?).with(anything).and_call_original
    end

    it 'skips the check' do
      expect(checker.report).to be_nil
    end
  end

  context 'when column is not referenced in any find_by call in the model source' do
    before do
      skip 'Prism not available (Ruby < 3.3)' unless defined?(Prism)
      define_database_with_entity do |t|
        t.string :email
      end
    end

    it 'skips the check' do
      Tempfile.create(['model', '.rb']) do |f|
        f.write("class Entity < ApplicationRecord\nend")
        f.flush
        allow(ObjectSpace).to receive(:each_object).with(Module).and_yield(klass)
        allow(Module).to receive(:const_source_location).with(klass.name).and_return([f.path, 1])
        expect(checker.report).to be_nil
      end
    end
  end

  context 'when column is used via dynamic finder (find_by_column_name)' do
    context 'when index is missing' do
      before do
        skip 'Prism not available (Ruby < 3.3)' unless defined?(Prism)
        define_database_with_entity do |t|
          t.string :email
        end
      end

      specify do
        Tempfile.create(['model', '.rb']) do |f|
          f.write("class Entity < ApplicationRecord\n  find_by_email(params[:email])\nend")
          f.flush
          allow(ObjectSpace).to receive(:each_object).with(Module).and_yield(klass)
          allow(Module).to receive(:const_source_location).with(klass.name).and_return([f.path, 1])
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

    context 'when index is present' do
      before do
        skip 'Prism not available (Ruby < 3.3)' unless defined?(Prism)
        define_database_with_entity do |t|
          t.string :email, index: true
        end
      end

      specify do
        Tempfile.create(['model', '.rb']) do |f|
          f.write("class Entity < ApplicationRecord\n  find_by_email(params[:email])\nend")
          f.flush
          allow(ObjectSpace).to receive(:each_object).with(Module).and_yield(klass)
          allow(Module).to receive(:const_source_location).with(klass.name).and_return([f.path, 1])
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
  end

  context 'when column is used via bang dynamic finder (find_by_column_name!)' do
    context 'when index is missing' do
      before do
        skip 'Prism not available (Ruby < 3.3)' unless defined?(Prism)
        define_database_with_entity do |t|
          t.string :email
        end
      end

      specify do
        Tempfile.create(['model', '.rb']) do |f|
          f.write("class Entity < ApplicationRecord\n  Entity.find_by_email!(params[:email])\nend")
          f.flush
          allow(ObjectSpace).to receive(:each_object).with(Module).and_yield(klass)
          allow(Module).to receive(:const_source_location).with(klass.name).and_return([f.path, 1])
          expect(checker.report).to have_attributes(
            checker_name: 'MissingIndexFindByChecker',
            column_or_attribute_name: 'email',
            status: :fail,
            error_slug: :missing_index_find_by
          )
        end
      end
    end
  end

  context 'when column is used via hash-style finder (find_by(column: ...))' do
    context 'when index is missing' do
      before do
        skip 'Prism not available (Ruby < 3.3)' unless defined?(Prism)
        define_database_with_entity do |t|
          t.string :email
        end
      end

      specify do
        Tempfile.create(['model', '.rb']) do |f|
          f.write("class Entity < ApplicationRecord\n  find_by(email: params[:email])\nend")
          f.flush
          allow(ObjectSpace).to receive(:each_object).with(Module).and_yield(klass)
          allow(Module).to receive(:const_source_location).with(klass.name).and_return([f.path, 1])
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
  end

  context 'when column is used via no-parens finder (find_by column: ...)' do
    context 'when index is missing' do
      before do
        skip 'Prism not available (Ruby < 3.3)' unless defined?(Prism)
        define_database_with_entity do |t|
          t.string :email
        end
      end

      specify do
        Tempfile.create(['model', '.rb']) do |f|
          f.write("class Entity < ApplicationRecord\n  Entity.find_by email: params[:email]\nend")
          f.flush
          allow(ObjectSpace).to receive(:each_object).with(Module).and_yield(klass)
          allow(Module).to receive(:const_source_location).with(klass.name).and_return([f.path, 1])
          expect(checker.report).to have_attributes(
            checker_name: 'MissingIndexFindByChecker',
            column_or_attribute_name: 'email',
            status: :fail,
            error_slug: :missing_index_find_by
          )
        end
      end
    end
  end

  context 'when column is used via string-key finder (find_by("column" => ...))' do
    context 'when index is missing' do
      before do
        skip 'Prism not available (Ruby < 3.3)' unless defined?(Prism)
        define_database_with_entity do |t|
          t.string :email
        end
      end

      specify do
        Tempfile.create(['model', '.rb']) do |f|
          f.write("class Entity < ApplicationRecord\n  find_by(\"email\" => params[:email])\nend")
          f.flush
          allow(ObjectSpace).to receive(:each_object).with(Module).and_yield(klass)
          allow(Module).to receive(:const_source_location).with(klass.name).and_return([f.path, 1])
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
  end

  context 'when column is the primary key' do
    let(:klass) { define_class { |k| k.primary_key = 'email' } }
    let(:column) { klass.columns.find { |c| c.name == 'email' } }

    before do
      skip 'Prism not available (Ruby < 3.3)' unless defined?(Prism)
      define_database_with_entity do |t|
        t.string :email
      end
    end

    it 'skips the check' do
      Tempfile.create(['model', '.rb']) do |f|
        f.write("class Entity < ApplicationRecord\n  find_by_email(params[:email])\nend")
        f.flush
        allow(ObjectSpace).to receive(:each_object).with(Module).and_yield(klass)
        allow(Module).to receive(:const_source_location).with(klass.name).and_return([f.path, 1])
        expect(checker.report).to be_nil
      end
    end
  end
end
