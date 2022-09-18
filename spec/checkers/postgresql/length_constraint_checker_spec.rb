# frozen_string_literal: true

RSpec.describe DatabaseConsistency::Checkers::LengthConstraintChecker, :postgresql do
  subject(:checker) { described_class.new(model, column) }

  let(:model) { klass }
  let(:column) { klass.columns.first }

  before do
    define_database_with_entity { |table| table.string :email, limit: 256, array: true }
  end

  let(:klass) { define_class }

  specify do
    expect(checker.report).to be_nil
  end
end
