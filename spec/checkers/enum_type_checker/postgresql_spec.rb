# frozen_string_literal: true

RSpec.describe DatabaseConsistency::Checkers::EnumTypeChecker, :postgresql do
  subject(:checker) { described_class.new(model, enum) }

  before do
    skip('older versions are not supported with sqlite3') if ActiveRecord::VERSION::MAJOR < 7 && adapter != 'postgresql'
  end

  let(:model) { entity_class }
  let(:enum) { entity_class.defined_enums.keys.first }
  let!(:entity_class) do
    define_class do |klass|
      klass.enum field: { value1: 'valueu1', value2: 'value2' }
    end
  end

  context 'with enum type' do
    before do
      define_database do
        create_enum :field_type, %w[value1 value2]

        create_table :entities do |t|
          t.enum :field, enum_type: 'field_type'
        end
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
end
