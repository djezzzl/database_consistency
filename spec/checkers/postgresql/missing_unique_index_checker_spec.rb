# frozen_string_literal: true

RSpec.describe DatabaseConsistency::Checkers::MissingUniqueIndexChecker, :postgresql do
  before do
    if ActiveRecord::VERSION::MAJOR < 5
      skip('Uniqueness validation with "case sensitive: false" is supported only by ActiveRecord >= 5')
    end
  end

  subject(:checker) { described_class.new(model, attribute, validator) }

  let(:model) { klass }
  let(:attribute) { :email }
  let(:validator) { klass.validators.first }

  context 'when uniqueness validation has case sensitive option turned off' do
    let(:klass) { define_class { |klass| klass.validates :email, uniqueness: { case_sensitive: false } } }

    context 'when unique index is provided' do
      before do
        define_database_with_entity do |table|
          table.string :email
          table.index 'lower(email)', unique: true
        end
      end

      specify do
        expect(checker.report).to have_attributes(
          checker_name: 'MissingUniqueIndexChecker',
          table_or_model_name: klass.name,
          column_or_attribute_name: 'lower(email)',
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
          column_or_attribute_name: 'lower(email)',
          status: :fail,
          error_message: nil,
          error_slug: :missing_unique_index
        )
      end
    end

    context 'when uniqueness validation has scope' do
      let(:klass) do
        define_class { |klass| klass.validates :email, uniqueness: { case_sensitive: false, scope: :phone } }
      end

      context 'when unique index is provided' do
        before do
          define_database_with_entity do |table|
            table.string :email
            table.string :phone
            table.index "lower('email'), phone", unique: true
          end
        end

        specify do
          expect(checker.report).to have_attributes(
            checker_name: 'MissingUniqueIndexChecker',
            table_or_model_name: klass.name,
            column_or_attribute_name: 'lower(email)+phone',
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
            table.string :phone
          end
        end

        specify do
          expect(checker.report).to have_attributes(
            checker_name: 'MissingUniqueIndexChecker',
            table_or_model_name: klass.name,
            column_or_attribute_name: 'lower(email)+phone',
            status: :fail,
            error_message: nil,
            error_slug: :missing_unique_index
          )
        end
      end
    end
  end

  context 'when uniqueness validation has conditions option' do
    let(:attribute) { :account_id }
    let(:klass) do
      define_class do |klass|
        klass.validates :account_id, uniqueness: { scope: :is_default, conditions: -> { where(is_default: true) } }
      end
    end

    context 'when partial unique index is provided' do
      before do
        define_database_with_entity do |table|
          table.integer :account_id
          table.boolean :is_default
          table.index %i[account_id], unique: true, where: 'is_default = true'
        end
      end

      specify do
        expect(checker.report).to be_nil
      end
    end

    context 'when no index is provided' do
      before do
        define_database_with_entity do |table|
          table.integer :account_id
          table.boolean :is_default
        end
      end

      specify do
        expect(checker.report).to be_nil
      end
    end
  end
end
