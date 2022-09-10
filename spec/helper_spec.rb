# frozen_string_literal: true

RSpec.describe DatabaseConsistency::Helper, :sqlite, :mysql, :postgresql do
  subject { described_class.first_level_associations(child) }

  describe '#first_level_associations' do
    let(:parent) { Class.new(ActiveRecord::Base) { |klass| klass.has_one :user } }

    context 'when only parent defines association' do
      let(:child) { Class.new(parent) }
      it { is_expected.to eq([]) }
    end

    context 'when child redefines association' do
      let(:child) { Class.new(parent) { |klass| klass.has_one :user } }
      it { expect(subject.size).to eq(1) }
    end
  end
end
