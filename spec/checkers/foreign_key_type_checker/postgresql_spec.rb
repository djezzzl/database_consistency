# frozen_string_literal: true

require_relative './context'

RSpec.describe DatabaseConsistency::Checkers::ForeignKeyTypeChecker, postgresql: true do
  subject(:checker) { described_class.new(model, association) }

  let!(:user_class) { define_class('User', :users) }

  let(:model) { company_class }
  let(:association) { company_class.reflect_on_all_associations.first }

  context 'with belongs_to association' do
    let!(:company_class) { define_class('Company', :companies) { |klass| klass.belongs_to :user } }

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

  context 'when field is missing' do
    let!(:company_class) { define_class('Company', :companies) { |klass| klass.belongs_to :user } }

    before do
      define_database do
        create_table :users
        create_table :companies
      end
    end

    it 'raises the missing field error' do
      expect { checker.report(false) }.to raise_error(DatabaseConsistency::Errors::MissingField)
    end
  end

  context 'with has_one association' do
    let!(:company_class) { define_class('Company', :companies) { |klass| klass.has_one :user } }

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

  context 'with has many through association' do
    let!(:users_company_class) do
      define_class('UsersCompany', :users_companies) do |klass|
        klass.belongs_to :user
        klass.belongs_to :company
      end
    end
    let!(:company_class) do
      define_class('Company', :companies) do |klass|
        klass.has_many :users_companies
        klass.has_many :users, through: :users_companies
      end
    end

    let(:association) { company_class.reflect_on_association(:users) }

    before do
      define_database do
        create_table :users

        create_table :users_companies do |t|
          t.integer :user_id
          t.integer :company_id
        end

        create_table :companies
      end
    end

    it 'is not supported' do
      expect(checker.report).to be_nil
    end
  end

  context 'with has_and_belongs_to_many association' do
    let!(:company_class) do
      define_class('Company', :companies) do |klass|
        klass.has_and_belongs_to_many :users
      end
    end

    before do
      define_database do
        create_table :users

        create_table :users_companies do |t|
          t.integer :user_id
          t.integer :company_id
        end

        create_table :companies
      end
    end

    it 'is not supported' do
      expect(checker.report).to be_nil
    end
  end

  context 'with custom foreign_key' do
    let!(:company_class) { define_class('Company', :companies) { |klass| klass.has_many :users, foreign_key: :c_id } }

    before do
      base = base_type
      associated = associated_type

      define_database do
        create_table :users do |t|
          t.send(associated, :c_id)
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

  context 'has_many with custom primary key' do
    before do
      base = base_type
      associated = associated_type

      define_database do
        create_table :users do |t|
          t.send(associated, :company_code)
        end

        create_table :companies, id: false do |t|
          t.send(base, :code)
        end
      end
    end

    let!(:company_class) { define_class('Company', :companies) { |klass| klass.has_many :users, class_name: 'User', foreign_key: :company_code, primary_key: :code } }

    context 'when base key has integer type' do
      let(:base_type) { :integer }

      include_examples 'check matches', %i[integer], %i[bigint]
    end

    context 'when base key has bigint type' do
      let(:base_type) { :bigint }

      include_examples 'check matches', %i[bigint], %i[integer]
    end
  end

  context 'has_one with custom primary key' do
    before do
      base = base_type
      associated = associated_type

      define_database do
        create_table :users do |t|
          t.send(associated, :company_code)
        end

        create_table :companies, id: false do |t|
          t.send(base, :code)
        end
      end
    end

    let!(:company_class) { define_class('Company', :companies) { |klass| klass.has_one :user, class_name: 'User', foreign_key: :company_code, primary_key: :code } }

    context 'when base key has integer type' do
      let(:base_type) { :integer }

      include_examples 'check matches', %i[integer], %i[bigint]
    end

    context 'when base key has bigint type' do
      let(:base_type) { :bigint }

      include_examples 'check matches', %i[bigint], %i[integer]
    end
  end

  context 'belongs_to with custom primary key' do
    before do
      base = base_type
      associated = associated_type

      define_database do
        create_table :users, id: false do |t|
          t.send(associated, :code)
        end

        create_table :companies do |t|
          t.send(base, :user_code)
        end
      end
    end

    # So far, I  didn't find a way to rewrite `User` global class for `Company`s association
    let!(:user_class) { define_class('User1', :users) { |klass| klass.primary_key = :code } }
    let!(:company_class) { define_class('Company', :companies) { |klass| klass.belongs_to :user, class_name: 'User1', foreign_key: :user_code } }

    context 'when base key has integer type' do
      let(:base_type) { :integer }

      include_examples 'check matches', %i[integer], %i[bigint]
    end

    context 'when base key has bigint type' do
      let(:base_type) { :bigint }

      include_examples 'check matches', %i[bigint], %i[integer]
    end
  end
end
