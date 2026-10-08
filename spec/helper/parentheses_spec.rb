# frozen_string_literal: true

RSpec.describe DatabaseConsistency::Helper::Parentheses, :sqlite, :mysql, :postgresql do
  describe '.strip_outer' do
    it 'removes every layer that encloses the whole fragment' do
      expect(described_class.strip_outer('((foo))')).to eq('foo')
    end

    it 'leaves a fragment whose opening parenthesis closes early' do
      expect(described_class.strip_outer('(a) AND (b)')).to eq('(a) AND (b)')
    end

    it 'leaves a fragment that is not enclosed at all' do
      expect(described_class.strip_outer('a = 1')).to eq('a = 1')
    end

    it 'strips the whitespace around and inside the layer it removes' do
      expect(described_class.strip_outer('  ( a = 1 )  ')).to eq('a = 1')
    end
  end

  describe '.wrapping?' do
    it 'is true when one pair encloses the whole fragment' do
      expect(described_class.wrapping?('(a)')).to be(true)
    end

    it 'is false when the opening parenthesis closes before the end' do
      expect(described_class.wrapping?('(a) AND (b)')).to be(false)
    end

    it 'is false when a group is left open' do
      expect(described_class.wrapping?('((a)')).to be(false)
    end

    it 'is false without a parenthesis on both ends' do
      expect(described_class.wrapping?('a)')).to be(false)
      expect(described_class.wrapping?('(a')).to be(false)
    end
  end

  describe '.unclosed?' do
    it 'reports only a group that is opened and never closed' do
      expect(described_class.unclosed?('(a = 1')).to be(true)
      expect(described_class.unclosed?('(a = 1)')).to be(false)
      expect(described_class.unclosed?('a = 1)')).to be(false)
    end
  end

  describe '.depth_after' do
    it 'counts an opening parenthesis up, a closing one down, and ignores the rest' do
      expect(described_class.depth_after(0, '(')).to eq(1)
      expect(described_class.depth_after(0, ')')).to eq(-1)
      expect(described_class.depth_after(0, 'x')).to eq(0)
    end
  end
end
