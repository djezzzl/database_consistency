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

    let(:klass) { define_class }

    specify do
      expect(checker.report).to be_nil
    end
  end
end
