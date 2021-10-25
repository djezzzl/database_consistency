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

      context 'when validator has "on" option specified' do
        let(:klass) { define_class { |klass| klass.validates :email, presence: true, on: :update } }

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

    if ActiveRecord::VERSION::MAJOR >= 5
      required = { optional: false }
      optional = { optional: true }
    else
      required = { required: true }
      optional = { required: false }
    end

    context 'when null constraint is missing for the association key' do
      before do
        define_database_with_entity { |table| table.string :user_id }
      end

      let(:attribute) { :user }

      context 'when `belongs_to` is required' do
        let(:klass) { define_class { |klass| klass.belongs_to :user, **required } }

        specify do
          expect(checker.report).to have_attributes(
            checker_name: 'ColumnPresenceChecker',
            table_or_model_name: klass.name,
            column_or_attribute_name: 'user',
            status: :fail,
            message: 'association foreign key column should be required in the database'
          )
        end
      end

      context 'when `belongs_to` is optional' do
        let(:klass) { define_class { |klass| klass.belongs_to :user, **optional } }

        specify do
          expect(checker.report).to be_nil
        end
      end
    end

    context 'when null constraint is provided for the association key' do
      let(:attribute) { :user }

      before do
        define_database_with_entity { |table| table.string :user_id, null: false }
      end

      context 'when `belongs_to` is required' do
        let(:klass) { define_class { |klass| klass.belongs_to :user, **required } }

        specify do
          expect(checker.report).to have_attributes(
            checker_name: 'ColumnPresenceChecker',
            table_or_model_name: klass.name,
            column_or_attribute_name: 'user',
            status: :ok,
            message: nil
          )
        end
      end

      context 'when `belongs_to` is optional' do
        let(:klass) { define_class { |klass| klass.belongs_to :user, **optional } }

        specify do
          expect(checker.report).to be_nil
        end
      end
    end
  end
end
