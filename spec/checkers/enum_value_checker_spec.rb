# frozen_string_literal: true

RSpec.describe DatabaseConsistency::Checkers::EnumValueChecker, :postgresql do
  subject(:checker) { described_class.new(model, column) }

  let(:model) { klass }
  let(:column) { klass.columns.last }

  before do
    skip('older versions are not supported') if ActiveRecord::VERSION::MAJOR < 7

    define_database do
      create_enum :status_type, %w[value1 value2]

      create_table :entities do |t|
        t.enum :status, enum_type: 'status_type'
      end
    end
  end

  context 'without validator nor ActiveRecord enum' do
    let(:klass) { define_class }

    specify do
      expect(checker.report).to be_nil
    end
  end

  context 'when values are consistent' do
    let(:klass) do
      define_class do |klass|
        klass.enum :status, { value1: 'value1', value2: 'value2' }
        klass.validates :status, inclusion: { in: %w[value1 value2] }
      end
    end

    specify do
      expect(checker.report.first).to have_attributes(
        checker_name: 'EnumValueChecker',
        table_or_model_name: klass.name,
        column_or_attribute_name: 'status',
        status: :ok,
        enum_values: %w[value1 value2],
        declared_values: %w[value1 value2],
        error_slug: nil,
        error_message: nil
      )

      expect(checker.report.last).to have_attributes(
        checker_name: 'EnumValueChecker',
        table_or_model_name: klass.name,
        column_or_attribute_name: 'status',
        status: :ok,
        enum_values: %w[value1 value2],
        declared_values: %w[value1 value2],
        error_slug: nil,
        error_message: nil
      )
    end
  end

  context 'when validation values are inconsistent' do
    let(:klass) { define_class { |klass| klass.validates :status, inclusion: { in: %w[value1 something] } } }

    specify do
      expect(checker.report.first).to have_attributes(
        checker_name: 'EnumValueChecker',
        table_or_model_name: klass.name,
        column_or_attribute_name: 'status',
        status: :fail,
        error_slug: :enum_values_inconsistent_with_inclusion,
        enum_values: %w[value1 value2],
        declared_values: %w[value1 something],
        error_message: nil
      )
    end
  end

  context 'when validation values are out of order' do
    let(:klass) { define_class { |klass| klass.validates :status, inclusion: { in: %w[value2 value1] } } }

    specify do
      expect(checker.report.first).to have_attributes(
        checker_name: 'EnumValueChecker',
        table_or_model_name: klass.name,
        column_or_attribute_name: 'status',
        status: :ok,
        error_slug: nil,
        enum_values: %w[value1 value2],
        declared_values: %w[value2 value1],
        error_message: nil
      )
    end
  end

  context 'when enum values are inconsistent' do
    let(:klass) { define_class { |klass| klass.enum :status, { value1: 'value1', something: 'something' } } }

    specify do
      expect(checker.report.first).to have_attributes(
        checker_name: 'EnumValueChecker',
        table_or_model_name: klass.name,
        column_or_attribute_name: 'status',
        status: :fail,
        error_slug: :enum_values_inconsistent_with_ar_enum,
        enum_values: %w[value1 value2],
        declared_values: %w[value1 something],
        error_message: nil
      )
    end
  end

  context 'when enum values are out of order' do
    let(:klass) { define_class { |klass| klass.enum :status, { value2: 'value2', value1: 'value1' } } }

    specify do
      expect(checker.report.first).to have_attributes(
        checker_name: 'EnumValueChecker',
        table_or_model_name: klass.name,
        column_or_attribute_name: 'status',
        status: :ok,
        error_slug: nil,
        enum_values: %w[value1 value2],
        declared_values: %w[value2 value1],
        error_message: nil
      )
    end
  end
end
