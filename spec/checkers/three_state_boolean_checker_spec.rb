# frozen_string_literal: true

RSpec.describe DatabaseConsistency::Checkers::ThreeStateBooleanChecker, :sqlite, :mysql, :postgresql do
  subject(:checker) { described_class.new(model, column) }

  let(:klass) { define_class }
  let(:model) { klass }
  let(:column) { klass.columns.first }

  context 'when column is nullable and without default' do
    before do
      define_database_with_entity do |table|
        table.boolean :active
      end
    end

    specify do
      expect(checker.report).to have_attributes(
        checker_name: 'ThreeStateBooleanChecker',
        table_or_model_name: klass.name,
        column_or_attribute_name: 'active',
        status: :fail,
        error_message: nil,
        error_slug: :three_state_boolean,
        table_name: klass.table_name,
        column_name: 'active'
      )
    end
  end

  context 'when column is not nullable and without default' do
    before do
      define_database_with_entity do |table|
        table.boolean :active, null: false
      end
    end

    specify do
      expect(checker.report).to have_attributes(
        checker_name: 'ThreeStateBooleanChecker',
        table_or_model_name: klass.name,
        column_or_attribute_name: 'active',
        status: :ok,
        error_message: nil,
        error_slug: nil,
        table_name: klass.table_name,
        column_name: 'active'
      )
    end
  end

  context 'when column is nullable and with default' do
    before do
      define_database_with_entity do |table|
        table.boolean :active, default: true
      end
    end

    specify do
      expect(checker.report).to have_attributes(
        checker_name: 'ThreeStateBooleanChecker',
        table_or_model_name: klass.name,
        column_or_attribute_name: 'active',
        status: :fail,
        error_message: nil,
        error_slug: :three_state_boolean,
        table_name: klass.table_name,
        column_name: 'active'
      )
    end
  end

  context 'when column is not nullable and with default' do
    before do
      define_database_with_entity do |table|
        table.boolean :active, null: false, default: true
      end
    end

    specify do
      expect(checker.report).to have_attributes(
        checker_name: 'ThreeStateBooleanChecker',
        table_or_model_name: klass.name,
        column_or_attribute_name: 'active',
        status: :ok,
        error_message: nil,
        error_slug: nil,
        table_name: klass.table_name,
        column_name: 'active'
      )
    end
  end
end
