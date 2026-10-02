# frozen_string_literal: true

RSpec.describe DatabaseConsistency::Helper::AndClauses, :sqlite, :mysql, :postgresql do
  describe '.sort' do
    it 'puts the clauses in a stable order' do
      expect(described_class.sort('b = 2 AND a = 1')).to eq('a = 1 AND b = 2')
    end

    it 'returns a single clause exactly as it arrived' do
      expect(described_class.sort('(a = 1)')).to eq('(a = 1)')
    end

    it 'orders around an OR group without reaching into it' do
      expect(described_class.sort('a = 1 AND (b = 2 OR c = 3)')).to eq('(b = 2 OR c = 3) AND a = 1')
    end

    it 'keeps a BETWEEN range whole while ordering the clauses around it' do
      expect(described_class.sort('s = 1 AND qty BETWEEN 1 AND 10')).to eq('qty BETWEEN 1 AND 10 AND s = 1')
    end

    it 'flattens a nested conjunction before ordering' do
      expect(described_class.sort('a = 1 AND (b = 2 AND c = 3)')).to eq('a = 1 AND b = 2 AND c = 3')
    end

    # `a AND b OR c` means `(a AND b) OR c`. Sorting its top-level clauses
    # would move one across the OR and change what the predicate means, so an
    # ungrouped top-level OR is left exactly as it arrived. Active Record's
    # `or` generates this shape.
    it 'leaves an ungrouped top-level OR untouched' do
      expect(described_class.sort('z = 1 AND b = 2 OR d = 4')).to eq('z = 1 AND b = 2 OR d = 4')
    end

    it 'leaves it untouched whichever side of the OR the conjunction is on' do
      expect(described_class.sort('d = 4 OR z = 1 AND b = 2')).to eq('d = 4 OR z = 1 AND b = 2')
    end

    # Guard: the OR here is inside a group, so it is not top-level and the
    # clauses around it can still be ordered.
    it 'still orders the clauses when the OR is grouped' do
      expect(described_class.sort('z = 1 AND (b = 2 OR d = 4)')).to eq('(b = 2 OR d = 4) AND z = 1')
    end
  end

  describe '.split' do
    it 'splits on an AND that joins two clauses' do
      expect(described_class.split('a = 1 AND b = 2')).to eq(['a = 1', 'b = 2'])
    end

    it 'keeps a parenthesized group as one clause' do
      expect(described_class.split('a = 1 AND (b = 2 OR c = 3)')).to eq(['a = 1', '(b = 2 OR c = 3)'])
    end

    it 'keeps a BETWEEN range as one clause' do
      expect(described_class.split('qty BETWEEN 1 AND 10')).to eq(['qty BETWEEN 1 AND 10'])
    end

    it 'keeps a NOT group as one clause' do
      expect(described_class.split('NOT (a = 1 AND b = 2) AND c = 3')).to eq(['NOT (a = 1 AND b = 2)', 'c = 3'])
    end

    it 'flattens a group that holds nothing but conjunctions' do
      expect(described_class.split('a = 1 AND (b = 2 AND c = 3)')).to eq(['a = 1', 'b = 2', 'c = 3'])
      expect(described_class.split('(a = 1 AND b = 2)')).to eq(['a = 1', 'b = 2'])
    end
  end

  describe '.incomplete?' do
    it 'is true while a parenthesized group is still open' do
      expect(described_class.incomplete?('(a = 1')).to be(true)
    end

    it 'is true while a BETWEEN range is missing the AND that ends it' do
      expect(described_class.incomplete?('qty BETWEEN 1')).to be(true)
    end

    it 'is false once the clause stands on its own' do
      expect(described_class.incomplete?('(a = 1)')).to be(false)
      expect(described_class.incomplete?('qty BETWEEN 1 AND 10')).to be(false)
      expect(described_class.incomplete?('a = 1')).to be(false)
    end
  end

  describe '.flatten_group' do
    it 'flattens a group that holds only conjunctions' do
      expect(described_class.flatten_group('(a = 1 AND b = 2)')).to eq(['a = 1', 'b = 2'])
    end

    it 'keeps a group that holds an OR' do
      expect(described_class.flatten_group('(a = 1 OR b = 2)')).to eq(['(a = 1 OR b = 2)'])
    end

    it 'flattens a conjunction whose OR sits in a group of its own' do
      expect(described_class.flatten_group('(a = 1 AND (b = 2 OR c = 3))')).to eq(['a = 1', '(b = 2 OR c = 3)'])
    end

    it 'returns an unwrapped clause on its own' do
      expect(described_class.flatten_group('a = 1')).to eq(['a = 1'])
    end
  end
end
