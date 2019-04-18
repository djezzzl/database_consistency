# frozen_string_literal: true

RSpec.describe DatabaseConsistency::Checkers::MissingUniqueIndexChecker do
  subject(:checker) { described_class.new(model, attribute, validator) }

  let(:model) { klass }
  let(:attribute) { :email }
  let(:validator) { klass.validators.first }

  context 'with postgresql database' do
    include_context 'postgresql database context'

    context 'when uniqueness validation has case sensitive option turned off' do
      let(:klass) { define_class { |klass| klass.validates :email, uniqueness: { case_sensitive: false } } }

      context 'when unique index is provided' do
        before do
          define_database_with_entity do |table|
            table.string :email
            table.index 'lower(email)', unique: true
          end
        end

        specify do
          expect(checker.report).to have_attributes(
            checker_name: 'MissingUniqueIndexChecker',
            table_or_model_name: klass.name,
            column_or_attribute_name: 'lower(email)',
            status: :ok,
            message: nil
          )
        end
      end

      context 'when unique index is missing' do
        before do
          define_database_with_entity do |table|
            table.string :email
          end
        end

        specify do
          expect(checker.report).to have_attributes(
            checker_name: 'MissingUniqueIndexChecker',
            table_or_model_name: klass.name,
            column_or_attribute_name: 'lower(email)',
            status: :fail,
            message: 'model should have proper unique index in the database'
          )
        end
      end

      context 'when uniqueness validation has scope' do
        let(:klass) do
          define_class { |klass| klass.validates :email, uniqueness: { case_sensitive: false, scope: :phone } }
        end

        context 'when unique index is provided' do
          before do
            define_database_with_entity do |table|
              table.string :email
              table.string :phone
              table.index 'lower(email), phone', unique: true
            end
          end

          specify do
            expect(checker.report).to have_attributes(
              checker_name: 'MissingUniqueIndexChecker',
              table_or_model_name: klass.name,
              column_or_attribute_name: 'lower(email)+phone',
              status: :ok,
              message: nil
            )
          end
        end

        context 'when unique index is missing' do
          before do
            define_database_with_entity do |table|
              table.string :email
              table.string :phone
            end
          end

          specify do
            expect(checker.report).to have_attributes(
              checker_name: 'MissingUniqueIndexChecker',
              table_or_model_name: klass.name,
              column_or_attribute_name: 'lower(email)+phone',
              status: :fail,
              message: 'model should have proper unique index in the database'
            )
          end
        end
      end
    end
  end
end
