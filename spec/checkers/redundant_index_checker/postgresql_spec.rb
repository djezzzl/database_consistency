# frozen_string_literal: true

RSpec.describe DatabaseConsistency::Checkers::RedundantIndexChecker, :postgresql do
  subject(:checker) { described_class.new(model, index) }

  let(:model) { define_class }
  let(:index) { ActiveRecord::Base.connection.indexes(model.table_name).find { |index| index.name == 'index' } }

  context "when index isn't btree type" do
    before do
      define_database_with_entity do |table|
        table.string :first_name
        table.string :second_name
        table.index %i[first_name], name: 'index', using: :hash
        table.index %i[first_name second_name], name: 'another_index', using: :btree
      end
    end

    specify do
      expect(checker.report).to be_nil
    end
  end

  context "when covered index isn't btree type" do
    before do
      define_database_with_entity do |table|
        table.string :first_name
        table.string :second_name
        table.index %i[first_name], name: 'index', using: :btree
        table.index %i[first_name second_name], name: 'another_index', using: :gin
      end
    end

    specify do
      expect(checker.report).to have_attributes(
        checker_name: 'RedundantIndexChecker',
        table_or_model_name: model.name,
        column_or_attribute_name: 'index',
        status: :ok,
        error_message: nil,
        error_slug: nil
      )
    end
  end

  context 'when another index includes current as prefix' do
    before do
      define_database_with_entity do |table|
        table.string :first_name
        table.string :second_name
        table.index %i[first_name], name: 'index'
        table.index %i[first_name second_name], name: 'another_index'
      end
    end

    specify do
      expect(checker.report)
        .to have_attributes(
          checker_name: 'RedundantIndexChecker',
          table_or_model_name: model.name,
          column_or_attribute_name: 'index',
          status: :fail,
          error_message: nil,
          error_slug: :redundant_index,
          index_name: 'index',
          covered_index_name: 'another_index'
        )
    end
  end

  context 'when another index has different where clause' do
    before do
      define_database_with_entity do |table|
        table.string :first_name
        table.string :second_name
        table.index %i[first_name], name: 'index'
        table.index %i[first_name second_name], name: 'another_index', where: 'first_name IS NULL'
      end
    end

    specify do
      expect(checker.report)
        .to have_attributes(
          checker_name: 'RedundantIndexChecker',
          table_or_model_name: model.name,
          column_or_attribute_name: 'index',
          status: :ok,
          error_message: nil,
          error_slug: nil
        )
    end
  end

  context 'when another index is bigger than current' do
    before do
      define_database_with_entity do |table|
        table.string :first_name
        table.string :second_name
        table.index %i[first_name], name: 'another_index'
        table.index %i[first_name second_name], name: 'index'
      end
    end

    specify do
      expect(checker.report)
        .to have_attributes(
          checker_name: 'RedundantIndexChecker',
          table_or_model_name: model.name,
          column_or_attribute_name: 'index',
          status: :ok,
          error_message: nil,
          error_slug: nil
        )
    end
  end

  context 'when another index includes current but not as prefix' do
    before do
      define_database_with_entity do |table|
        table.string :first_name
        table.string :second_name
        table.index %i[first_name], name: 'index'
        table.index %i[second_name first_name], name: 'another_index'
      end
    end

    specify do
      expect(checker.report)
        .to have_attributes(
          checker_name: 'RedundantIndexChecker',
          table_or_model_name: model.name,
          column_or_attribute_name: 'index',
          status: :ok,
          error_message: nil,
          error_slug: nil
        )
    end
  end

  context 'when current index is unique' do
    before do
      define_database_with_entity do |table|
        table.string :first_name
        table.string :second_name
        table.index %i[first_name], name: 'index', unique: true
        table.index %i[second_name first_name], name: 'another_index'
      end
    end

    specify do
      expect(checker.report).to be_nil
    end
  end
end
