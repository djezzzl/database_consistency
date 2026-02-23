# frozen_string_literal: true

RSpec.describe DatabaseConsistency::Checkers::ViewPrimaryKeyChecker, :sqlite, :mysql, :postgresql do
  subject(:checker) { described_class.new(model) }

  let(:model) { view_klass }
  let(:view_klass) { define_class('EntityView', :entity_views) }

  context 'when table is not a view' do
    let(:model) { define_class }

    before do
      define_database do
        create_table :entities
      end
    end

    specify do
      expect(checker.report).to be_nil
    end
  end

  context 'when model is abstract' do
    let(:model) { define_class { |klass| klass.abstract_class = true } }

    before do
      define_database do
        create_table :entities
      end
    end

    specify do
      expect(checker.report).to be_nil
    end
  end

  context 'when table is a view' do
    before do
      skip('view_exists? not supported before ActiveRecord 5') if ActiveRecord::VERSION::MAJOR < 5

      define_database do
        create_table :entities do |t|
          t.string :name
        end
      end

      model.connection.execute(<<~SQL)
        DROP VIEW IF EXISTS #{view_klass.table_name};
      SQL
      model.connection.execute(<<~SQL)
        CREATE VIEW #{view_klass.table_name} AS SELECT * FROM entities;
      SQL
    end

    context 'without primary_key set' do
      specify do
        expect(checker.report).to have_attributes(
          checker_name: 'ViewPrimaryKeyChecker',
          table_or_model_name: view_klass.name,
          column_or_attribute_name: 'self',
          status: :fail,
          error_slug: :view_missing_primary_key,
          error_message: nil
        )
      end
    end

    context 'with primary_key set to a non-existent column' do
      let(:view_klass) do
        define_class('EntityView', :entity_views) do |klass|
          klass.primary_key = :nonexistent
        end
      end

      specify do
        expect(checker.report).to have_attributes(
          checker_name: 'ViewPrimaryKeyChecker',
          table_or_model_name: view_klass.name,
          column_or_attribute_name: 'self',
          status: :fail,
          error_slug: :view_primary_key_column_missing,
          error_message: nil
        )
      end
    end

    context 'with primary_key set to an existing column' do
      let(:view_klass) do
        define_class('EntityView', :entity_views) do |klass|
          klass.primary_key = :id
        end
      end

      specify do
        expect(checker.report).to have_attributes(
          checker_name: 'ViewPrimaryKeyChecker',
          table_or_model_name: view_klass.name,
          column_or_attribute_name: 'self',
          status: :ok,
          error_slug: nil,
          error_message: nil
        )
      end
    end

    context 'with composite primary_key set to existing columns' do
      let(:view_klass) do
        define_class('EntityView', :entity_views) do |klass|
          klass.primary_key = %i[id name]
        end
      end

      before do
        skip('Composite primary keys are supported only in Rails 7.1+') unless compound_primary_keys_supported?
      end

      specify do
        expect(checker.report).to have_attributes(
          checker_name: 'ViewPrimaryKeyChecker',
          table_or_model_name: view_klass.name,
          column_or_attribute_name: 'self',
          status: :ok,
          error_slug: nil,
          error_message: nil
        )
      end
    end

    context 'with composite primary_key where one column is missing' do
      let(:view_klass) do
        define_class('EntityView', :entity_views) do |klass|
          klass.primary_key = %i[id nonexistent]
        end
      end

      before do
        skip('Composite primary keys are supported only in Rails 7.1+') unless compound_primary_keys_supported?
      end

      specify do
        expect(checker.report).to have_attributes(
          checker_name: 'ViewPrimaryKeyChecker',
          table_or_model_name: view_klass.name,
          column_or_attribute_name: 'self',
          status: :fail,
          error_slug: :view_primary_key_column_missing,
          error_message: nil
        )
      end
    end
  end
end
