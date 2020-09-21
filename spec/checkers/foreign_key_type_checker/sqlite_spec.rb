# frozen_string_literal: true

require_relative './context'

RSpec.describe DatabaseConsistency::Checkers::ForeignKeyTypeChecker, sqlite: true do
  subject(:checker) { described_class.new(model, association) }

  let!(:user_class) { define_class('User', :users) }

  let(:model) { company_class }
  let(:association) { company_class.reflect_on_all_associations.first }

  context 'with belongs_to association' do
    let!(:company_class) { define_class('Company', :companies) { |klass| klass.belongs_to :user } }

    let(:associated) { :id }
    let(:base) { :user_id }

    before do
      base = base_type
      associated = associated_type

      define_database do
        create_table :users, id: associated

        create_table :companies do |t|
          t.send(base, :user_id)
        end
      end
    end

    context 'when base key has integer type' do
      let(:base_type) { :integer }

      include_examples 'check matches', %i[serial], %i[bigserial]
    end

    context 'when base key has bigint type' do
      let(:base_type) { :bigint }

      include_examples 'check matches', %i[bigserial], %i[serial]
    end
  end

  context 'with has_one association' do
    let!(:company_class) { define_class('Company', :companies) { |klass| klass.has_one :user } }

    let(:associated) { :company_id }
    let(:base) { :id }

    before do
      base = base_type
      associated = associated_type

      define_database do
        create_table :users do |t|
          t.send(associated, :company_id)
        end

        create_table :companies, id: base
      end
    end

    context 'when base key has serial type' do
      let(:base_type) { :serial }

      include_examples 'check matches', %i[integer], %i[bigint]
    end

    context 'when base key has bigserial type' do
      let(:base_type) { :bigserial }

      include_examples 'check matches', %i[bigint], %i[integer]
    end
  end

  context 'with has_many association' do
    let!(:company_class) { define_class('Company', :companies) { |klass| klass.has_many :users } }

    let(:associated) { :company_id }
    let(:base) { :id }

    before do
      base = base_type
      associated = associated_type

      define_database do
        create_table :users do |t|
          t.send(associated, :company_id)
        end

        create_table :companies, id: base
      end
    end

    context 'when base key has serial type' do
      let(:base_type) { :serial }

      include_examples 'check matches', %i[integer], %i[bigint]
    end

    context 'when base key has bigserial type' do
      let(:base_type) { :bigserial }

      include_examples 'check matches', %i[bigint], %i[integer]
    end
  end
end
