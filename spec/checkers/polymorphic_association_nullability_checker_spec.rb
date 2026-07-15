# frozen_string_literal: true

RSpec.describe DatabaseConsistency::Checkers::PolymorphicAssociationNullabilityChecker, :sqlite, :mysql, :postgresql do
  subject(:checker) { described_class.new(model, association) }

  let(:model) { entity_class }
  let(:association) { entity_class.reflect_on_all_associations.first }
  let(:foreign_key_null) { true }
  let(:foreign_type_null) { true }
  let!(:entity_class) do
    define_class do |klass|
      klass.belongs_to :record, polymorphic: true, optional: true
    end
  end

  before do
    key_null = foreign_key_null
    type_null = foreign_type_null

    define_database do
      create_table :entities do |t|
        t.integer :record_id, null: key_null
        t.string :record_type, null: type_null
      end
    end
  end

  context 'when both columns are nullable' do
    specify do
      expect(checker.report).to have_attributes(
        checker_name: 'PolymorphicAssociationNullabilityChecker',
        table_or_model_name: entity_class.name,
        column_or_attribute_name: 'record',
        status: :ok,
        error_slug: nil,
        error_message: nil
      )
    end
  end

  context 'when neither column is nullable' do
    let(:foreign_key_null) { false }
    let(:foreign_type_null) { false }

    specify do
      expect(checker.report).to have_attributes(
        checker_name: 'PolymorphicAssociationNullabilityChecker',
        table_or_model_name: entity_class.name,
        column_or_attribute_name: 'record',
        status: :ok,
        error_slug: nil,
        error_message: nil
      )
    end
  end

  context 'when only the foreign key is nullable' do
    let(:foreign_type_null) { false }

    specify do
      expect(checker.report).to have_attributes(
        checker_name: 'PolymorphicAssociationNullabilityChecker',
        table_or_model_name: entity_class.name,
        column_or_attribute_name: 'record',
        status: :fail,
        error_slug: :polymorphic_association_nullability_mismatch,
        error_message: nil,
        foreign_key: 'record_id',
        foreign_type: 'record_type'
      )
    end
  end

  context 'when only the foreign type is nullable' do
    let(:foreign_key_null) { false }

    specify do
      expect(checker.report).to have_attributes(
        checker_name: 'PolymorphicAssociationNullabilityChecker',
        table_or_model_name: entity_class.name,
        column_or_attribute_name: 'record',
        status: :fail,
        error_slug: :polymorphic_association_nullability_mismatch,
        error_message: nil,
        foreign_key: 'record_id',
        foreign_type: 'record_type'
      )
    end
  end

  context 'when the association is not polymorphic' do
    let!(:entity_class) do
      define_class do |klass|
        klass.belongs_to :record, optional: true
      end
    end

    specify do
      expect(checker.report).to be_nil
    end
  end
end
