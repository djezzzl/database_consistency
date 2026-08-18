# frozen_string_literal: true

RSpec.describe DatabaseConsistency::Checkers::NumericalityConstraintChecker, :sqlite, :mysql, :postgresql do
  subject(:checker) { described_class.new(model, attribute, validators) }

  let(:klass) { define_class }
  let(:model) { klass }
  let(:attribute) { :age }
  let(:validators) { klass._validators[attribute] }

  before do
    unless model.connection.respond_to?(:check_constraints)
      skip('check constraints are not supported in this ActiveRecord version')
    end
  end

  context 'when check constraint is provided' do
    before do
      define_database_with_entity do |table|
        table.integer :age
        table.check_constraint 'age >= 0'
      end
    end

    let(:klass) { define_class { |klass| klass.validates :age, numericality: { greater_than_or_equal_to: 0 } } }

    specify do
      expect(checker.report).to have_attributes(
        checker_name: 'NumericalityConstraintChecker',
        table_or_model_name: klass.name,
        column_or_attribute_name: 'age',
        status: :ok,
        error_message: nil,
        error_slug: nil
      )
    end
  end

  context 'when check constraint uses quoted column name' do
    before do
      define_database_with_entity do |table|
        table.integer :age
        table.check_constraint '"age" >= 0'
      end
    end

    let(:klass) { define_class { |klass| klass.validates :age, numericality: { greater_than_or_equal_to: 0 } } }

    specify do
      expect(checker.report).to have_attributes(
        checker_name: 'NumericalityConstraintChecker',
        table_or_model_name: klass.name,
        column_or_attribute_name: 'age',
        status: :ok,
        error_message: nil,
        error_slug: nil
      )
    end
  end

  context 'when the column is named after a SQL keyword' do
    before do
      define_database_with_entity do |table|
        table.integer :limit
        quoted_column = ActiveRecord::Base.connection.quote_column_name(:limit)
        table.check_constraint "#{quoted_column} > 0"
      end
    end

    let(:attribute) { :limit }
    let(:klass) { define_class { |klass| klass.validates :limit, numericality: { greater_than: 0 } } }

    specify do
      expect(checker.report).to have_attributes(
        checker_name: 'NumericalityConstraintChecker',
        table_or_model_name: klass.name,
        column_or_attribute_name: 'limit',
        status: :ok,
        error_message: nil,
        error_slug: nil
      )
    end
  end

  context 'when check constraint uses table-qualified column name' do
    before do
      define_database_with_entity do |table|
        table.integer :age
        table.check_constraint 'entities.age >= 0'
      end
    end

    let(:klass) { define_class { |klass| klass.validates :age, numericality: { greater_than_or_equal_to: 0 } } }

    specify do
      expect(checker.report).to have_attributes(
        checker_name: 'NumericalityConstraintChecker',
        table_or_model_name: klass.name,
        column_or_attribute_name: 'age',
        status: :ok,
        error_message: nil,
        error_slug: nil
      )
    end
  end

  context 'when check constraint is missing' do
    before do
      define_database_with_entity { |table| table.integer :age }
    end

    let(:klass) { define_class { |klass| klass.validates :age, numericality: { greater_than_or_equal_to: 0 } } }

    specify do
      expect(checker.report).to have_attributes(
        checker_name: 'NumericalityConstraintChecker',
        table_or_model_name: klass.name,
        column_or_attribute_name: 'age',
        status: :fail,
        error_message: nil,
        error_slug: :numericality_check_constraint_missing
      )
    end
  end

  context 'when numericality validator has no options' do
    before do
      define_database_with_entity { |table| table.integer :age }
    end

    let(:klass) { define_class { |klass| klass.validates :age, numericality: true } }

    specify do
      expect(checker.report).to be_nil
    end
  end

  context 'when numericality validator has only non-range options' do
    before do
      define_database_with_entity { |table| table.integer :age }
    end

    let(:klass) { define_class { |klass| klass.validates :age, numericality: { only_integer: true } } }

    specify do
      expect(checker.report).to be_nil
    end
  end

  context 'when numericality validator has only allow_nil' do
    before do
      define_database_with_entity { |table| table.integer :age }
    end

    let(:klass) { define_class { |klass| klass.validates :age, numericality: { allow_nil: true } } }

    specify do
      expect(checker.report).to be_nil
    end
  end

  context 'when numericality validator has a range option' do
    before do
      define_database_with_entity { |table| table.integer :age }
    end

    let(:klass) { define_class { |klass| klass.validates :age, numericality: { greater_than: 0 } } }

    specify do
      expect(checker.report).to have_attributes(
        checker_name: 'NumericalityConstraintChecker',
        table_or_model_name: klass.name,
        column_or_attribute_name: 'age',
        status: :fail,
        error_message: nil,
        error_slug: :numericality_check_constraint_missing
      )
    end
  end

  context 'when numericality validator combines range and non-range options' do
    before do
      define_database_with_entity { |table| table.integer :age }
    end

    let(:klass) { define_class { |klass| klass.validates :age, numericality: { only_integer: true, less_than: 100 } } }

    specify do
      expect(checker.report).to have_attributes(
        checker_name: 'NumericalityConstraintChecker',
        table_or_model_name: klass.name,
        column_or_attribute_name: 'age',
        status: :fail,
        error_message: nil,
        error_slug: :numericality_check_constraint_missing
      )
    end
  end

  context 'when attribute has no numericality validator' do
    before do
      define_database_with_entity { |table| table.integer :age }
    end

    let(:klass) { define_class { |klass| klass.validates :age, presence: true } }

    specify do
      expect(checker.report).to be_nil
    end
  end

  context 'when check constraint exists for another column' do
    before do
      define_database_with_entity do |table|
        table.integer :age
        table.integer :salary
        table.check_constraint 'salary >= 0'
      end
    end

    let(:klass) { define_class { |klass| klass.validates :age, numericality: { greater_than_or_equal_to: 0 } } }

    specify do
      expect(checker.report).to have_attributes(
        checker_name: 'NumericalityConstraintChecker',
        table_or_model_name: klass.name,
        column_or_attribute_name: 'age',
        status: :fail,
        error_message: nil,
        error_slug: :numericality_check_constraint_missing
      )
    end
  end

  context 'when check constraint uses SQL function' do
    before do
      define_database_with_entity do |table|
        table.integer :age
        table.integer :abs
        table.check_constraint 'ABS(age) >= 0'
      end
    end

    let(:attribute) { :abs }
    let(:klass) { define_class { |klass| klass.validates :abs, numericality: { greater_than_or_equal_to: 0 } } }

    specify do
      expect(checker.report).to have_attributes(
        checker_name: 'NumericalityConstraintChecker',
        table_or_model_name: klass.name,
        column_or_attribute_name: 'abs',
        status: :fail,
        error_message: nil,
        error_slug: :numericality_check_constraint_missing
      )
    end
  end
end
