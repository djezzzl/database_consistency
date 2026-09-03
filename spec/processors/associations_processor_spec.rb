# frozen_string_literal: true

RSpec.describe DatabaseConsistency::Processors::AssociationsProcessor, :sqlite do
  subject(:processor) { described_class.new(config) }

  let(:config) { DatabaseConsistency::Configuration.new }
  let(:entity_class) do
    define_database do
      create_table :entities do |t|
        t.integer :user_id
      end
      create_table :users
    end
    define_class('User', :users)
    define_class('Entity', :entities) { |klass| klass.belongs_to :user }
  end

  before do
    skip('older versions are not supported with sqlite3') if ActiveRecord::VERSION::MAJOR < 5 && adapter == 'sqlite3'
    allow(DatabaseConsistency::Helper).to receive(:models).and_return([entity_class])
  end

  describe '#reports' do
    it 'returns an array of reports' do
      expect(processor.reports).to be_an(Array)
    end

    it 'processes associations' do
      expect(processor.reports).not_to be_nil
    end
  end
end
