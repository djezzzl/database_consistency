# frozen_string_literal: true

RSpec.describe DatabaseConsistency::Processors, :sqlite do
  let(:config) { DatabaseConsistency::Configuration.new }

  describe '.reports' do
    it 'returns reports from all processors' do
      expect(described_class.reports(config)).to be_an(Array)
    end
  end
end
