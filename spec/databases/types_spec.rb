# frozen_string_literal: true

RSpec.describe DatabaseConsistency::Databases::Types::Base, :sqlite, :mysql, :postgresql do
  subject(:type) { described_class.new(raw_type) }

  describe '#convert' do
    let(:raw_type) { 'BigInt' }

    it 'returns the downcased type' do
      expect(type.convert).to eq('bigint')
    end
  end

  describe '#numeric?' do
    context 'when type is numeric' do
      %w[bigserial serial bigint integer smallint].each do |t|
        context "with type #{t}" do
          let(:raw_type) { t }

          it { expect(type.numeric?).to be(true) }
        end
      end
    end

    context 'when type is not numeric' do
      let(:raw_type) { 'varchar' }

      it { expect(type.numeric?).to be(false) }
    end
  end

  describe '#cover?' do
    context 'when bigint covers integer' do
      let(:raw_type) { 'bigint' }

      it 'returns true for integer' do
        expect(type.cover?(described_class.new('integer'))).to be(true)
      end

      it 'returns true for bigint' do
        expect(type.cover?(described_class.new('bigint'))).to be(true)
      end
    end

    context 'when integer covers smallint' do
      let(:raw_type) { 'integer' }

      it 'returns true for smallint' do
        expect(type.cover?(described_class.new('smallint'))).to be(true)
      end

      it 'returns false for bigint' do
        expect(type.cover?(described_class.new('bigint'))).to be(false)
      end
    end

    context 'when type has no coverage mapping' do
      let(:raw_type) { 'varchar' }

      it 'returns true only for exact match' do
        expect(type.cover?(described_class.new('varchar'))).to be(true)
      end

      it 'returns false for other types' do
        expect(type.cover?(described_class.new('text'))).to be(false)
      end
    end
  end
end

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
