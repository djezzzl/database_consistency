# frozen_string_literal: true

RSpec.describe DatabaseConsistency::Checkers::MissingUniqueIndexChecker, :sqlite do
  subject(:checker) { described_class.new(model, attribute, validator) }

  let(:model) { klass }
  let(:attribute) { :account_id }
  let(:validator) { klass.validators.first }

  context 'when uniqueness validation has conditions option' do
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
          table.index %i[account_id], unique: true, where: 'is_default = 1'
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
    context 'when partial unique index where clause does not match validator conditions' do
      before do
        define_database_with_entity do |table|
          table.integer :account_id
          table.boolean :is_default
          table.boolean :deleted
          table.index %i[account_id], unique: true, where: 'deleted = 0'
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
