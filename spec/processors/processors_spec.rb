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

RSpec.describe DatabaseConsistency::Processors::ColumnsProcessor, :sqlite do
  subject(:processor) { described_class.new(config) }

  let(:config) { DatabaseConsistency::Configuration.new }
  let(:entity_class) do
    define_database_with_entity { |table| table.string :email, null: false }
    define_class('Entity', :entities)
  end

  before do
    allow(DatabaseConsistency::Helper).to receive(:parent_models).and_return([entity_class])
  end

  describe '#reports' do
    it 'returns an array of reports' do
      expect(processor.reports).to be_an(Array)
    end

    it 'processes columns' do
      expect(processor.reports).not_to be_nil
    end
  end
end

RSpec.describe DatabaseConsistency::Processors::EnumsProcessor, :sqlite do
  subject(:processor) { described_class.new(config) }

  let(:config) { DatabaseConsistency::Configuration.new }
  let(:entity_class) do
    define_database_with_entity { |table| table.integer :status }
    define_class('Entity', :entities) do |klass|
      if ActiveRecord::VERSION::MAJOR >= 8
        klass.enum :status, %i[active inactive]
      else
        klass.enum status: %i[active inactive]
      end
    end
  end

  before do
    allow(DatabaseConsistency::Helper).to receive(:models).and_return([entity_class])
  end

  describe '#reports' do
    it 'returns an array of reports' do
      expect(processor.reports).to be_an(Array)
    end

    it 'processes enums' do
      expect(processor.reports).not_to be_nil
    end
  end
end

RSpec.describe DatabaseConsistency::Processors::IndexesProcessor, :sqlite do
  subject(:processor) { described_class.new(config) }

  let(:config) { DatabaseConsistency::Configuration.new }
  let(:entity_class) do
    define_database do
      create_table :entities do |t|
        t.string :email
        t.index :email
      end
    end
    define_class('Entity', :entities)
  end

  before do
    allow(DatabaseConsistency::Helper).to receive(:parent_models).and_return([entity_class])
  end

  describe '#reports' do
    it 'returns an array of reports' do
      expect(processor.reports).to be_an(Array)
    end

    it 'processes indexes' do
      expect(processor.reports).not_to be_nil
    end
  end
end

RSpec.describe DatabaseConsistency::Processors::ModelsProcessor, :sqlite do
  subject(:processor) { described_class.new(config) }

  let(:config) { DatabaseConsistency::Configuration.new }
  let(:entity_class) do
    define_database_with_entity { |table| table.string :email }
    define_class('Entity', :entities)
  end

  before do
    allow(DatabaseConsistency::Helper).to receive(:project_models).and_return([entity_class])
  end

  describe '#reports' do
    it 'returns an array of reports' do
      expect(processor.reports).to be_an(Array)
    end

    it 'processes models' do
      expect(processor.reports).not_to be_nil
    end
  end
end

RSpec.describe DatabaseConsistency::Processors::ValidatorsProcessor, :sqlite do
  subject(:processor) { described_class.new(config) }

  let(:config) { DatabaseConsistency::Configuration.new }
  let(:entity_class) do
    define_database_with_entity { |table| table.string :email, null: false }
    define_class('Entity', :entities) { |klass| klass.validates :email, presence: true }
  end

  before do
    allow(DatabaseConsistency::Helper).to receive(:parent_models).and_return([entity_class])
  end

  describe '#reports' do
    it 'returns an array of reports' do
      expect(processor.reports).to be_an(Array)
    end

    it 'processes validators' do
      expect(processor.reports).not_to be_nil
    end
  end
end

RSpec.describe DatabaseConsistency::Processors::ValidatorsFractionsProcessor, :sqlite do
  subject(:processor) { described_class.new(config) }

  let(:config) { DatabaseConsistency::Configuration.new }
  let(:entity_class) do
    define_database_with_entity { |table| table.string :email, null: false }
    define_class('Entity', :entities) { |klass| klass.validates :email, presence: true }
  end

  before do
    allow(DatabaseConsistency::Helper).to receive(:parent_models).and_return([entity_class])
  end

  describe '#reports' do
    it 'returns an array of reports' do
      expect(processor.reports).to be_an(Array)
    end

    it 'processes validator fractions' do
      expect(processor.reports).not_to be_nil
    end
  end
end

RSpec.describe DatabaseConsistency::Processors do
  let(:config) { DatabaseConsistency::Configuration.new }

  describe '.reports' do
    it 'returns reports from all processors' do
      expect(described_class.reports(config)).to be_an(Array)
    end
  end
end

