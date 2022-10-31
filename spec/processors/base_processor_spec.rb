# frozen_string_literal: true

RSpec.describe DatabaseConsistency::Processors::BaseProcessor do
  subject(:processor) { dummy_processor.new }

  describe '#reports' do
    subject(:reports) { processor.reports }

    context 'when error happens' do
      let(:dummy_processor) do
        Class.new(described_class) do
          def check
            raise 'issue'
          end
        end
      end

      it 'catches errors' do
        expect(DatabaseConsistency::RescueError).to receive(:call).with(kind_of(StandardError))

        expect(reports).to eq([])
      end
    end
  end
end
