# frozen_string_literal: true

RSpec.describe DatabaseConsistency::Checkers::MissingTableChecker, :sqlite, :mysql, :postgresql do
  subject(:checker) { described_class.new(model) }

  let(:model) { klass }

  before do
    define_database do
      create_table :entities

      create_table :entities_users do |t|
        t.belongs_to :entity
        t.belongs_to :user
      end

      create_table :users
    end
  end

  context 'with table' do
    let(:klass) { define_class }

    specify do
      expect(checker.report).to have_attributes(
        checker_name: 'MissingTableChecker',
        table_or_model_name: klass.name,
        column_or_attribute_name: 'self',
        status: :ok,
        error_slug: nil,
        error_message: nil
      )
    end
  end

  context 'without table' do
    let(:klass) { define_class('Something', :something) }

    specify do
      expect(checker.report).to have_attributes(
        checker_name: 'MissingTableChecker',
        table_or_model_name: klass.name,
        column_or_attribute_name: 'self',
        status: :fail,
        error_slug: :missing_table,
        error_message: nil
      )
    end
  end

  context 'with abstract class' do
    let(:klass) { define_class { |klass| klass.abstract_class = true } }

    specify do
      expect(checker.report).to be_nil
    end
  end
end
