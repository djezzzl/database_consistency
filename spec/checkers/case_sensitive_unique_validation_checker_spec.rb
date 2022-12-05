# frozen_string_literal: true

RSpec.describe DatabaseConsistency::Checkers::CaseSensitiveUniqueValidationChecker, :postgresql do
  before do
    if ActiveRecord::VERSION::MAJOR < 5
      skip('Uniqueness validation with "case sensitive: false" is supported only by ActiveRecord >= 5')
    end
  end

  subject(:checker) { described_class.new(model, attribute, validator) }

  let(:model) { klass }
  let(:attribute) { :email }
  let(:validator) { klass.validators.first }

  before do
    define_database do
      enable_extension 'citext'

      create_table :entities do |t|
        t.citext :email
      end
    end
  end

  context 'when uniqueness validation has case sensitive option turned off' do
    let(:klass) { define_class { |klass| klass.validates :email, uniqueness: { case_sensitive: false } } }

    specify do
      expect(checker.report).to have_attributes(
        checker_name: 'CaseSensitiveUniqueValidationChecker',
        table_or_model_name: klass.name,
        column_or_attribute_name: 'email',
        status: :fail,
        error_message: nil,
        error_slug: :redundant_case_insensitive_option
      )
    end
  end

  context 'when uniqueness validation has case sensitive option turned on' do
    let(:klass) { define_class { |klass| klass.validates :email, uniqueness: { case_sensitive: true } } }

    specify do
      expect(checker.report).to have_attributes(
        checker_name: 'CaseSensitiveUniqueValidationChecker',
        table_or_model_name: klass.name,
        column_or_attribute_name: 'email',
        status: :ok,
        error_message: nil,
        error_slug: nil
      )
    end
  end

  context 'when uniqueness validation has case sensitive option is not specified' do
    let(:klass) { define_class { |klass| klass.validates :email, uniqueness: true } }

    specify do
      expect(checker.report).to have_attributes(
        checker_name: 'CaseSensitiveUniqueValidationChecker',
        table_or_model_name: klass.name,
        column_or_attribute_name: 'email',
        status: :ok,
        error_message: nil,
        error_slug: nil
      )
    end
  end
end
