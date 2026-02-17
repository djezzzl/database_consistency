# frozen_string_literal: true

RSpec.describe DatabaseConsistency::Checkers::MissingUniqueIndexChecker, :sqlite, :mysql, :postgresql do
  subject(:checker) { described_class.new(model, attribute, validator) }

  let(:model) { klass }
  let(:attribute) { :email }
  let(:validator) { klass.validators.first }

  context 'when uniqueness validation has no scope' do
    let(:klass) { define_class { |klass| klass.validates :email, uniqueness: true } }

    context 'when unique index is provided' do
      before do
        define_database_with_entity do |table|
          table.string :email
          table.index :email, unique: true
        end
      end

      specify do
        expect(checker.report).to have_attributes(
          checker_name: 'MissingUniqueIndexChecker',
          table_or_model_name: klass.name,
          column_or_attribute_name: 'email',
          status: :ok,
          error_message: nil,
          error_slug: nil
        )
      end
    end

    context 'when unique index is missing' do
      before do
        define_database_with_entity do |table|
          table.string :email
        end
      end

      specify do
        expect(checker.report).to have_attributes(
          checker_name: 'MissingUniqueIndexChecker',
          table_or_model_name: klass.name,
          column_or_attribute_name: 'email',
          status: :fail,
          error_message: nil,
          error_slug: :missing_unique_index
        )
      end
    end
  end

  context 'when uniqueness validation has a scope' do
    let(:klass) { define_class { |klass| klass.validates :email, uniqueness: { scope: :country } } }

    context 'when unique index is provided' do
      before do
        define_database_with_entity do |table|
          table.string :email
          table.string :country
          table.index %i[country email], unique: true
        end
      end

      specify do
        expect(checker.report).to have_attributes(
          checker_name: 'MissingUniqueIndexChecker',
          table_or_model_name: klass.name,
          column_or_attribute_name: 'email+country',
          status: :ok,
          error_message: nil,
          error_slug: nil
        )
      end
    end

    context 'when scope contains relation instead column' do
      before do
        define_database_with_entity do |table|
          table.string :email
          table.integer :country_id
          table.index %i[country_id email], unique: true
        end
      end

      let(:klass) do
        define_class do |klass|
          klass.validates :email, uniqueness: { scope: :country }
          klass.belongs_to :country
        end
      end

      specify do
        expect(checker.report).to have_attributes(
          checker_name: 'MissingUniqueIndexChecker',
          table_or_model_name: klass.name,
          column_or_attribute_name: 'email+country_id',
          status: :ok,
          error_message: nil,
          error_slug: nil
        )
      end
    end

    context 'when unique index is missing' do
      before do
        define_database_with_entity do |table|
          table.string :email
          table.string :country
          table.index %i[email country]
        end
      end

      specify do
        expect(checker.report).to have_attributes(
          checker_name: 'MissingUniqueIndexChecker',
          table_or_model_name: klass.name,
          column_or_attribute_name: 'email+country',
          status: :fail,
          error_message: nil,
          error_slug: :missing_unique_index
        )
      end
    end
  end

  context 'when single column primary key matches uniqueness validation' do
    let(:attribute) { :id }
    let(:klass) do
      define_class do |klass|
        klass.validates :id, uniqueness: true
      end
    end
    let(:validator) { klass.validators.first }

    before do
      # Create table with standard id primary key
      define_database do
        create_table :entities
      end
    end

    specify do
      expect(checker.report).to have_attributes(
        checker_name: 'MissingUniqueIndexChecker',
        table_or_model_name: klass.name,
        column_or_attribute_name: 'id',
        status: :ok,
        error_message: nil,
        error_slug: nil
      )
    end
  end

  context 'when model has primary_key set but database does not' do
    let(:klass) do
      define_class do |klass|
        klass.validates :email, uniqueness: true
      end
    end

    before do
      # Create table without setting email as primary key in database
      define_database_with_entity do |table|
        table.string :email, null: false
        table.string :name
      end

      # Only set primary key at model level, not in database
      klass.primary_key = :email
    end

    specify do
      # Should fail because database doesn't have email as primary key
      # even though model.primary_key is set
      expect(checker.report).to have_attributes(
        checker_name: 'MissingUniqueIndexChecker',
        table_or_model_name: klass.name,
        column_or_attribute_name: 'email',
        status: :fail,
        error_message: nil,
        error_slug: :missing_unique_index
      )
    end
  end

  context 'with compound primary key' do
    before do
      skip('Composite primary keys are supported only in Rails 7.1+') unless compound_primary_keys_supported?
    end

    context 'when table has a compound primary key that matches uniqueness validation' do
      let(:klass) do
        define_class do |klass|
          klass.primary_key = %i[email country_id]
          klass.validates :email, uniqueness: { scope: :country_id }
        end
      end

      before do
        define_database_with_entity do |table|
          table.string :email
          table.integer :country_id
          table.primary_key %i[email country_id]
        end
      end

      specify do
        expect(checker.report).to have_attributes(
          checker_name: 'MissingUniqueIndexChecker',
          table_or_model_name: klass.name,
          column_or_attribute_name: 'email+country_id',
          status: :ok,
          error_message: nil,
          error_slug: nil
        )
      end
    end

    context 'when table has an implicit compound primary key that matches uniqueness validation' do
      let(:klass) do
        define_class do |klass|
          klass.validates :email, uniqueness: { scope: :country_id }
        end
      end

      before do
        define_database_with_entity do |table|
          table.string :email
          table.integer :country_id
          table.primary_key %i[email country_id]
        end
      end

      specify do
        expect(checker.report).to have_attributes(
          checker_name: 'MissingUniqueIndexChecker',
          table_or_model_name: klass.name,
          column_or_attribute_name: 'email+country_id',
          status: :ok,
          error_message: nil,
          error_slug: nil
        )
      end
    end

    context 'when table has a compound primary key (single column validation)' do
      let(:klass) do
        define_class do |klass|
          klass.primary_key = %i[email id]
          klass.validates :email, uniqueness: true
        end
      end

      before do
        define_database_with_entity do |table|
          table.string :email
          table.integer :id
          table.primary_key %i[email id]
        end
      end

      specify do
        expect(checker.report).to have_attributes(
          checker_name: 'MissingUniqueIndexChecker',
          table_or_model_name: klass.name,
          column_or_attribute_name: 'email',
          status: :fail,
          error_message: nil,
          error_slug: :missing_unique_index
        )
      end
    end
  end
end
