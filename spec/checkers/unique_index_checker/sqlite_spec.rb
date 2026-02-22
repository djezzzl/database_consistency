# frozen_string_literal: true

RSpec.describe DatabaseConsistency::Checkers::UniqueIndexChecker, :sqlite do
  subject(:checker) { described_class.new(model, index) }

  let(:model) { klass }
  let(:index) { ActiveRecord::Base.connection.indexes(klass.table_name).first }

  let(:index_name) { 'index_name' }

  context 'when unique partial index exists' do
    before do
      define_database_with_entity do |table|
        table.integer :account_id
        table.boolean :is_default
        table.index %i[account_id], unique: true, name: index_name, where: 'is_default = 1'
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

  context 'when partial index where clause does not match conditions validation' do
    before do
      define_database_with_entity do |table|
        table.integer :account_id
        table.boolean :is_default
        table.boolean :deleted
        table.index %i[account_id], unique: true, name: index_name, where: 'deleted = 0'
      end
    end

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
        status: :fail,
        error_message: nil,
        error_slug: :missing_uniqueness_validation
      )
    end
  end
end
