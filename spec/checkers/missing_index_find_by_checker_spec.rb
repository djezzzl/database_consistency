# frozen_string_literal: true

require 'tempfile'

RSpec.describe DatabaseConsistency::Checkers::MissingIndexFindByChecker, :sqlite, :mysql, :postgresql do
  subject(:checker) { described_class.new(model, column) }

  let(:model) { klass }
  let(:klass) { define_class }
  let(:column) { klass.columns.find { |c| c.name == 'email' } }

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
      allow(DatabaseConsistency::Helper).to receive(:find_by_calls_index).and_return({})
    end

    it 'skips the check' do
      expect(checker.report).to be_nil
    end
  end

  context 'when column is not referenced in any find_by call in the project' do
    before do
      skip 'Prism not available (Ruby < 3.3)' unless defined?(Prism)
      define_database_with_entity do |t|
        t.string :email
      end
      allow(DatabaseConsistency::Helper).to receive(:find_by_calls_index).and_return({})
    end

    it 'skips the check' do
      expect(checker.report).to be_nil
    end
  end

  context 'when column is used via dynamic finder (find_by_column_name)' do
    context 'when index is missing' do
      before do
        skip 'Prism not available (Ruby < 3.3)' unless defined?(Prism)
        define_database_with_entity do |t|
          t.string :email
        end
        allow(DatabaseConsistency::Helper).to receive(:find_by_calls_index)
          .and_return({ 'Entity' => { 'email' => 'app/models/entity.rb:2' } })
      end

      specify do
        expect(checker.report).to have_attributes(
          checker_name: 'MissingIndexFindByChecker',
          table_or_model_name: klass.name,
          column_or_attribute_name: 'email',
          status: :fail,
          error_slug: :missing_index_find_by,
          source_location: 'app/models/entity.rb:2'
        )
      end
    end

    context 'when index is present' do
      before do
        skip 'Prism not available (Ruby < 3.3)' unless defined?(Prism)
        define_database_with_entity do |t|
          t.string :email, index: true
        end
        allow(DatabaseConsistency::Helper).to receive(:find_by_calls_index)
          .and_return({ 'Entity' => { 'email' => 'app/models/entity.rb:2' } })
      end

      specify do
        expect(checker.report).to have_attributes(
          checker_name: 'MissingIndexFindByChecker',
          table_or_model_name: klass.name,
          column_or_attribute_name: 'email',
          status: :ok,
          error_slug: nil,
          source_location: nil
        )
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
        allow(DatabaseConsistency::Helper).to receive(:find_by_calls_index)
          .and_return({ 'Entity' => { 'email' => 'app/models/entity.rb:2' } })
      end

      specify do
        expect(checker.report).to have_attributes(status: :fail, error_slug: :missing_index_find_by,
                                                   source_location: 'app/models/entity.rb:2')
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
        allow(DatabaseConsistency::Helper).to receive(:find_by_calls_index)
          .and_return({ 'Entity' => { 'email' => 'app/models/entity.rb:2' } })
      end

      specify do
        expect(checker.report).to have_attributes(
          checker_name: 'MissingIndexFindByChecker',
          column_or_attribute_name: 'email',
          status: :fail,
          error_slug: :missing_index_find_by,
          source_location: 'app/models/entity.rb:2'
        )
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
        allow(DatabaseConsistency::Helper).to receive(:find_by_calls_index)
          .and_return({ 'Entity' => { 'email' => 'app/models/entity.rb:2' } })
      end

      specify do
        expect(checker.report).to have_attributes(
          checker_name: 'MissingIndexFindByChecker',
          table_or_model_name: klass.name,
          column_or_attribute_name: 'email',
          status: :fail,
          error_slug: :missing_index_find_by,
          source_location: 'app/models/entity.rb:2'
        )
      end
    end

    context 'when column is referenced only via another model' do
      before do
        skip 'Prism not available (Ruby < 3.3)' unless defined?(Prism)
        define_database_with_entity do |t|
          t.string :email
        end
        allow(DatabaseConsistency::Helper).to receive(:find_by_calls_index)
          .and_return({ 'OtherModel' => { 'email' => 'app/models/other.rb:2' } })
      end

      it 'skips the check' do
        expect(checker.report).to be_nil
      end
    end

    context 'when column is referenced only via a complex scope (model.where(...))' do
      before do
        skip 'Prism not available (Ruby < 3.3)' unless defined?(Prism)
        define_database_with_entity do |t|
          t.string :email
        end
        allow(DatabaseConsistency::Helper).to receive(:find_by_calls_index).and_return({})
      end

      it 'skips the check' do
        expect(checker.report).to be_nil
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
        allow(DatabaseConsistency::Helper).to receive(:find_by_calls_index)
          .and_return({ 'Entity' => { 'email' => 'app/models/entity.rb:2' } })
      end

      specify do
        expect(checker.report).to have_attributes(
          checker_name: 'MissingIndexFindByChecker',
          column_or_attribute_name: 'email',
          status: :fail,
          error_slug: :missing_index_find_by,
          source_location: 'app/models/entity.rb:2'
        )
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
        allow(DatabaseConsistency::Helper).to receive(:find_by_calls_index)
          .and_return({ 'Entity' => { 'email' => 'app/models/entity.rb:2' } })
      end

      specify do
        expect(checker.report).to have_attributes(
          checker_name: 'MissingIndexFindByChecker',
          table_or_model_name: klass.name,
          column_or_attribute_name: 'email',
          status: :fail,
          error_slug: :missing_index_find_by,
          source_location: 'app/models/entity.rb:2'
        )
      end
    end
  end

  context 'when column is used via bare find_by (nil receiver)' do
    context 'when index is missing' do
      before do
        skip 'Prism not available (Ruby < 3.3)' unless defined?(Prism)
        define_database_with_entity do |t|
          t.string :email
        end
        allow(DatabaseConsistency::Helper).to receive(:find_by_calls_index)
          .and_return({ nil => { 'email' => 'app/models/entity.rb:2' } })
      end

      specify do
        expect(checker.report).to have_attributes(
          status: :fail,
          error_slug: :missing_index_find_by,
          source_location: 'app/models/entity.rb:2'
        )
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
      allow(DatabaseConsistency::Helper).to receive(:find_by_calls_index)
        .and_return({ 'Entity' => { 'email' => 'app/models/entity.rb:2' } })
    end

    it 'skips the check' do
      expect(checker.report).to be_nil
    end
  end

  # Unit tests for FindByCollector: verify AST parsing produces the correct index entries
  if defined?(Prism)
    describe described_class::FindByCollector do
      def collect(source)
        Tempfile.create(['model', '.rb']) do |f|
          f.write(source)
          f.flush
          collector = described_class.new(f.path)
          collector.visit(Prism.parse_file(f.path).value)
          return collector.results.transform_values { |loc| loc.rpartition(':').last.to_i }
        end
      end

      it 'detects dynamic finder' do
        expect(collect("Entity.find_by_email(x)")).to include(['Entity', 'email'] => 1)
      end

      it 'detects bang dynamic finder' do
        expect(collect("Entity.find_by_email!(x)")).to include(['Entity', 'email'] => 1)
      end

      it 'detects hash-style with symbol key' do
        expect(collect("Entity.find_by(email: x)")).to include(['Entity', 'email'] => 1)
      end

      it 'detects hash-style with string key' do
        expect(collect("Entity.find_by('email' => x)")).to include(['Entity', 'email'] => 1)
      end

      it 'detects bare find_by (nil model key)' do
        expect(collect("find_by(email: x)")).to include([nil, 'email'] => 1)
      end

      it 'detects unscoped receiver' do
        expect(collect("Entity.unscoped.find_by(email: x)")).to include(['Entity', 'email'] => 1)
      end

      it 'detects includes receiver' do
        expect(collect("Entity.includes(:posts).find_by(email: x)")).to include(['Entity', 'email'] => 1)
      end

      it 'ignores multi-key hash' do
        expect(collect("Entity.find_by(email: x, name: y)")).not_to include(['Entity', 'email'] => 1)
      end

      it 'stores other model under its own key' do
        results = collect("OtherModel.find_by_email(x)")
        expect(results).to include(['OtherModel', 'email'] => 1)
      end

      it 'skips complex scope (where receiver)' do
        expect(collect("Entity.where(active: true).find_by(email: x)")).to be_empty
      end
    end
  end
end
