# frozen_string_literal: true

RSpec.describe DatabaseConsistency::ReportBuilder, :sqlite, :mysql, :postgresql do
  describe '.define' do
    subject(:klass) do
      described_class.define(Class.new, :name, :value)
    end

    it 'creates a class with attribute readers' do
      instance = klass.new(name: 'test', value: 42)
      expect(instance.name).to eq('test')
      expect(instance.value).to eq(42)
    end

    it 'responds to to_h with the defined attributes' do
      instance = klass.new(name: 'test', value: 42)
      h = instance.to_h
      # to_h uses values as keys per ReportBuilder's implementation
      expect(h['test']).to eq('test')
      expect(h[42]).to eq(42)
    end

    context 'when inheriting from a base class with to_h' do
      let(:base_class) do
        Class.new do
          def to_h
            { base_attr: 'base_value' }
          end
        end
      end

      subject(:klass) { described_class.define(base_class, :extra) }

      it 'merges with parent to_h' do
        instance = klass.new(extra: 'extra_value')
        h = instance.to_h
        expect(h[:base_attr]).to eq('base_value')
        expect(h['extra_value']).to eq('extra_value')
      end
    end
  end
end
