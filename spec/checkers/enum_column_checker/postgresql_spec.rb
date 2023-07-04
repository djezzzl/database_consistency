# frozen_string_literal: true

RSpec.describe DatabaseConsistency::Checkers::EnumColumnChecker, :postgresql do
  subject(:checker) { described_class.new(model, enum) }

  before do
    skip('older versions are not supported') if ActiveRecord::VERSION::MAJOR < 7
  end

  let(:model) { entity_class }
  let(:enum) { entity_class.defined_enums.keys.first }

  context 'with enum column' do
    let(:entity_class) do
      define_class do |klass|
        klass.enum field: { value1: 'value1', value2: 'value2' }
      end
    end

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
        checker_name: 'EnumColumnChecker',
        table_or_model_name: entity_class.name,
        column_or_attribute_name: 'field',
        status: :ok,
        error_message: nil,
        error_slug: nil
      )
    end
  end

  context 'with integer column' do
    let(:entity_class) do
      define_class do |klass|
        klass.enum field: %i[value1 value2]
      end
    end

    before do
      define_database do
        create_table :entities do |t|
          t.integer :field
        end
      end
    end

    specify do
      expect(checker.report).to have_attributes(
        checker_name: 'EnumColumnChecker',
        table_or_model_name: entity_class.name,
        column_or_attribute_name: 'field',
        status: :fail,
        error_message: nil,
        error_slug: :enum_column_type_mismatch
      )
    end
  end

  context 'with string column' do
    let(:entity_class) do
      define_class do |klass|
        klass.enum field: { value1: 'value1', value2: 'value2' }
      end
    end

    before do
      define_database do
        create_table :entities do |t|
          t.string :field
        end
      end
    end

    specify do
      expect(checker.report).to have_attributes(
        checker_name: 'EnumColumnChecker',
        table_or_model_name: entity_class.name,
        column_or_attribute_name: 'field',
        status: :fail,
        error_message: nil,
        error_slug: :enum_column_type_mismatch
      )
    end
  end
end
