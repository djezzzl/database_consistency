# frozen_string_literal: true

RSpec.describe DatabaseConsistency::Checkers::MissingIndexChecker do
  subject(:checker) { described_class.new(model, association) }

  let(:model) { company_class }
  let(:association) { company_class.reflect_on_all_associations.first }

  test_each_database do
    context 'with polymorphic association' do
      let!(:user_class) { define_class('User', :users) { |klass| klass.belongs_to :companable, polymorphic: true } }

      context 'with has_one association' do
        context 'with has_one association' do
          let!(:company_class) { define_class('Company', :companies) { |klass| klass.has_one :user, as: :companable } }

          context 'when index is not provided' do
            before do
              define_database do
                create_table :users do |t|
                  t.integer :companable_id
                  t.string :companable_type
                end

                create_table :companies
              end
            end

            specify do
              expect(checker.report).to have_attributes(
                checker_name: 'MissingIndexChecker',
                table_or_model_name: company_class.name,
                column_or_attribute_name: 'user',
                status: :fail,
                message: 'associated model should have proper index in the database'
              )
            end
          end

          context 'when index is provided' do
            before do
              define_database do
                create_table :users do |t|
                  t.integer :companable_id
                  t.string :companable_type
                  t.index %i[companable_type companable_id]
                end

                create_table :companies
              end
            end

            specify do
              expect(checker.report).to have_attributes(
                checker_name: 'MissingIndexChecker',
                table_or_model_name: company_class.name,
                column_or_attribute_name: 'user',
                status: :ok,
                message: nil
              )
            end
          end
        end
      end
    end

    context 'with simple association' do
      let!(:user_class) { define_class('User', :users) }

      context 'with has_one association' do
        let!(:company_class) { define_class('Company', :companies) { |klass| klass.has_one :user } }

        context 'when index is not provided' do
          before do
            define_database do
              create_table :users do |t|
                t.integer :company_id
              end

              create_table :companies
            end
          end

          specify do
            expect(checker.report).to have_attributes(
              checker_name: 'MissingIndexChecker',
              table_or_model_name: company_class.name,
              column_or_attribute_name: 'user',
              status: :fail,
              message: 'associated model should have proper index in the database'
            )
          end
        end

        context 'when index is provided' do
          before do
            define_database do
              create_table :users do |t|
                t.integer :company_id
                t.index [:company_id]
              end

              create_table :companies
            end
          end

          specify do
            expect(checker.report).to have_attributes(
              checker_name: 'MissingIndexChecker',
              table_or_model_name: company_class.name,
              column_or_attribute_name: 'user',
              status: :ok,
              message: nil
            )
          end
        end
      end

      context 'with has_many association' do
        let!(:company_class) { define_class('Company', :companies) { |klass| klass.has_many :users } }

        context 'when index is not provided' do
          before do
            define_database do
              create_table :users do |t|
                t.integer :company_id
              end

              create_table :companies
            end
          end

          specify do
            expect(checker.report).to have_attributes(
              checker_name: 'MissingIndexChecker',
              table_or_model_name: company_class.name,
              column_or_attribute_name: 'users',
              status: :fail,
              message: 'associated model should have proper index in the database'
            )
          end
        end

        context 'when index is provided' do
          before do
            define_database do
              create_table :users do |t|
                t.integer :company_id
                t.index [:company_id]
              end

              create_table :companies
            end
          end

          specify do
            expect(checker.report).to have_attributes(
              checker_name: 'MissingIndexChecker',
              table_or_model_name: company_class.name,
              column_or_attribute_name: 'users',
              status: :ok,
              message: nil
            )
          end
        end
      end
    end
  end
end
