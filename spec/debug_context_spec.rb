# frozen_string_literal: true

RSpec.describe DatabaseConsistency::DebugContext, :sqlite, :mysql, :postgresql do
  subject(:context) { described_class.instance }

  before do
    # Reset singleton state between tests
    context.send(:clear!)
  end

  describe '.with' do
    it 'sets context values and restores them after the block' do
      outer_result = nil

      described_class.with(model: 'User') do
        outer_result = context.send(:store).dup
      end

      expect(outer_result).to include(model: 'User')
      expect(context.send(:store)).not_to include(:model)
    end

    it 'returns the result of the block' do
      result = described_class.with(checker: 'NullConstraintChecker') { 42 }
      expect(result).to eq(42)
    end
  end

  describe '.output' do
    it 'writes context entries to the destination' do
      described_class.with(model: 'User', checker: 'NullConstraintChecker') do
        output = StringIO.new
        described_class.output(output)
        expect(output.string).to include('model: User')
        expect(output.string).to include('checker: NullConstraintChecker')
      end
    end

    it 'writes nothing when context is empty' do
      output = StringIO.new
      described_class.output(output)
      expect(output.string).to be_empty
    end
  end
end
