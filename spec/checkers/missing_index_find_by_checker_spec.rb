# frozen_string_literal: true

require 'tempfile'

RSpec.describe DatabaseConsistency::Checkers::MissingIndexFindByChecker, :sqlite, :mysql, :postgresql do
  subject(:checker) { described_class.new(model, column) }

  let(:model) { klass }
  let(:klass) { define_class }
  let(:column) { klass.columns.find { |c| c.name == 'email' } }

  after do
    if DatabaseConsistency::PrismHelper.instance_variable_defined?(:@find_by_calls_index)
      DatabaseConsistency::PrismHelper.remove_instance_variable(:@find_by_calls_index)
    end
  end

  context 'when Prism is not available' do
    before do
      define_database_with_entity do |t|
        t.string :email
      end
      hide_const('Prism')
    end

    it 'skips the check' do
      expect(checker.report).to be_nil
    end
  end

  context 'when no project source files are found' do
    before do
      define_database_with_entity do |t|
        t.string :email
      end
    end

    it 'skips the check' do
      allow(DatabaseConsistency::FilesHelper).to receive(:project_source_files).and_return([])
      expect(checker.report).to be_nil
    end
  end

  context 'when column is not referenced in any find_by call in the project' do
    before do
      skip 'Prism not available (Ruby < 3.3)' unless defined?(Prism)
      define_database_with_entity do |t|
        t.string :email
      end
    end

    it 'skips the check' do
      Tempfile.create(['entity', '.rb']) do |f|
        f.write("Entity.find_by_name(x)\n")
        f.flush
        allow(DatabaseConsistency::FilesHelper).to receive(:project_source_files).and_return([f.path])
        expect(checker.report).to be_nil
      end
    end
  end

  context 'when column is used via dynamic finder (find_by_column_name)' do
    context 'when index is missing' do
      before do
        skip 'Prism not available (Ruby < 3.3)' unless defined?(Prism)
        define_database_with_entity do |t|
          t.string :email
        end
      end

      specify do
        Tempfile.create(['entity', '.rb']) do |f|
          f.write("Entity.find_by_email(x)\n")
          f.flush
          allow(DatabaseConsistency::FilesHelper).to receive(:project_source_files).and_return([f.path])
          expect(checker.report).to have_attributes(
            checker_name: 'MissingIndexFindByChecker',
            table_or_model_name: klass.name,
            column_or_attribute_name: 'email',
            status: :fail,
            error_slug: :missing_index_find_by,
            source_location: "#{f.path}:1",
            total_findings_count: 1
          )
        end
      end
    end

    context 'when index is present' do
      before do
        skip 'Prism not available (Ruby < 3.3)' unless defined?(Prism)
        define_database_with_entity do |t|
          t.string :email, index: true
        end
      end

      specify do
        Tempfile.create(['entity', '.rb']) do |f|
          f.write("Entity.find_by_email(x)\n")
          f.flush
          allow(DatabaseConsistency::FilesHelper).to receive(:project_source_files).and_return([f.path])
          expect(checker.report).to have_attributes(
            checker_name: 'MissingIndexFindByChecker',
            table_or_model_name: klass.name,
            column_or_attribute_name: 'email',
            status: :ok,
            error_slug: nil,
            source_location: nil,
            total_findings_count: nil
          )
        end
      end
    end

    context 'when a multi-column index exists but column is not first' do
      before do
        skip 'Prism not available (Ruby < 3.3)' unless defined?(Prism)
        define_database do
          create_table(:entities, id: false) do |t|
            t.string :email
            t.string :name
          end
          add_index :entities, %i[name email]
        end
      end

      specify do
        Tempfile.create(['entity', '.rb']) do |f|
          f.write("Entity.find_by_email(x)\n")
          f.flush
          allow(DatabaseConsistency::FilesHelper).to receive(:project_source_files).and_return([f.path])
          expect(checker.report).to have_attributes(status: :fail, error_slug: :missing_index_find_by,
                                                    source_location: "#{f.path}:1")
        end
      end
    end
  end

  context 'when column is used via bang dynamic finder (find_by_column_name!)' do
    context 'when index is missing' do
      before do
        skip 'Prism not available (Ruby < 3.3)' unless defined?(Prism)
        define_database_with_entity do |t|
          t.string :email
        end
      end

      specify do
        Tempfile.create(['entity', '.rb']) do |f|
          f.write("Entity.find_by_email!(x)\n")
          f.flush
          allow(DatabaseConsistency::FilesHelper).to receive(:project_source_files).and_return([f.path])
          expect(checker.report).to have_attributes(
            checker_name: 'MissingIndexFindByChecker',
            column_or_attribute_name: 'email',
            status: :fail,
            error_slug: :missing_index_find_by,
            source_location: "#{f.path}:1"
          )
        end
      end
    end
  end

  context 'when column is used via hash-style finder (find_by(column: ...))' do
    context 'when index is missing' do
      before do
        skip 'Prism not available (Ruby < 3.3)' unless defined?(Prism)
        define_database_with_entity do |t|
          t.string :email
        end
      end

      specify do
        Tempfile.create(['entity', '.rb']) do |f|
          f.write("Entity.find_by(email: x)\n")
          f.flush
          allow(DatabaseConsistency::FilesHelper).to receive(:project_source_files).and_return([f.path])
          expect(checker.report).to have_attributes(
            checker_name: 'MissingIndexFindByChecker',
            table_or_model_name: klass.name,
            column_or_attribute_name: 'email',
            status: :fail,
            error_slug: :missing_index_find_by,
            source_location: "#{f.path}:1"
          )
        end
      end
    end

    context 'when column is referenced only via another model' do
      before do
        skip 'Prism not available (Ruby < 3.3)' unless defined?(Prism)
        define_database_with_entity do |t|
          t.string :email
        end
      end

      it 'skips the check' do
        Tempfile.create(['other', '.rb']) do |f|
          f.write("OtherModel.find_by(email: x)\n")
          f.flush
          allow(DatabaseConsistency::FilesHelper).to receive(:project_source_files).and_return([f.path])
          expect(checker.report).to be_nil
        end
      end
    end

    context 'when column is referenced only via a complex scope (model.where(...))' do
      before do
        skip 'Prism not available (Ruby < 3.3)' unless defined?(Prism)
        define_database_with_entity do |t|
          t.string :email
        end
      end

      it 'skips the check' do
        Tempfile.create(['entity', '.rb']) do |f|
          f.write("Entity.where(active: true).find_by(email: x)\n")
          f.flush
          allow(DatabaseConsistency::FilesHelper).to receive(:project_source_files).and_return([f.path])
          expect(checker.report).to be_nil
        end
      end
    end

    context 'when find_by has multiple keys in the hash' do
      before do
        skip 'Prism not available (Ruby < 3.3)' unless defined?(Prism)
        define_database_with_entity do |t|
          t.string :email
        end
      end

      it 'skips the check' do
        Tempfile.create(['entity', '.rb']) do |f|
          f.write("Entity.find_by(email: x, name: y)\n")
          f.flush
          allow(DatabaseConsistency::FilesHelper).to receive(:project_source_files).and_return([f.path])
          expect(checker.report).to be_nil
        end
      end
    end
  end

  context 'when column is used via no-parens finder (find_by column: ...)' do
    context 'when index is missing' do
      before do
        skip 'Prism not available (Ruby < 3.3)' unless defined?(Prism)
        define_database_with_entity do |t|
          t.string :email
        end
      end

      specify do
        Tempfile.create(['entity', '.rb']) do |f|
          f.write("Entity.find_by email: x\n")
          f.flush
          allow(DatabaseConsistency::FilesHelper).to receive(:project_source_files).and_return([f.path])
          expect(checker.report).to have_attributes(
            checker_name: 'MissingIndexFindByChecker',
            column_or_attribute_name: 'email',
            status: :fail,
            error_slug: :missing_index_find_by,
            source_location: "#{f.path}:1"
          )
        end
      end
    end
  end

  context 'when column is used via string-key finder (find_by("column" => ...))' do
    context 'when index is missing' do
      before do
        skip 'Prism not available (Ruby < 3.3)' unless defined?(Prism)
        define_database_with_entity do |t|
          t.string :email
        end
      end

      specify do
        Tempfile.create(['entity', '.rb']) do |f|
          f.write("Entity.find_by('email' => x)\n")
          f.flush
          allow(DatabaseConsistency::FilesHelper).to receive(:project_source_files).and_return([f.path])
          expect(checker.report).to have_attributes(
            checker_name: 'MissingIndexFindByChecker',
            table_or_model_name: klass.name,
            column_or_attribute_name: 'email',
            status: :fail,
            error_slug: :missing_index_find_by,
            source_location: "#{f.path}:1"
          )
        end
      end
    end
  end

  context 'when column is used via bare find_by inside the model class' do
    context 'when index is missing' do
      before do
        skip 'Prism not available (Ruby < 3.3)' unless defined?(Prism)
        define_database_with_entity do |t|
          t.string :email
        end
      end

      specify do
        Tempfile.create(['entity', '.rb']) do |f|
          f.write("class Entity\n  find_by(email: x)\nend\n")
          f.flush
          allow(DatabaseConsistency::FilesHelper).to receive(:project_source_files).and_return([f.path])
          expect(checker.report).to have_attributes(
            status: :fail,
            error_slug: :missing_index_find_by,
            source_location: "#{f.path}:2"
          )
        end
      end
    end
  end

  context 'when bare find_by is inside a different model class' do
    before do
      skip 'Prism not available (Ruby < 3.3)' unless defined?(Prism)
      define_database_with_entity do |t|
        t.string :email
      end
    end

    it 'skips the check' do
      Tempfile.create(['other', '.rb']) do |f|
        f.write("class OtherModel\n  find_by(email: x)\nend\n")
        f.flush
        allow(DatabaseConsistency::FilesHelper).to receive(:project_source_files).and_return([f.path])
        expect(checker.report).to be_nil
      end
    end
  end

  context 'when column is the primary key' do
    let(:klass) { define_class { |k| k.primary_key = 'email' } }
    let(:column) { klass.columns.find { |c| c.name == 'email' } }

    before do
      skip 'Prism not available (Ruby < 3.3)' unless defined?(Prism)
      define_database_with_entity do |t|
        t.string :email
      end
    end

    it 'skips the check' do
      Tempfile.create(['entity', '.rb']) do |f|
        f.write("Entity.find_by_email(x)\n")
        f.flush
        allow(DatabaseConsistency::FilesHelper).to receive(:project_source_files).and_return([f.path])
        expect(checker.report).to be_nil
      end
    end
  end

  context 'when there are multiple find_by calls for the column across files' do
    before do
      skip 'Prism not available (Ruby < 3.3)' unless defined?(Prism)
      define_database_with_entity do |t|
        t.string :email
      end
    end

    specify 'reports first location and total count' do
      Tempfile.create(['entity1', '.rb']) do |f1|
        f1.write("Entity.find_by_email(x)\nEntity.find_by(email: y)\n")
        f1.flush
        Tempfile.create(['entity2', '.rb']) do |f2|
          f2.write("Entity.find_by_email!(z)\n")
          f2.flush
          allow(DatabaseConsistency::FilesHelper).to receive(:project_source_files).and_return([f1.path, f2.path])
          report = checker.report
          expect(report).to have_attributes(
            status: :fail,
            source_location: "#{f1.path}:1",
            total_findings_count: 3
          )
        end
      end
    end
  end
end
