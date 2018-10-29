require_relative 'database_context'

RSpec.describe DatabaseConsistency::Processor do
  include_context 'database context'

  describe '#comparisons' do
    subject { described_class.new.comparisons }

    context 'with one validator' do
      before do
        define_database do |t|
          t.string :field, null: false
        end
      end

      let!(:klass) do
        define_class { |klass| klass.validates :field, presence: true }
      end

      specify do
        expect(subject.size).to eq(1)
        expect(subject['Entity'].size).to eq(1)
      end
    end

    context 'with one validator for two attributes' do
      before do
        define_database do |t|
          t.string :field, null: false
          t.string :another, null: false
        end
      end

      let!(:klass) do
        define_class do |klass|
          klass.validates :field, presence: true
          klass.validates :another, presence: true
        end
      end

      specify do
        expect(subject.size).to eq(1)
        expect(subject['Entity'].size).to eq(2)
      end
    end
  end
end
