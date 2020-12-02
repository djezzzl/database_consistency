# frozen_string_literal: true

RSpec.describe DatabaseConsistency::Checkers::UniqueIndexChecker do
  subject(:checker) { described_class.new(model, index) }

  let(:model) { klass }
  let(:index) { ActiveRecord::Base.connection.indexes(klass.table_name).first }

  let(:checker_name) { described_class.to_s.split('::').last }
  let(:index_name) { 'index_name' }

  test_each_database do
    context 'mono attribute index' do
      before do
        define_database_with_entity do |table|
          table.string :first_name
          table.string :email, index: { unique: true, name: index_name }
        end
      end

      context 'when validation is present' do
        let(:klass) { define_class { |klass| klass.validates :email, :first_name, uniqueness: true } }

        specify do
          expect(checker.report).to have_attributes(
            checker_name: checker_name,
            table_or_model_name: klass.name,
            column_or_attribute_name: index_name,
            status: :ok,
            message: nil
          )
        end
      end

      context 'when validation is missing' do
        let(:klass) { define_class }

        specify do
          expect(checker.report).to have_attributes(
            checker_name: checker_name,
            table_or_model_name: klass.name,
            column_or_attribute_name: index_name,
            status: :fail,
            message: 'index is unique in the database but do not have uniqueness validator'
          )
        end
      end
    end

    context 'two attributes index' do
      before do
        define_database_with_entity do |table|
          table.string :first_name
          table.string :email

          table.index %i[first_name email], unique: true, name: index_name
        end
      end

      context 'when validation is present one way' do
        let(:klass) { define_class { |klass| klass.validates :email, uniqueness: { scope: :first_name } } }

        specify do
          expect(checker.report).to have_attributes(
            checker_name: checker_name,
            table_or_model_name: klass.name,
            column_or_attribute_name: index_name,
            status: :ok,
            message: nil
          )
        end
      end

      context 'when validation is present the other way' do
        let(:klass) { define_class { |klass| klass.validates :first_name, uniqueness: { scope: :email } } }

        specify do
          expect(checker.report).to have_attributes(
            checker_name: checker_name,
            table_or_model_name: klass.name,
            column_or_attribute_name: index_name,
            status: :ok,
            message: nil
          )
        end
      end

      context 'when validation is missing' do
        let(:klass) { define_class { |klass| klass.validates :first_name, uniqueness: true } }

        specify do
          expect(checker.report).to have_attributes(
            checker_name: checker_name,
            table_or_model_name: klass.name,
            column_or_attribute_name: index_name,
            status: :fail,
            message: 'index is unique in the database but do not have uniqueness validator'
          )
        end
      end
    end

    context 'three attributes index' do
      before do
        define_database_with_entity do |table|
          table.string :first_name
          table.string :last_name
          table.string :email

          table.index %i[first_name last_name email], unique: true, name: index_name
        end
      end

      context 'when validation is present one way' do
        let(:klass) { define_class { |klass| klass.validates :email, uniqueness: { scope: %i[first_name last_name] } } }

        specify do
          expect(checker.report).to have_attributes(
            checker_name: checker_name,
            table_or_model_name: klass.name,
            column_or_attribute_name: index_name,
            status: :ok,
            message: nil
          )
        end
      end

      context 'when validation is present another way' do
        let(:klass) { define_class { |klass| klass.validates :first_name, uniqueness: { scope: %i[email last_name] } } }

        specify do
          expect(checker.report).to have_attributes(
            checker_name: checker_name,
            table_or_model_name: klass.name,
            column_or_attribute_name: index_name,
            status: :ok,
            message: nil
          )
        end
      end

      context 'when validation is missing' do
        let(:klass) { define_class { |klass| klass.validates :first_name, uniqueness: { scope: :last_name } } }

        specify do
          expect(checker.report).to have_attributes(
            checker_name: checker_name,
            table_or_model_name: klass.name,
            column_or_attribute_name: index_name,
            status: :fail,
            message: 'index is unique in the database but do not have uniqueness validator'
          )
        end
      end
    end
  end
end
