# frozen_string_literal: true

RSpec.describe DatabaseConsistency::Checkers::ForeignKeyTypeChecker, :postgresql do
  subject(:checker) { described_class.new(model, association) }

  let!(:user_class) { define_class('User', :users) }

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

    context 'when primary key has integer type' do
      let(:primary_key_type) { :integer }

      context 'when foreign key type has integer type' do
        let(:foreign_key_type) { :integer }

        it 'matches' do
          expect(checker.report).to have_attributes(
            checker_name: 'ForeignKeyTypeChecker',
            table_or_model_name: company_class.name,
            column_or_attribute_name: association.name.to_s,
            status: :ok,
            error_message: nil,
            error_slug: nil,
            pk_type: 'integer',
            pk_name: 'id',
            fk_type: 'integer',
            fk_name: 'user_id'
          )
        end
      end

      context 'when foreign key type has bigint type' do
        let(:foreign_key_type) { :bigint }

        it 'matches' do
          expect(checker.report).to have_attributes(
            checker_name: 'ForeignKeyTypeChecker',
            table_or_model_name: company_class.name,
            column_or_attribute_name: association.name.to_s,
            status: :ok,
            error_message: nil,
            error_slug: nil,
            pk_type: 'integer',
            pk_name: 'id',
            fk_type: 'bigint',
            fk_name: 'user_id'
          )
        end
      end
    end

    context 'when primary key has bigint type' do
      let(:primary_key_type) { :bigint }

      context 'when foreign key type has integer type' do
        let(:foreign_key_type) { :integer }

        it 'matches' do
          expect(checker.report).to have_attributes(
            checker_name: 'ForeignKeyTypeChecker',
            table_or_model_name: company_class.name,
            column_or_attribute_name: association.name.to_s,
            status: :ok,
            error_message: nil,
            error_slug: nil,
            pk_type: 'integer',
            pk_name: 'id',
            fk_type: 'integer',
            fk_name: 'user_id'
          )
        end
      end

      context 'when foreign key type has bigint type' do
        let(:foreign_key_type) { :bigint }

        it 'matches' do
          expect(checker.report).to have_attributes(
            checker_name: 'ForeignKeyTypeChecker',
            table_or_model_name: company_class.name,
            column_or_attribute_name: association.name.to_s,
            status: :ok,
            error_message: nil,
            error_slug: nil,
            pk_type: 'integer',
            pk_name: 'id',
            fk_type: 'bigint',
            fk_name: 'user_id'
          )
        end
      end
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

    it 'outputs the missing field error' do
      expect(checker.report).to have_attributes(
        checker_name: 'ForeignKeyTypeChecker',
        table_or_model_name: company_class.name,
        column_or_attribute_name: association.name.to_s,
        status: :fail,
        error_message: 'association (user) of class (Company) relies on field (user_id) of table (companies) but it is missing', # rubocop:disable Layout/LineLength
        error_slug: nil
      )
    end
  end

  context 'with has_one association' do
    let!(:company_class) do
      define_class('Company', :companies) do |klass|
        klass.has_one :user
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

        it 'matches' do
          expect(checker.report).to have_attributes(
            checker_name: 'ForeignKeyTypeChecker',
            table_or_model_name: company_class.name,
            column_or_attribute_name: association.name.to_s,
            status: :ok,
            error_message: nil,
            error_slug: nil,
            pk_type: 'serial',
            pk_name: 'id',
            fk_type: 'integer',
            fk_name: 'company_id'
          )
        end
      end

      context 'when foreign key type has bigint type' do
        let(:foreign_key_type) { :bigint }

        it 'matches' do
          expect(checker.report).to have_attributes(
            checker_name: 'ForeignKeyTypeChecker',
            table_or_model_name: company_class.name,
            column_or_attribute_name: association.name.to_s,
            status: :ok,
            error_message: nil,
            error_slug: nil,
            pk_type: 'serial',
            pk_name: 'id',
            fk_type: 'bigint',
            fk_name: 'company_id'
          )
        end
      end
    end

    context 'when primary key type has bigserial type' do
      let(:primary_key_type) { :bigserial }

      context 'when foreign key type has integer type' do
        let(:foreign_key_type) { :integer }

        it 'mismatches' do
          expect(checker.report).to have_attributes(
            checker_name: 'ForeignKeyTypeChecker',
            table_or_model_name: company_class.name,
            column_or_attribute_name: association.name.to_s,
            status: :fail,
            error_message: nil,
            error_slug: :inconsistent_types,
            pk_type: 'bigserial',
            pk_name: 'id',
            fk_type: 'integer',
            fk_name: 'company_id'
          )
        end
      end

      context 'when foreign key type has bigint type' do
        let(:foreign_key_type) { :bigint }

        it 'matches' do
          expect(checker.report).to have_attributes(
            checker_name: 'ForeignKeyTypeChecker',
            table_or_model_name: company_class.name,
            column_or_attribute_name: association.name.to_s,
            status: :ok,
            error_message: nil,
            error_slug: nil,
            pk_type: 'bigserial',
            pk_name: 'id',
            fk_type: 'bigint',
            fk_name: 'company_id'
          )
        end
      end
    end
  end

  context 'with has_many association' do
    let!(:company_class) do
      define_class('Company', :companies) do |klass|
        klass.has_many :users
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

        it 'matches' do
          expect(checker.report).to have_attributes(
            checker_name: 'ForeignKeyTypeChecker',
            table_or_model_name: company_class.name,
            column_or_attribute_name: association.name.to_s,
            status: :ok,
            error_message: nil,
            error_slug: nil,
            pk_type: 'serial',
            pk_name: 'id',
            fk_type: 'integer',
            fk_name: 'company_id'
          )
        end
      end

      context 'when foreign key type has bigint type' do
        let(:foreign_key_type) { :bigint }

        it 'matches' do
          expect(checker.report).to have_attributes(
            checker_name: 'ForeignKeyTypeChecker',
            table_or_model_name: company_class.name,
            column_or_attribute_name: association.name.to_s,
            status: :ok,
            error_message: nil,
            error_slug: nil,
            pk_type: 'serial',
            pk_name: 'id',
            fk_type: 'bigint',
            fk_name: 'company_id'
          )
        end
      end
    end

    context 'when primary key type has bigserial type' do
      let(:primary_key_type) { :bigserial }

      context 'when foreign key type has integer type' do
        let(:foreign_key_type) { :integer }

        it 'mismatches' do
          expect(checker.report).to have_attributes(
            checker_name: 'ForeignKeyTypeChecker',
            table_or_model_name: company_class.name,
            column_or_attribute_name: association.name.to_s,
            status: :fail,
            error_message: nil,
            error_slug: :inconsistent_types,
            pk_type: 'bigserial',
            pk_name: 'id',
            fk_type: 'integer',
            fk_name: 'company_id'
          )
        end
      end

      context 'when foreign key type has bigint type' do
        let(:foreign_key_type) { :bigint }

        it 'matches' do
          expect(checker.report).to have_attributes(
            checker_name: 'ForeignKeyTypeChecker',
            table_or_model_name: company_class.name,
            column_or_attribute_name: association.name.to_s,
            status: :ok,
            error_message: nil,
            error_slug: nil,
            pk_type: 'bigserial',
            pk_name: 'id',
            fk_type: 'bigint',
            fk_name: 'company_id'
          )
        end
      end
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
      pk_type = primary_key_type
      fk_type = foreign_key_type

      define_database do
        create_table :users do |t|
          t.send(fk_type, :c_id)
        end

        create_table :companies, id: pk_type
      end
    end

    context 'when primary key type has serial type' do
      let(:primary_key_type) { :serial }

      context 'when foreign key type has integer type' do
        let(:foreign_key_type) { :integer }

        it 'matches' do
          expect(checker.report).to have_attributes(
            checker_name: 'ForeignKeyTypeChecker',
            table_or_model_name: company_class.name,
            column_or_attribute_name: association.name.to_s,
            status: :ok,
            error_message: nil,
            error_slug: nil,
            pk_type: 'serial',
            pk_name: 'id',
            fk_type: 'integer',
            fk_name: 'c_id'
          )
        end
      end

      context 'when foreign key type has bigint type' do
        let(:foreign_key_type) { :bigint }

        it 'matches' do
          expect(checker.report).to have_attributes(
            checker_name: 'ForeignKeyTypeChecker',
            table_or_model_name: company_class.name,
            column_or_attribute_name: association.name.to_s,
            status: :ok,
            error_message: nil,
            error_slug: nil,
            pk_type: 'serial',
            pk_name: 'id',
            fk_type: 'bigint',
            fk_name: 'c_id'
          )
        end
      end
    end

    context 'when primary key type has bigserial type' do
      let(:primary_key_type) { :bigserial }

      context 'when foreign key type has integer type' do
        let(:foreign_key_type) { :integer }

        it 'mismatches' do
          expect(checker.report).to have_attributes(
            checker_name: 'ForeignKeyTypeChecker',
            table_or_model_name: company_class.name,
            column_or_attribute_name: association.name.to_s,
            status: :fail,
            error_message: nil,
            error_slug: :inconsistent_types,
            pk_type: 'bigserial',
            pk_name: 'id',
            fk_type: 'integer',
            fk_name: 'c_id'
          )
        end
      end

      context 'when foreign key type has bigint type' do
        let(:foreign_key_type) { :bigint }

        it 'matches' do
          expect(checker.report).to have_attributes(
            checker_name: 'ForeignKeyTypeChecker',
            table_or_model_name: company_class.name,
            column_or_attribute_name: association.name.to_s,
            status: :ok,
            error_message: nil,
            error_slug: nil,
            pk_type: 'bigserial',
            pk_name: 'id',
            fk_type: 'bigint',
            fk_name: 'c_id'
          )
        end
      end
    end
  end

  context 'has_many with custom primary key' do
    before do
      pk_type = primary_key_type
      fk_type = foreign_key_type

      define_database do
        create_table :users do |t|
          t.send(fk_type, :company_code)
        end

        create_table :companies, id: false do |t|
          t.send(pk_type, :code)
        end
      end
    end

    let!(:company_class) do
      define_class('Company', :companies) do |klass|
        klass.has_many :users, class_name: 'User', foreign_key: :company_code, primary_key: :code
      end
    end

    context 'when primary key type has integer type' do
      let(:primary_key_type) { :integer }

      context 'when foreign key type has integer type' do
        let(:foreign_key_type) { :integer }

        it 'matches' do
          expect(checker.report).to have_attributes(
            checker_name: 'ForeignKeyTypeChecker',
            table_or_model_name: company_class.name,
            column_or_attribute_name: association.name.to_s,
            status: :ok,
            error_message: nil,
            error_slug: nil,
            pk_type: 'integer',
            pk_name: 'code',
            fk_type: 'integer',
            fk_name: 'company_code'
          )
        end
      end

      context 'when foreign key type has bigint type' do
        let(:foreign_key_type) { :bigint }

        it 'matches' do
          expect(checker.report).to have_attributes(
            checker_name: 'ForeignKeyTypeChecker',
            table_or_model_name: company_class.name,
            column_or_attribute_name: association.name.to_s,
            status: :ok,
            error_message: nil,
            error_slug: nil,
            pk_type: 'integer',
            pk_name: 'code',
            fk_type: 'bigint',
            fk_name: 'company_code'
          )
        end
      end
    end

    context 'when primary key type has bigint type' do
      let(:primary_key_type) { :bigint }

      context 'when foreign key type has integer type' do
        let(:foreign_key_type) { :integer }

        it 'mismatches' do
          expect(checker.report).to have_attributes(
            checker_name: 'ForeignKeyTypeChecker',
            table_or_model_name: company_class.name,
            column_or_attribute_name: association.name.to_s,
            status: :fail,
            error_message: nil,
            error_slug: :inconsistent_types,
            pk_type: 'bigint',
            pk_name: 'code',
            fk_type: 'integer',
            fk_name: 'company_code'
          )
        end
      end

      context 'when foreign key type has bigint type' do
        let(:foreign_key_type) { :bigint }

        it 'matches' do
          expect(checker.report).to have_attributes(
            checker_name: 'ForeignKeyTypeChecker',
            table_or_model_name: company_class.name,
            column_or_attribute_name: association.name.to_s,
            status: :ok,
            error_message: nil,
            error_slug: nil,
            pk_type: 'bigint',
            pk_name: 'code',
            fk_type: 'bigint',
            fk_name: 'company_code'
          )
        end
      end
    end
  end

  context 'has_one with custom primary key' do
    before do
      pk_type = primary_key_type
      fk_type = foreign_key_type

      define_database do
        create_table :users do |t|
          t.send(fk_type, :company_code)
        end

        create_table :companies, id: false do |t|
          t.send(pk_type, :code)
        end
      end
    end

    let!(:company_class) do
      define_class('Company', :companies) do |klass|
        klass.has_one :user, class_name: 'User', foreign_key: :company_code, primary_key: :code
      end
    end

    context 'when primary key type has integer type' do
      let(:primary_key_type) { :integer }

      context 'when foreign key type has integer type' do
        let(:foreign_key_type) { :integer }

        it 'matches' do
          expect(checker.report).to have_attributes(
            checker_name: 'ForeignKeyTypeChecker',
            table_or_model_name: company_class.name,
            column_or_attribute_name: association.name.to_s,
            status: :ok,
            error_message: nil,
            error_slug: nil,
            pk_type: 'integer',
            pk_name: 'code',
            fk_type: 'integer',
            fk_name: 'company_code'
          )
        end
      end

      context 'when foreign key type has bigint type' do
        let(:foreign_key_type) { :bigint }

        it 'matches' do
          expect(checker.report).to have_attributes(
            checker_name: 'ForeignKeyTypeChecker',
            table_or_model_name: company_class.name,
            column_or_attribute_name: association.name.to_s,
            status: :ok,
            error_message: nil,
            error_slug: nil,
            pk_type: 'integer',
            pk_name: 'code',
            fk_type: 'bigint',
            fk_name: 'company_code'
          )
        end
      end
    end

    context 'when primary key type has bigint type' do
      let(:primary_key_type) { :bigint }

      context 'when foreign key type has integer type' do
        let(:foreign_key_type) { :integer }

        it 'mismatches' do
          expect(checker.report).to have_attributes(
            checker_name: 'ForeignKeyTypeChecker',
            table_or_model_name: company_class.name,
            column_or_attribute_name: association.name.to_s,
            status: :fail,
            error_message: nil,
            error_slug: :inconsistent_types,
            pk_type: 'bigint',
            pk_name: 'code',
            fk_type: 'integer',
            fk_name: 'company_code'
          )
        end
      end

      context 'when foreign key type has bigint type' do
        let(:foreign_key_type) { :bigint }

        it 'matches' do
          expect(checker.report).to have_attributes(
            checker_name: 'ForeignKeyTypeChecker',
            table_or_model_name: company_class.name,
            column_or_attribute_name: association.name.to_s,
            status: :ok,
            error_message: nil,
            error_slug: nil,
            pk_type: 'bigint',
            pk_name: 'code',
            fk_type: 'bigint',
            fk_name: 'company_code'
          )
        end
      end
    end
  end

  context 'belongs_to with custom primary key' do
    before do
      pk_type = primary_key_type
      fk_type = foreign_key_type

      define_database do
        create_table :users, id: false do |t|
          t.send(pk_type, :code)
        end

        create_table :companies do |t|
          t.send(fk_type, :user_code)
        end
      end
    end

    # So far, I  didn't find a way to rewrite `User` global class for `Company`s association
    let!(:user_class) { define_class('User1', :users) { |klass| klass.primary_key = :code } }
    let!(:company_class) do
      define_class('Company', :companies) do |klass|
        klass.belongs_to :user, class_name: 'User1', foreign_key: :user_code
      end
    end

    context 'when primary key type has integer type' do
      let(:primary_key_type) { :integer }

      context 'when foreign key type has integer type' do
        let(:foreign_key_type) { :integer }

        it 'matches' do
          expect(checker.report).to have_attributes(
            checker_name: 'ForeignKeyTypeChecker',
            table_or_model_name: company_class.name,
            column_or_attribute_name: association.name.to_s,
            status: :ok,
            error_message: nil,
            error_slug: nil,
            pk_type: 'integer',
            pk_name: 'code',
            fk_type: 'integer',
            fk_name: 'user_code'
          )
        end
      end

      context 'when foreign key type has bigint type' do
        let(:foreign_key_type) { :bigint }

        it 'matches' do
          expect(checker.report).to have_attributes(
            checker_name: 'ForeignKeyTypeChecker',
            table_or_model_name: company_class.name,
            column_or_attribute_name: association.name.to_s,
            status: :ok,
            error_message: nil,
            error_slug: nil,
            pk_type: 'integer',
            pk_name: 'code',
            fk_type: 'bigint',
            fk_name: 'user_code'
          )
        end
      end
    end

    context 'when primary key type has bigint type' do
      let(:primary_key_type) { :bigint }

      context 'when foreign key type has integer type' do
        let(:foreign_key_type) { :integer }

        it 'mismatches' do
          expect(checker.report).to have_attributes(
            checker_name: 'ForeignKeyTypeChecker',
            table_or_model_name: company_class.name,
            column_or_attribute_name: association.name.to_s,
            status: :fail,
            error_message: nil,
            error_slug: :inconsistent_types,
            pk_type: 'bigint',
            pk_name: 'code',
            fk_type: 'integer',
            fk_name: 'user_code'
          )
        end
      end

      context 'when foreign key type has bigint type' do
        let(:foreign_key_type) { :bigint }

        it 'matches' do
          expect(checker.report).to have_attributes(
            checker_name: 'ForeignKeyTypeChecker',
            table_or_model_name: company_class.name,
            column_or_attribute_name: association.name.to_s,
            status: :ok,
            error_message: nil,
            error_slug: nil,
            pk_type: 'bigint',
            pk_name: 'code',
            fk_type: 'bigint',
            fk_name: 'user_code'
          )
        end
      end
    end
  end
end
