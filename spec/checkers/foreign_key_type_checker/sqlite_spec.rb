# frozen_string_literal: true

require_relative './context'

RSpec.describe DatabaseConsistency::Checkers::ForeignKeyTypeChecker, sqlite: true do
  subject(:checker) { described_class.new(model, association) }

  let!(:user_class) { define_class('User', :users) { |klass| klass.primary_key = :id } }

  let(:model) { company_class }
  let(:association) { company_class.reflect_on_all_associations.first }

  context 'with belongs_to association' do
    let!(:company_class) { define_class('Company', :companies) { |klass| klass.belongs_to :user } }

    before do
      pk_type = primary_key_type
      fk_type = foreign_key_type

      define_database do
        create_table :users, id: pk_type

        create_table :companies do |t|
          t.send(fk_type, :user_id)
        end
      end
    end

    context 'when primary key has serial type' do
      let(:primary_key_type) { :serial }

      context 'when foreign key type has integer type' do
        let(:foreign_key_type) { :integer }

        include_examples 'match'
      end

      context 'when foreign key type has bigint type' do
        let(:foreign_key_type) { :bigint }

        include_examples 'match'
      end
    end

    context 'when primary key has bigserial type' do
      let(:primary_key_type) { :bigserial }

      context 'when foreign key type has integer type' do
        let(:foreign_key_type) { :integer }

        include_examples 'mismatch'
      end

      context 'when foreign key type has bigint type' do
        let(:foreign_key_type) { :bigint }

        include_examples 'match'
      end
    end
  end

  context 'with has_one association' do
    let!(:company_class) do
      define_class('Company', :companies) do |klass|
        klass.has_one :user
        # This is required for Rails 4
        klass.primary_key = :id
      end
    end

    before do
      pk_type = primary_key_type
      fk_type = foreign_key_type

      define_database do
        create_table :users do |t|
          t.send(fk_type, :company_id)
        end

        create_table :companies, id: pk_type
      end
    end

    context 'when primary key type has serial type' do
      let(:primary_key_type) { :serial }

      context 'when foreign key type has integer type' do
        let(:foreign_key_type) { :integer }

        include_examples 'match'
      end

      context 'when foreign key type has bigint type' do
        let(:foreign_key_type) { :bigint }

        include_examples 'match'
      end
    end

    context 'when primary key type has bigserial type' do
      let(:primary_key_type) { :bigserial }

      context 'when foreign key type has integer type' do
        let(:foreign_key_type) { :integer }

        include_examples 'mismatch'
      end

      context 'when foreign key type has bigint type' do
        let(:foreign_key_type) { :bigint }

        include_examples 'match'
      end
    end
  end

  context 'with has_many association' do
    let!(:company_class) do
      define_class('Company', :companies) do |klass|
        klass.has_many :users
        # This is required for Rails 4
        klass.primary_key = :id
      end
    end

    before do
      pk_type = primary_key_type
      fk_type = foreign_key_type

      define_database do
        create_table :users do |t|
          t.send(fk_type, :company_id)
        end

        create_table :companies, id: pk_type
      end
    end

    context 'when primary key type has serial type' do
      let(:primary_key_type) { :serial }

      context 'when foreign key type has integer type' do
        let(:foreign_key_type) { :integer }

        include_examples 'match'
      end

      context 'when foreign key type has bigint type' do
        let(:foreign_key_type) { :bigint }

        include_examples 'match'
      end
    end

    context 'when primary key type has bigserial type' do
      let(:primary_key_type) { :bigserial }

      context 'when foreign key type has integer type' do
        let(:foreign_key_type) { :integer }

        include_examples 'mismatch'
      end

      context 'when foreign key type has bigint type' do
        let(:foreign_key_type) { :bigint }

        include_examples 'match'
      end
    end
  end
end
