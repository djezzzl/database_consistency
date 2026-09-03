# frozen_string_literal: true

RSpec.describe DatabaseConsistency::Databases::Types::Sqlite, :sqlite, :mysql, :postgresql do
  subject(:type) { described_class.new(raw_type) }

  describe '#convert' do
    {
      'bigserial' => 'bigint',
      'serial' => 'integer',
      'integer(8)' => 'bigint',
      'integer(4)' => 'integer',
      'integer(2)' => 'smallint'
    }.each do |input, expected|
      context "with type #{input}" do
        let(:raw_type) { input }

        it "converts to #{expected}" do
          expect(type.convert).to eq(expected)
        end
      end
    end

    context 'with an unmapped type' do
      let(:raw_type) { 'varchar' }

      it 'returns the type as-is' do
        expect(type.convert).to eq('varchar')
      end
    end
  end
end
