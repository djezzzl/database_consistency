# frozen_string_literal: true

RSpec.describe DatabaseConsistency::Checkers::ColumnPresenceChecker do
  test_each_database do
    subject(:checker) { described_class.new(model, attribute, validators) }

    let(:model) { klass }
    let(:attribute) { :email }
    let(:validators) { klass._validators[attribute] }

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

      context 'when null insert is possible' do
        let(:klass) { define_class { |klass| klass.validates :email, presence: true, if: -> { false } } }

        specify do
          expect(checker.report).to have_attributes(
            checker_name: 'ColumnPresenceChecker',
            table_or_model_name: klass.name,
            column_or_attribute_name: 'email',
            status: :fail,
            message: 'column is required but there is possible null value insert'
          )
        end
      end

      context 'when has both strong and weak validators' do
        let(:klass) do
          define_class do |klass|
            klass.validates :email, presence: true, if: -> { false }
            klass.validates :email, presence: true
          end
        end

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
          message: 'column should be required in the database'
        )
      end
    end
  end
end
