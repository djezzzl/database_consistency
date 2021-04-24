# frozen_string_literal: true

RSpec.describe DatabaseConsistency::Checkers::RedundantUniqueIndexChecker, postgresql: true do
  subject(:checker) { described_class.new(model, index) }

  let(:model) { define_class }
  let(:index) { ActiveRecord::Base.connection.indexes(model.table_name).find { |index| index.name == 'index' } }

  context 'when another index is part of current as prefix' do
    before do
      define_database_with_entity do |table|
        table.string :first_name
        table.string :second_name
        table.index %i[first_name], name: 'another_index', unique: true
        table.index %i[first_name second_name], name: 'index', unique: true
      end
    end

    specify do
      expect(checker.report)
        .to have_attributes(
          checker_name: 'RedundantUniqueIndexChecker',
          table_or_model_name: model.name,
          column_or_attribute_name: 'index',
          status: :fail,
          message: 'index uniqueness is redundant as (another_index) covers it'
        )
    end
  end

  context 'when another index has partial overlap only' do
    before do
      define_database_with_entity do |table|
        table.string :first_name
        table.string :second_name
        table.string :email
        table.index %i[first_name email], name: 'another_index', unique: true
        table.index %i[first_name second_name], name: 'index', unique: true
      end
    end

    specify do
      expect(checker.report)
        .to have_attributes(
          checker_name: 'RedundantUniqueIndexChecker',
          table_or_model_name: model.name,
          column_or_attribute_name: 'index',
          status: :ok,
          message: nil
        )
    end
  end

  context 'when another index is part of current as suffix' do
    before do
      define_database_with_entity do |table|
        table.string :first_name
        table.string :second_name
        table.index %i[first_name], name: 'another_index', unique: true
        table.index %i[second_name first_name], name: 'index', unique: true
      end
    end

    specify do
      expect(checker.report)
        .to have_attributes(
          checker_name: 'RedundantUniqueIndexChecker',
          table_or_model_name: model.name,
          column_or_attribute_name: 'index',
          status: :fail,
          message: 'index uniqueness is redundant as (another_index) covers it'
        )
    end
  end

  context 'when current index is not unique' do
    before do
      define_database_with_entity do |table|
        table.string :first_name
        table.string :second_name
        table.index %i[first_name], name: 'index'
        table.index %i[second_name first_name], name: 'another_index', unique: true
      end
    end

    specify do
      expect(checker.report).to be_nil
    end
  end

  context 'when another index is not unique' do
    before do
      define_database_with_entity do |table|
        table.string :first_name
        table.string :second_name
        table.index %i[first_name], name: 'another_index'
        table.index %i[second_name first_name], name: 'index', unique: true
      end
    end

    specify do
      expect(checker.report)
        .to have_attributes(
          checker_name: 'RedundantUniqueIndexChecker',
          table_or_model_name: model.name,
          column_or_attribute_name: 'index',
          status: :ok,
          message: nil
        )
    end
  end
end
