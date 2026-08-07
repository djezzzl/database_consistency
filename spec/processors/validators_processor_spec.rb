# frozen_string_literal: true

RSpec.describe DatabaseConsistency::Processors::ValidatorsProcessor, :sqlite do
  subject(:processor) { described_class.new(config) }

  let(:config) { DatabaseConsistency::Configuration.new }
  let(:entity_class) do
    define_database_with_entity { |table| table.string :email, null: false }
    define_class('Entity', :entities) { |klass| klass.validates :email, presence: true }
  end

  before do
    allow(DatabaseConsistency::Helper).to receive(:parent_models).and_return([entity_class])
  end

  describe '#reports' do
    it 'returns an array of reports' do
      expect(processor.reports).to be_an(Array)
    end

    it 'processes validators' do
      expect(processor.reports).not_to be_nil
    end
  end
end
