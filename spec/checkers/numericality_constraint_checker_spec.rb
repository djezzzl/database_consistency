# frozen_string_literal: true

RSpec.describe DatabaseConsistency::Checkers::NumericalityConstraintChecker, :sqlite, :mysql, :postgresql do
  subject(:checker) { described_class.new(model, attribute, validators) }

  let(:klass) { define_class }
  let(:model) { klass }
  let(:attribute) { :age }
  let(:validators) { klass._validators[attribute] }

  context 'when check constraint is provided' do
    before do
      define_database_with_entity do |table|
        table.integer :age
        table.check_constraint 'age >= 0'
      end
    end

    let(:klass) { define_class { |klass| klass.validates :age, numericality: true } }

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

    let(:klass) { define_class { |klass| klass.validates :age, numericality: true } }

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

  context 'when check constraint uses table-qualified column name' do
    before do
      define_database_with_entity do |table|
        table.integer :age
        table.check_constraint 'entities.age >= 0'
      end
    end

    let(:klass) { define_class { |klass| klass.validates :age, numericality: true } }

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

    let(:klass) { define_class { |klass| klass.validates :age, numericality: true } }

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

  context 'when check constraint exists for another column' do
    before do
      define_database_with_entity do |table|
        table.integer :age
        table.integer :salary
        table.check_constraint 'salary >= 0'
      end
    end

    let(:klass) { define_class { |klass| klass.validates :age, numericality: true } }

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

  context 'when check constraint exists for similarly named column' do
    before do
      define_database_with_entity do |table|
        table.integer :age
        table.integer :page
        table.check_constraint 'page >= 0'
      end
    end

    let(:klass) { define_class { |klass| klass.validates :age, numericality: true } }

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
    let(:klass) { define_class { |klass| klass.validates :abs, numericality: true } }

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
