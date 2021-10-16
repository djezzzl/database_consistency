# frozen_string_literal: true

RSpec.describe DatabaseConsistency::Checkers::MissingNotNullConstraintChecker do
  subject(:checker) { described_class.new(model, column) }

  let(:model) { book_class }
  let(:column) { model.columns.first }

  before do
    skip('older versions are not supported') if ActiveRecord::VERSION::MAJOR < 5
  end

  test_each_database do
    context 'when NOT NULL is missing' do
      before do
        define_database do
          create_table(:authors)
          create_table(:books, id: false) do |books|
            books.bigint :author_id, null: true
            books.foreign_key :authors
          end
        end
      end

      context 'when `belongs_to` is `optional: false`' do
        let(:book_class) do
          define_class('Book', :books) do |book|
            book.belongs_to :author, optional: false
          end
        end

        it 'detects an inconsistency' do
          expect(checker.report(false)).to have_attributes(
            checker_name: 'MissingNotNullConstraintChecker',
            table_or_model_name: book_class.name,
            column_or_attribute_name: 'author_id',
            status: :fail,
            message: 'FK allows for null in the database, but is required in the model'
          )
        end
      end

      context 'when `belongs_to` is `optional: true`' do
        let(:book_class) do
          define_class('Book', :books) do |book|
            book.belongs_to :author, optional: true
          end
        end

        it 'passes' do
          expect(checker.report(false)).to be_nil
        end
      end
    end

    context 'when NOT NULL is present' do
      before do
        define_database do
          create_table(:authors)
          create_table(:books, id: false) do |books|
            books.bigint :author_id, null: false
            books.foreign_key :authors
          end
        end
      end

      let(:book_class) do
        define_class('Book', :books) do |book|
          book.belongs_to :author, optional: false
        end
      end

      it 'passes' do
        expect(checker.report(false)).to be_nil
      end
    end

    context 'when FK column name is different from association name' do
      before do
        define_database do
          create_table(:users)
          create_table(:books, id: false) do |books|
            books.bigint :author_id, null: true
            books.foreign_key :users, column: :author_id
          end
        end

        define_class('User', :users)
      end

      let(:book_class) do
        define_class('Book', :books) do |book|
          book.belongs_to :author, class_name: 'User', optional: false
        end
      end

      it 'detects an inconsistency' do
        expect(checker.report(false)).to have_attributes(
          checker_name: 'MissingNotNullConstraintChecker',
          table_or_model_name: book_class.name,
          column_or_attribute_name: 'author_id',
          status: :fail,
          message: 'FK allows for null in the database, but is required in the model'
        )
      end
    end

    context 'when FK is not defined and NOT NULL is missing' do
      before do
        define_database do
          create_table(:authors)
          create_table(:books, id: false) do |books|
            books.bigint :author_id, null: true
          end
        end
      end

      let(:book_class) do
        define_class('Book', :books) do |book|
          book.belongs_to :author, optional: false
        end
      end

      it 'passes (other checker takes care of this case)' do
        expect(checker.report(false)).to be_nil
      end
    end
  end
end
