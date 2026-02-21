# frozen_string_literal: true

RSpec.describe DatabaseConsistency::Checkers::UniqueIndexChecker, :postgresql do
  subject(:checker) { described_class.new(model, index) }

  let(:model) { klass }
  let(:index) { ActiveRecord::Base.connection.indexes(klass.table_name).first }

  let(:checker_name) { described_class.name.demodulize }
  let(:index_name) { 'index_name' }

  context 'when unique partial index exists' do
    before do
      define_database_with_entity do |table|
        table.integer :account_id
        table.boolean :is_default
        table.index %i[account_id], unique: true, name: index_name, where: 'is_default = true'
      end
    end

    context 'when validation with conditions is present' do
      let(:klass) do
        define_class do |klass|
          klass.validates :account_id, uniqueness: { scope: :is_default, conditions: -> { where(is_default: true) } }
        end
      end

      specify do
        expect(checker.report).to be_nil
      end
    end

    context 'when validation is missing' do
      let(:klass) { define_class }

      specify do
        expect(checker.report).to be_nil
      end
    end
  end
end
