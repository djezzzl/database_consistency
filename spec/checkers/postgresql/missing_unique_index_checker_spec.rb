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
        klass.validates :account_id, uniqueness: { conditions: -> { where(is_default: true) } }
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
        expect(checker.report).to have_attributes(
          checker_name: 'MissingUniqueIndexChecker',
          table_or_model_name: klass.name,
          column_or_attribute_name: 'account_id',
          status: :ok,
          error_message: nil,
          error_slug: nil
        )
      end
    end

    context 'when index has different where scope' do
      before do
        define_database_with_entity do |table|
          table.integer :account_id
          table.boolean :is_default
          table.boolean :deleted
          table.index %i[account_id], unique: true, where: 'deleted = false'
        end
      end

      specify do
        expect(checker.report).to have_attributes(
          checker_name: 'MissingUniqueIndexChecker',
          table_or_model_name: klass.name,
          column_or_attribute_name: 'account_id',
          status: :fail,
          error_message: nil,
          error_slug: :missing_unique_index
        )
      end
    end

    context 'when partial unique index uses shorthand boolean where clause' do
      before do
        define_database_with_entity do |table|
          table.integer :account_id
          table.boolean :is_default
          table.index %i[account_id], unique: true, where: 'is_default'
        end
      end

      specify do
        expect(checker.report).to have_attributes(
          checker_name: 'MissingUniqueIndexChecker',
          table_or_model_name: klass.name,
          column_or_attribute_name: 'account_id',
          status: :ok,
          error_message: nil,
          error_slug: nil
        )
      end
    end

    context 'when partial unique index uses casts and <> syntax' do
      let(:attribute) { :internal_name }
      let(:klass) do
        define_class do |klass|
          klass.validates :internal_name, uniqueness: { conditions: -> { where.not(internal_name: '') } }
        end
      end

      before do
        define_database_with_entity do |table|
          table.string :internal_name
          table.index %i[internal_name], unique: true, where: "((internal_name)::text <> ''::text)"
        end
      end

      specify do
        expect(checker.report).to have_attributes(
          checker_name: 'MissingUniqueIndexChecker',
          table_or_model_name: klass.name,
          column_or_attribute_name: 'internal_name',
          status: :ok,
          error_message: nil,
          error_slug: nil
        )
      end
    end

    context 'when partial unique index uses ANY (ARRAY[...]) syntax' do
      let(:attribute) { :approval_status }
      let(:klass) do
        define_class do |klass|
          klass.validates :approval_status, uniqueness: { conditions: -> { where(approval_status: [0, 1]) } }
        end
      end

      before do
        define_database_with_entity do |table|
          table.integer :approval_status
          table.index %i[approval_status], unique: true, where: '(approval_status = ANY (ARRAY[0, 1]))'
        end
      end

      specify do
        expect(checker.report).to have_attributes(
          checker_name: 'MissingUniqueIndexChecker',
          table_or_model_name: klass.name,
          column_or_attribute_name: 'approval_status',
          status: :ok,
          error_message: nil,
          error_slug: nil
        )
      end
    end
  end

  context 'when uniqueness validation uses allow_nil' do
    let(:attribute) { :reset_password_token }
    let(:klass) do
      define_class do |klass|
        klass.validates :reset_password_token, uniqueness: true, allow_nil: true
      end
    end

    before do
      define_database_with_entity do |table|
        table.string :reset_password_token
        table.index %i[reset_password_token], unique: true, where: 'reset_password_token IS NOT NULL'
      end
    end

    specify do
      expect(checker.report).to have_attributes(
        checker_name: 'MissingUniqueIndexChecker',
        table_or_model_name: klass.name,
        column_or_attribute_name: 'reset_password_token',
        status: :ok,
        error_message: nil,
        error_slug: nil
      )
    end
  end

  context 'when uniqueness validation uses allow_nil and full unique index is provided' do
    let(:attribute) { :reset_password_token }
    let(:klass) do
      define_class do |klass|
        klass.validates :reset_password_token, uniqueness: true, allow_nil: true
      end
    end

    before do
      define_database_with_entity do |table|
        table.string :reset_password_token
        table.index %i[reset_password_token], unique: true
      end
    end

    specify do
      expect(checker.report).to have_attributes(
        checker_name: 'MissingUniqueIndexChecker',
        table_or_model_name: klass.name,
        column_or_attribute_name: 'reset_password_token',
        status: :ok,
        error_message: nil,
        error_slug: nil
      )
    end
  end

  context 'when uniqueness validation uses allow_blank' do
    let(:attribute) { :external_id }
    let(:klass) do
      define_class do |klass|
        klass.validates :external_id, uniqueness: true, allow_blank: true
      end
    end

    before do
      define_database_with_entity do |table|
        table.string :external_id
        table.index(
          %i[external_id],
          unique: true,
          where: "((external_id)::text <> ''::text) AND (external_id IS NOT NULL)"
        )
      end
    end

    specify do
      expect(checker.report).to have_attributes(
        checker_name: 'MissingUniqueIndexChecker',
        table_or_model_name: klass.name,
        column_or_attribute_name: 'external_id',
        status: :ok,
        error_message: nil,
        error_slug: nil
      )
    end
  end

  context 'when uniqueness validation uses allow_blank and full unique index is provided' do
    let(:attribute) { :external_id }
    let(:klass) do
      define_class do |klass|
        klass.validates :external_id, uniqueness: true, allow_blank: true
      end
    end

    before do
      define_database_with_entity do |table|
        table.string :external_id
        table.index %i[external_id], unique: true
      end
    end

    specify do
      expect(checker.report).to have_attributes(
        checker_name: 'MissingUniqueIndexChecker',
        table_or_model_name: klass.name,
        column_or_attribute_name: 'external_id',
        status: :ok,
        error_message: nil,
        error_slug: nil
      )
    end
  end

  context 'when uniqueness validation has different conditions scope' do
    let(:attribute) { :account_id }
    let(:klass) do
      define_class do |klass|
        klass.validates :account_id, uniqueness: { conditions: -> { where(deleted: false) } }
      end
    end

    context 'when partial unique index with different where clause is provided' do
      before do
        define_database_with_entity do |table|
          table.integer :account_id
          table.boolean :is_default
          table.boolean :deleted
          table.index %i[account_id], unique: true, where: 'is_default = true'
        end
      end

      specify do
        expect(checker.report).to have_attributes(
          checker_name: 'MissingUniqueIndexChecker',
          table_or_model_name: klass.name,
          column_or_attribute_name: 'account_id',
          status: :fail,
          error_message: nil,
          error_slug: :missing_unique_index
        )
      end
    end
  end
end
