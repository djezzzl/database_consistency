# frozen_string_literal: true

RSpec.describe DatabaseConsistency::Checkers::ColumnPresenceChecker, :sqlite, :mysql, :postgresql do
  subject(:checker) { described_class.new(model, attribute, validators) }

  let(:model) { klass }
  let(:attribute) { :email }
  let(:validators) { klass._validators[attribute] }

  context 'when null constraint is provided' do
    before do
      define_database do
        create_table :entities do |table|
          table.string :email, null: false
        end
        create_table :country do |table|
          table.belongs_to :entity
        end
      end
    end

    let(:klass) { define_class { |klass| klass.validates :email, presence: true } }

    specify do
      expect(checker.report).to have_attributes(
        checker_name: 'ColumnPresenceChecker',
        table_or_model_name: klass.name,
        column_or_attribute_name: 'email',
        status: :ok,
        error_message: nil,
        error_slug: nil
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
          error_message: nil,
          error_slug: :possible_null
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
          error_message: nil,
          error_slug: nil
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
        error_message: nil,
        error_slug: :null_constraint_missing
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
          error_message: nil,
          error_slug: nil
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

  if ActiveRecord::VERSION::MAJOR >= 6
    context 'when has validation on has_one association' do
      before do
        define_database_with_entity { |table| table.string :email }
      end

      let(:klass) { define_class { |klass| klass.has_one :country, required: true } }
      let(:attribute) { :country }

      specify do
        expect(checker.report).to be_nil
      end
    end
  end

  context 'with polymorphic belongs_to association' do
    before do
      define_database_with_entity do |table|
        table.integer :subject_id, null: false
        table.string :subject_type
      end
    end

    let(:attribute) { :subject }
    let(:klass) { define_class { |klass| klass.belongs_to :subject, polymorphic: true, **required } }

    specify do
      expect(checker.report.last).to have_attributes(
        checker_name: 'ColumnPresenceChecker',
        table_or_model_name: klass.name,
        column_or_attribute_name: 'subject',
        status: :fail,
        error_message: nil,
        error_slug: :association_foreign_type_missing_null_constraint
      )
    end
  end

  context 'when null constraint is missing for the association key' do
    before do
      define_database_with_entity { |table| table.string :user_id }
    end

    let(:attribute) { :user }

    context 'when `belongs_to` is required' do
      let(:klass) { define_class { |klass| klass.belongs_to :user, **required } }

      specify do
        expect(checker.report.first).to have_attributes(
          checker_name: 'ColumnPresenceChecker',
          table_or_model_name: klass.name,
          column_or_attribute_name: 'user',
          status: :fail,
          error_message: nil,
          error_slug: :association_missing_null_constraint
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
        expect(checker.report.first).to have_attributes(
          checker_name: 'ColumnPresenceChecker',
          table_or_model_name: klass.name,
          column_or_attribute_name: 'user',
          status: :ok,
          error_message: nil,
          error_slug: nil
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

  context 'when the column for the `belongs_to` foreign key is missing' do
    let(:attribute) { :user }
    let(:klass) { define_class { |klass| klass.belongs_to :user, foreign_key: 'user_id', **required } }

    before do
      define_database do
        create_table :entities
      end
    end


    specify do
      expect(checker.report(catch_errors: false)).to be_nil
    end
  end
end
