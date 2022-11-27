# frozen_string_literal: true

RSpec.describe DatabaseConsistency::Checkers::EnumTypeChecker, :sqlite, :mysql, :postgresql do
  subject(:checker) { described_class.new(model, enum) }

  let(:model) { entity_class }
  let(:enum) { entity_class.defined_enums.keys.first }
  let!(:entity_class) do
    define_class do |klass|
      klass.enum field: %i[value1 value2]
    end
  end

  context 'when type matches' do
    before do
      define_database_with_entity do |table|
        table.integer :field
      end
    end

    specify do
      expect(checker.report).to have_attributes(
        checker_name: 'EnumTypeChecker',
        table_or_model_name: entity_class.name,
        column_or_attribute_name: 'field',
        status: :ok,
        error_message: nil,
        error_slug: nil
      )
    end
  end

  context 'when type mismatches' do
    before do
      define_database_with_entity do |table|
        table.string :field
      end
    end

    specify do
      expect(checker.report).to have_attributes(
        checker_name: 'EnumTypeChecker',
        table_or_model_name: entity_class.name,
        column_or_attribute_name: 'field',
        status: :fail,
        error_slug: :inconsistent_enum_type,
        error_message: nil
      )
    end
  end
end
