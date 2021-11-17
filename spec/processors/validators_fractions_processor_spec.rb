# frozen_string_literal: true

RSpec.describe DatabaseConsistency::Processors::ValidatorsFractionsProcessor do
  test_each_database do
    subject(:processor) { described_class.new }

    describe 'when has_one association is required' do
      before do
        define_database do
          create_table :users
        end

        define_class('User', :users) do |klass|
          klass.has_one :company
          klass.validates :company, presence: true
        end
      end

      specify do
        expect(processor.reports).to be_empty
      end
    end
  end
end
