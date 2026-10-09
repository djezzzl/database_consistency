# frozen_string_literal: true

RSpec.describe DatabaseConsistency::Processors::IndexesProcessor, :sqlite do
  subject(:processor) { described_class.new(config) }

  let(:config) { DatabaseConsistency::Configuration.new }
  let(:entity_class) do
    define_database do
      create_table :entities do |t|
        t.string :email
        t.index :email
      end
    end
    define_class('Entity', :entities)
  end

  before do
    allow(DatabaseConsistency::Helper).to receive(:parent_models).and_return([entity_class])
  end

  describe '#reports' do
    it 'returns an array of reports' do
      expect(processor.reports).to be_an(Array)
    end

    it 'processes indexes' do
      expect(processor.reports).not_to be_nil
    end
  end
end
