# frozen_string_literal: true

RSpec.describe DatabaseConsistency::Checkers::MissingAssociationClassChecker, :sqlite, :mysql, :postgresql do
  subject(:checker) { described_class.new(model, association) }

  let(:model) { entity_class }
  let(:association) { entity_class.reflect_on_all_associations.first }

  before do
    define_database_with_entity do |table|
      table.integer :something_id
    end
  end

  shared_context 'with class' do
    before { stub_const('Something', Class.new(ActiveRecord::Base)) }
  end

  context 'with polymorphic association' do
    let!(:entity_class) { define_class('Entity', :entities) { |klass| klass.belongs_to :something, polymorphic: true } }

    it 'is not supported' do
      expect(checker.report).to be_nil
    end
  end

  context 'with belongs_to association' do
    let!(:entity_class) { define_class('Entity', :entities) { |klass| klass.belongs_to :something } }

    context 'when class exists' do
      include_context 'with class'

      specify do
        expect(checker.report).to have_attributes(
          checker_name: 'MissingAssociationClassChecker',
          table_or_model_name: model.name,
          column_or_attribute_name: association.name.to_s,
          status: :ok,
          error_message: nil,
          error_slug: nil,
          class_name: 'Something'
        )
      end
    end

    context 'when class is missing' do
      specify do
        expect(checker.report).to have_attributes(
          checker_name: 'MissingAssociationClassChecker',
          table_or_model_name: model.name,
          column_or_attribute_name: association.name.to_s,
          status: :fail,
          error_message: nil,
          error_slug: :missing_association_class,
          class_name: 'Something'
        )
      end
    end
  end

  context 'with has_one association' do
    let!(:entity_class) { define_class('Entity', :entities) { |klass| klass.has_one :something } }

    context 'when class exists' do
      include_context 'with class'

      specify do
        expect(checker.report).to have_attributes(
          checker_name: 'MissingAssociationClassChecker',
          table_or_model_name: model.name,
          column_or_attribute_name: association.name.to_s,
          status: :ok,
          error_message: nil,
          error_slug: nil,
          class_name: 'Something'
        )
      end
    end

    context 'when class is missing' do
      specify do
        expect(checker.report).to have_attributes(
          checker_name: 'MissingAssociationClassChecker',
          table_or_model_name: model.name,
          column_or_attribute_name: association.name.to_s,
          status: :fail,
          error_message: nil,
          error_slug: :missing_association_class,
          class_name: 'Something'
        )
      end
    end
  end

  context 'with has_many association' do
    let!(:entity_class) { define_class('Entity', :entities) { |klass| klass.has_many :something } }

    context 'when class exists' do
      include_context 'with class'

      specify do
        expect(checker.report).to have_attributes(
          checker_name: 'MissingAssociationClassChecker',
          table_or_model_name: model.name,
          column_or_attribute_name: association.name.to_s,
          status: :ok,
          error_message: nil,
          error_slug: nil,
          class_name: 'Something'
        )
      end
    end

    context 'when class is missing' do
      specify do
        expect(checker.report).to have_attributes(
          checker_name: 'MissingAssociationClassChecker',
          table_or_model_name: model.name,
          column_or_attribute_name: association.name.to_s,
          status: :fail,
          error_message: nil,
          error_slug: :missing_association_class,
          class_name: 'Something'
        )
      end
    end
  end

  context 'with has many through association' do
    let!(:entity_class) do
      define_class('Entity', :entities) do |klass|
        klass.has_one :something, through: :user
        klass.has_one :user
      end
    end

    let!(:user_class) do
      define_class('User') do |klass|
        klass.has_one :something
      end
    end

    context 'when class exists' do
      include_context 'with class'

      specify do
        expect(checker.report).to have_attributes(
          checker_name: 'MissingAssociationClassChecker',
          table_or_model_name: model.name,
          column_or_attribute_name: association.name.to_s,
          status: :ok,
          error_message: nil,
          error_slug: nil,
          class_name: 'Something'
        )
      end
    end

    context 'when class is missing' do
      specify do
        expect(checker.report).to have_attributes(
          checker_name: 'MissingAssociationClassChecker',
          table_or_model_name: model.name,
          column_or_attribute_name: association.name.to_s,
          status: :fail,
          error_message: nil,
          error_slug: :missing_association_class,
          class_name: 'Something'
        )
      end
    end
  end

  context 'with has_and_belongs_to_many association' do
    let!(:entity_class) { define_class('Entity', :entities) { |klass| klass.has_and_belongs_to_many :something } }

    context 'when class exists' do
      include_context 'with class'

      specify do
        expect(checker.report).to have_attributes(
          checker_name: 'MissingAssociationClassChecker',
          table_or_model_name: model.name,
          column_or_attribute_name: association.name.to_s,
          status: :ok,
          error_message: nil,
          error_slug: nil,
          class_name: 'Something'
        )
      end
    end

    context 'when class is missing' do
      specify do
        expect(checker.report).to have_attributes(
          checker_name: 'MissingAssociationClassChecker',
          table_or_model_name: model.name,
          column_or_attribute_name: association.name.to_s,
          status: :fail,
          error_message: nil,
          error_slug: :missing_association_class,
          class_name: 'Something'
        )
      end
    end
  end
end
