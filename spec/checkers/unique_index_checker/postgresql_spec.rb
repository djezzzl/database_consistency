# frozen_string_literal: true

RSpec.describe DatabaseConsistency::Checkers::UniqueIndexChecker, :postgresql do
  subject(:checker) { described_class.new(model, index) }

  let(:model) { klass }
  let(:index) { ActiveRecord::Base.connection.indexes(klass.table_name).first }

  let(:index_name) { 'index_name' }

  context 'when unique partial index exists' do
    before do
      define_database_with_entity do |table|
        table.integer :account_id
        table.boolean :is_default
        table.index %i[account_id], unique: true, name: index_name, where: 'is_default = true'
      end
    end

    context 'when conditions validation is missing' do
      let(:klass) { define_class }

      specify do
        expect(checker.report).to have_attributes(
          checker_name: 'UniqueIndexChecker',
          table_or_model_name: klass.name,
          column_or_attribute_name: index_name,
          status: :fail,
          error_message: nil,
          error_slug: :missing_uniqueness_validation
        )
      end
    end

    context 'when conditions validation is present' do
      let(:klass) do
        define_class do |klass|
          klass.validates :account_id, uniqueness: { conditions: -> { where(is_default: true) } }
        end
      end

      specify do
        expect(checker.report).to have_attributes(
          checker_name: 'UniqueIndexChecker',
          table_or_model_name: klass.name,
          column_or_attribute_name: index_name,
          status: :ok,
          error_message: nil,
          error_slug: nil
        )
      end
    end
  end

  context 'when unique partial index uses shorthand boolean where clause' do
    before do
      define_database_with_entity do |table|
        table.integer :account_id
        table.boolean :is_default
        table.index %i[account_id], unique: true, name: index_name, where: 'is_default'
      end
    end

    context 'when conditions validation is present' do
      let(:klass) do
        define_class do |klass|
          klass.validates :account_id, uniqueness: { conditions: -> { where(is_default: true) } }
        end
      end

      specify do
        expect(checker.report).to have_attributes(
          checker_name: 'UniqueIndexChecker',
          table_or_model_name: klass.name,
          column_or_attribute_name: index_name,
          status: :ok,
          error_message: nil,
          error_slug: nil
        )
      end
    end
  end

  context 'when unique partial index uses casts and <> syntax' do
    before do
      define_database_with_entity do |table|
        table.string :internal_name
        table.index %i[internal_name], unique: true, name: index_name, where: "((internal_name)::text <> ''::text)"
      end
    end

    context 'when conditions validation is present' do
      let(:klass) do
        define_class do |klass|
          klass.validates :internal_name, uniqueness: { conditions: -> { where.not(internal_name: '') } }
        end
      end

      specify do
        expect(checker.report).to have_attributes(
          checker_name: 'UniqueIndexChecker',
          table_or_model_name: klass.name,
          column_or_attribute_name: index_name,
          status: :ok,
          error_message: nil,
          error_slug: nil
        )
      end
    end
  end

  context 'when unique partial index uses ANY (ARRAY[...]) syntax' do
    before do
      define_database_with_entity do |table|
        table.integer :approval_status
        table.index %i[approval_status], unique: true, name: index_name, where: '(approval_status = ANY (ARRAY[0, 1]))'
      end
    end

    context 'when conditions validation is present' do
      let(:klass) do
        define_class do |klass|
          klass.validates :approval_status, uniqueness: { conditions: -> { where(approval_status: [0, 1]) } }
        end
      end

      specify do
        expect(checker.report).to have_attributes(
          checker_name: 'UniqueIndexChecker',
          table_or_model_name: klass.name,
          column_or_attribute_name: index_name,
          status: :ok,
          error_message: nil,
          error_slug: nil
        )
      end
    end
  end

  context 'when unique partial index matches allow_nil validation' do
    before do
      define_database_with_entity do |table|
        table.string :reset_password_token
        table.index %i[reset_password_token], unique: true, name: index_name, where: 'reset_password_token IS NOT NULL'
      end
    end

    context 'when allow_nil validation is present' do
      let(:klass) do
        define_class do |klass|
          klass.validates :reset_password_token, uniqueness: true, allow_nil: true
        end
      end

      specify do
        expect(checker.report).to have_attributes(
          checker_name: 'UniqueIndexChecker',
          table_or_model_name: klass.name,
          column_or_attribute_name: index_name,
          status: :ok,
          error_message: nil,
          error_slug: nil
        )
      end
    end
  end

  context 'when full unique index is present for allow_nil validation' do
    before do
      define_database_with_entity do |table|
        table.string :reset_password_token
        table.index %i[reset_password_token], unique: true, name: index_name
      end
    end

    let(:klass) do
      define_class do |klass|
        klass.validates :reset_password_token, uniqueness: true, allow_nil: true
      end
    end

    specify do
      expect(checker.report).to have_attributes(
        checker_name: 'UniqueIndexChecker',
        table_or_model_name: klass.name,
        column_or_attribute_name: index_name,
        status: :ok,
        error_message: nil,
        error_slug: nil
      )
    end
  end

  context 'when unique partial index matches allow_blank validation' do
    before do
      define_database_with_entity do |table|
        table.string :external_id
        table.index(
          %i[external_id],
          unique: true,
          name: index_name,
          where: "((external_id)::text <> ''::text) AND (external_id IS NOT NULL)"
        )
      end
    end

    context 'when allow_blank validation is present' do
      let(:klass) do
        define_class do |klass|
          klass.validates :external_id, uniqueness: true, allow_blank: true
        end
      end

      specify do
        expect(checker.report).to have_attributes(
          checker_name: 'UniqueIndexChecker',
          table_or_model_name: klass.name,
          column_or_attribute_name: index_name,
          status: :ok,
          error_message: nil,
          error_slug: nil
        )
      end
    end
  end

  context 'when full unique index is present for allow_blank validation' do
    before do
      define_database_with_entity do |table|
        table.string :external_id
        table.index %i[external_id], unique: true, name: index_name
      end
    end

    let(:klass) do
      define_class do |klass|
        klass.validates :external_id, uniqueness: true, allow_blank: true
      end
    end

    specify do
      expect(checker.report).to have_attributes(
        checker_name: 'UniqueIndexChecker',
        table_or_model_name: klass.name,
        column_or_attribute_name: index_name,
        status: :ok,
        error_message: nil,
        error_slug: nil
      )
    end
  end
end
