# frozen_string_literal: true

RSpec.describe DatabaseConsistency::Checkers::ColumnPresenceChecker do
  subject(:checker) { described_class.new(model, attribute, validator) }

  let(:model) { klass }
  let(:attribute) { :email }
  let(:validator) { klass.validators.first }

  include_context 'database context'

  context 'when null constraint is provided' do
    before do
      define_database_with_entity { |table| table.string :email, null: false }
    end

    let(:klass) { define_class { |klass| klass.validates :email, presence: true } }

    specify do
      expect(checker.report).to have_attributes(
        checker_name: 'ColumnPresenceChecker',
        table_or_model_name: klass.name,
        column_or_attribute_name: 'email',
        status: :ok,
        message: nil
      )
    end
  end

  context 'when null constraint is missing' do
    before do
      define_database_with_entity { |table| table.string :email }
    end

    let(:klass) { define_class { |klass| klass.validates :email, presence: true } }

    specify do
      expect(checker.report).to have_attributes(
        checker_name: 'ColumnPresenceChecker',
        table_or_model_name: klass.name,
        column_or_attribute_name: 'email',
        status: :fail,
        message: 'should be required in the database'
      )
    end
  end

  context 'when null insert is possible' do
    before do
      define_database_with_entity { |table| table.string :email, null: false }
    end

    let(:klass) { define_class { |klass| klass.validates :email, presence: true, if: -> { false } } }

    specify do
      expect(checker.report).to have_attributes(
        checker_name: 'ColumnPresenceChecker',
        table_or_model_name: klass.name,
        column_or_attribute_name: 'email',
        status: :fail,
        message: 'is required but possible null value insert'
      )
    end
  end
end
