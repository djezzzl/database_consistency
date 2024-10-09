# frozen_string_literal: true

RSpec.describe DatabaseConsistency::Checkers::UniqueIndexChecker, :sqlite, :mysql, :postgresql do
  subject(:checker) { described_class.new(model, index) }

  let(:model) { klass }
  let(:index) { ActiveRecord::Base.connection.indexes(klass.table_name).first }

  let(:checker_name) { described_class.name.demodulize }
  let(:index_name) { 'index_name' }

  context 'when unique index is based on association' do
    before do
      define_database_with_entity do |t|
        t.integer :user_id
        t.integer :post_id

        t.index %i[post_id user_id], unique: true, name: 'index_name'
      end
    end

    context 'when validation is missing' do
      let(:klass) do
        define_class do |klass|
          klass.belongs_to :post
          klass.belongs_to :user
        end
      end

      specify do
        expect(checker.report).to have_attributes(
          checker_name: checker_name,
          table_or_model_name: klass.name,
          column_or_attribute_name: index_name,
          status: :fail,
          error_message: nil,
          error_slug: :missing_uniqueness_validation
        )
      end
    end

    context 'when validation is present' do
      let(:klass) do
        define_class do |klass|
          klass.belongs_to :post
          klass.belongs_to :user

          klass.validates :post, uniqueness: { scope: :user }
        end
      end

      specify do
        expect(checker.report).to have_attributes(
          checker_name: checker_name,
          table_or_model_name: klass.name,
          column_or_attribute_name: index_name,
          status: :ok,
          error_message: nil,
          error_slug: nil
        )
      end
    end
  end

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
          error_message: nil,
          error_slug: nil
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
          error_message: nil,
          error_slug: :missing_uniqueness_validation
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
          error_message: nil,
          error_slug: nil
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
          error_message: nil,
          error_slug: nil
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
          error_message: nil,
          error_slug: :missing_uniqueness_validation
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
          error_message: nil,
          error_slug: nil
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
          error_message: nil,
          error_slug: nil
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
          error_message: nil,
          error_slug: :missing_uniqueness_validation
        )
      end
    end
  end
end
