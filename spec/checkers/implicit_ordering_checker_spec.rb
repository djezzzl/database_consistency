# frozen_string_literal: true

RSpec.describe DatabaseConsistency::Checkers::ImplicitOrderingChecker, :postgresql do
  subject(:checker) { described_class.new(model, column) }

  let(:klass) { define_class { |klass| klass.primary_key = :id } }
  let(:model) { klass }
  let(:column) { klass.columns.first }

  context 'when primary key type is uuid and model defines self.implicit_order_column' do
    before do
      define_database do
        create_table :entities, id: :uuid
      end

      klass.class_eval do
        self.implicit_order_column = :created_at
      end
    end

    specify do
      expect(checker.report).to have_attributes(
        checker_name: 'ImplicitOrderingChecker',
        model_name: klass.name,
        primary_fk_name: 'id',
        status: :ok,
        error_slug: nil,
        error_message: nil
      )
    end
  end

  context 'when primary key type is uuid and model does not define self.implicit_order_column' do
    before do
      define_database do
        create_table :entities, id: :uuid
      end
    end

    specify do
      expect(checker.report).to have_attributes(
        checker_name: 'ImplicitOrderingChecker',
        model_name: klass.name,
        primary_fk_name: 'id',
        status: :fail,
        error_slug: :implicit_order_column_missing,
        error_message: nil
      )
    end
  end

  context 'when primary key type is not uuid' do
    before do
      define_database do
        create_table :entities, id: :bigint
      end
    end

    specify do
      expect(checker.report).to be_nil
    end
  end
end
