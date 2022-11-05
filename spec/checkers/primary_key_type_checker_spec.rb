# frozen_string_literal: true

RSpec.describe DatabaseConsistency::Checkers::PrimaryKeyTypeChecker, :mysql, :postgresql do
  subject(:checker) { described_class.new(model, column) }

  let(:model) { klass }
  let(:column) { klass.columns.first }
  let(:klass) { define_class { |klass| klass.primary_key = :id } }

  context 'when type is bigint' do
    before do
      define_database do
        create_table :entities, id: :bigint
      end
    end

    specify do
      expect(checker.report).to have_attributes(
        checker_name: 'PrimaryKeyTypeChecker',
        table_or_model_name: klass.name,
        column_or_attribute_name: 'id',
        status: :ok,
        error_slug: nil,
        error_message: nil
      )
    end
  end

  context 'when type is int' do
    before do
      define_database do
        create_table :entities, id: :int
      end
    end

    specify do
      expect(checker.report).to have_attributes(
        checker_name: 'PrimaryKeyTypeChecker',
        table_or_model_name: klass.name,
        column_or_attribute_name: 'id',
        status: :fail,
        error_slug: :small_primary_key,
        error_message: nil
      )
    end
  end
end
