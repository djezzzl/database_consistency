# frozen_string_literal: true

RSpec.describe DatabaseConsistency::Helper, :sqlite, :mysql, :postgresql do
  describe '#first_level_associations' do
    subject { described_class.first_level_associations(child) }

    let(:parent) { define_class('Dummy') { |klass| klass.has_one :user } }

    context 'when only parent defines association' do
      let(:child) { stub_const('SubDummy', Class.new(parent)) }
      it { is_expected.to eq([]) }
    end

    context 'when child redefines association' do
      let(:child) { stub_const('SubDummy', Class.new(parent) { |klass| klass.has_one :user }) }
      it { expect(subject.size).to eq(1) }
    end
  end

  describe '#parent_models' do
    subject(:parent_models) { described_class.parent_models(DatabaseConsistency::Configuration.new) }

    before do
      allow(described_class).to receive(:project_klass?).and_return(true)

      define_database_with_entity { |table| table.string :email }

      define_class('Entities', :entities)
      define_class('Scoped::Entities', :entities)
      stub_const('SubEntities', Class.new(Entities))

      expect(ActiveRecord::Base)
        .to receive(:descendants)
        .and_return([Entities, Scoped::Entities, SubEntities])
    end

    it 'includes top-level classes only' do
      expect(subject).to include(Entities, Scoped::Entities)
      expect(subject).not_to include(SubEntities)
    end
  end

  describe '#project_klass', focus: true do
    subject(:project_klass) { described_class.project_klass?(klass) }

    # `Module.const_source_location` was added in Ruby-2.7, so on previous Ruby versions we always
    #   return `true` instead of `false` expected for this testcases
    context 'when the class is anonymous' do
      let(:klass) { define_class.tap { |k| k.singleton_class.remove_method(:name) } }

      context 'without a name' do
        it { is_expected.to be(RUBY_VERSION < '2.7') }
      end

      context 'with bogus name' do
        before { klass.define_singleton_method(:name) { 'Some invalid !@#' } }

        it { is_expected.to be(RUBY_VERSION < '2.7') }
      end
    end
  end

  describe '#models' do
    subject(:models) { described_class.models(DatabaseConsistency::Configuration.new) }

    before do
      allow(described_class).to receive(:project_klass?).and_return(true)

      define_database_with_entity { |table| table.string :email }

      define_class('Entities', :entities)
      define_class('Scoped::Entities', :entities)
      stub_const('SubEntities', Class.new(Entities))

      dummy_cache = Object.new
      dummy_cache.define_singleton_method(:data_source_exists?) { |_table_name| false }
      dummy_cache.define_singleton_method(:table_exists?) { |_table_name| false }

      dummy_connection = ActiveRecord::ConnectionAdapters::AbstractAdapter.new(nil)
      dummy_connection.define_singleton_method(:schema_cache) { dummy_cache }

      define_class('AbstractEntity') do |klass|
        klass.table_name = 'bogus'
        klass.define_singleton_method(:connection) { dummy_connection }
      end

      allow(ActiveRecord::Base)
        .to receive(:descendants)
        .and_return([Entities, Scoped::Entities, SubEntities, AbstractEntity])
    end

    specify do
      expect(models).to contain_exactly(Entities, Scoped::Entities, SubEntities)
    end
  end

  describe '#normalize_condition_sql' do
    context 'with string literals that contain metacharacters' do
      it 'does not unwrap parentheses inside a string literal' do
        expect(described_class.normalize_condition_sql("state = '(draft)'"))
          .to eq("state = '(draft)'")
      end

      it 'does not strip casts inside a string literal' do
        expect(described_class.normalize_condition_sql("label = 'a::text'"))
          .to eq("label = 'a::text'")
      end

      it 'preserves AND inside a string literal' do
        expect(described_class.normalize_condition_sql("name = 'foo AND bar'"))
          .to eq("name = 'foo AND bar'")
      end

      it 'preserves a literal containing AND while sorting real AND clauses' do
        expect(described_class.normalize_condition_sql("name = 'foo AND bar' AND b = 1"))
          .to eq("b = 1 AND name = 'foo AND bar'")
      end

      it 'does not unwrap parentheses around a value that looks like a column' do
        expect(described_class.normalize_condition_sql("code = '(none)'"))
          .to eq("code = '(none)'")
      end

      it 'preserves escaped single quotes inside literals' do
        expect(described_class.normalize_condition_sql("value = 'it''s'")).to include("'it''s'")
      end

      it 'keeps the inequality operator inside a literal' do
        expect(described_class.normalize_condition_sql("note = 'a <> b'"))
          .to eq("note = 'a <> b'")
      end

      it 'does not normalize TRUE or FALSE inside a string literal' do
        expect(described_class.normalize_condition_sql("label = 'TRUE'")).to eq("label = 'TRUE'")
        expect(described_class.normalize_condition_sql("label = 'false'")).to eq("label = 'false'")
      end

      it 'does not collapse whitespace inside a string literal' do
        expect(described_class.normalize_condition_sql("label = 'foo  bar'"))
          .to eq("label = 'foo  bar'")
      end

      it 'strips outer parentheses even when a literal contains an unmatched parenthesis' do
        expect(described_class.normalize_condition_sql("(label = 'foo)bar')"))
          .to eq(described_class.normalize_condition_sql("label = 'foo)bar'"))
      end

      it 'preserves an escaped inner boolean literal' do
        expect(described_class.normalize_condition_sql("label = 'x = ''t'''"))
          .to eq("label = 'x = ''t'''")
      end
    end

    context 'with boolean predicate forms' do
      it "normalizes PostgreSQL 't'/'f' literals with flexible whitespace" do
        expect(described_class.normalize_condition_sql("flag='t'"))
          .to eq(described_class.normalize_condition_sql('flag = 1'))
        expect(described_class.normalize_condition_sql("flag  =   'f'"))
          .to eq(described_class.normalize_condition_sql('flag = 0'))
      end

      it "normalizes inequality comparisons to 't'/'f' without collapsing equality" do
        expect(described_class.normalize_condition_sql("flag <> 't'")).to eq('flag != 1')
        expect(described_class.normalize_condition_sql("flag != 'f'")).to eq('flag != 0')
        expect(described_class.normalize_condition_sql("flag = 'f'")).to eq('flag = 0')
      end

      it 'normalizes IS TRUE and IS FALSE' do
        expect(described_class.normalize_condition_sql('flag IS TRUE'))
          .to eq(described_class.normalize_condition_sql('flag = 1'))
        expect(described_class.normalize_condition_sql('flag IS FALSE'))
          .to eq(described_class.normalize_condition_sql('flag = 0'))
      end

      it 'matches IS TRUE to = TRUE and = t' do
        expect(described_class.normalize_condition_sql('flag IS TRUE'))
          .to eq(described_class.normalize_condition_sql('flag = TRUE'))
        expect(described_class.normalize_condition_sql('flag IS TRUE'))
          .to eq(described_class.normalize_condition_sql("flag = 't'"))
      end

      it 'normalizes TRUE = TRUE to 1 = 1' do
        expect(described_class.normalize_condition_sql('TRUE = TRUE')).to eq('1 = 1')
      end

      it 'normalizes IS NOT TRUE and IS NOT FALSE' do
        expect(described_class.normalize_condition_sql('flag IS NOT TRUE')).to eq('flag IS NOT 1')
        expect(described_class.normalize_condition_sql('flag IS NOT FALSE')).to eq('flag IS NOT 0')
      end

      it 'normalizes boolean predicate forms on parenthesized columns' do
        expect(described_class.normalize_condition_sql("(flag) = 't'"))
          .to eq(described_class.normalize_condition_sql('flag = 1'))
        expect(described_class.normalize_condition_sql('(flag) IS TRUE'))
          .to eq(described_class.normalize_condition_sql('flag = 1'))
        expect(described_class.normalize_condition_sql('(flag) IS NOT TRUE'))
          .to eq(described_class.normalize_condition_sql('flag IS NOT 1'))
      end

      it 'preserves boolean keywords inside string literals' do
        expect(described_class.normalize_condition_sql("label = 'IS TRUE'")).to eq("label = 'IS TRUE'")
      end
    end

    context 'when identifiers are quoted' do
      it 'strips double-quoted identifiers' do
        expect(described_class.normalize_condition_sql("\"state\" = 'draft'"))
          .to eq(described_class.normalize_condition_sql("state = 'draft'"))
      end

      it 'strips backtick-quoted identifiers' do
        expect(described_class.normalize_condition_sql("`state` = 'draft'"))
          .to eq(described_class.normalize_condition_sql("state = 'draft'"))
      end
    end

    context 'with parenthesized numeric literals' do
      it 'unwraps a parenthesized integer literal with a cast' do
        expect(described_class.normalize_condition_sql('price > (0)::numeric'))
          .to eq(described_class.normalize_condition_sql('price > 0'))
      end

      it 'unwraps a parenthesized decimal literal with a cast' do
        expect(described_class.normalize_condition_sql('price > (0.0)::float8'))
          .to eq(described_class.normalize_condition_sql('price > 0.0'))
      end

      it 'unwraps a parenthesized small decimal literal' do
        expect(described_class.normalize_condition_sql('price > (0.00001)::double precision'))
          .to eq(described_class.normalize_condition_sql('price > 0.00001'))
      end

      it 'unwraps a parenthesized large integer literal with a cast' do
        expect(described_class.normalize_condition_sql('price > (1000000)::numeric'))
          .to eq(described_class.normalize_condition_sql('price > 1000000'))
      end

      it 'unwraps a parenthesized decimal through nested casts' do
        expect(described_class.normalize_condition_sql('price > ((1.23)::real)::numeric'))
          .to eq(described_class.normalize_condition_sql('price > 1.23'))
      end

      it 'unwraps a decimal through three levels of nested casts' do
        expect(described_class.normalize_condition_sql('price > (((1.23)::real)::numeric)::double precision'))
          .to eq(described_class.normalize_condition_sql('price > 1.23'))
      end

      it 'does not unwrap parentheses around a number-string literal' do
        expect(described_class.normalize_condition_sql("code = '(0)'")).to eq("code = '(0)'")
      end
    end

    context 'with multi-word and array casts' do
      it 'strips a double precision cast' do
        expect(described_class.normalize_condition_sql('price > (0.0)::double precision'))
          .to eq(described_class.normalize_condition_sql('price > 0.0'))
      end

      it 'strips a character varying cast' do
        expect(described_class.normalize_condition_sql("label = 'x'::character varying"))
          .to eq(described_class.normalize_condition_sql("label = 'x'"))
      end

      it 'strips a timestamp without time zone cast' do
        expect(described_class.normalize_condition_sql("created_at > '2024-01-01'::timestamp without time zone"))
          .to eq(described_class.normalize_condition_sql("created_at > '2024-01-01'"))
      end

      it 'strips an array cast and normalizes ANY (ARRAY[...]) to IN (...)' do
        expect(described_class.normalize_condition_sql("state = ANY (ARRAY['draft'::character varying]::text[])"))
          .to eq(described_class.normalize_condition_sql("state IN ('draft')"))
      end

      it 'normalizes a simple ANY (ARRAY[...]) with one text element' do
        expect(described_class.normalize_condition_sql("state = ANY (ARRAY['draft'])"))
          .to eq(described_class.normalize_condition_sql("state IN ('draft')"))
      end

      it 'normalizes a simple ANY (ARRAY[...]) with multiple text elements' do
        expect(described_class.normalize_condition_sql("state = ANY (ARRAY['draft', 'published'])"))
          .to eq(described_class.normalize_condition_sql("state IN ('draft', 'published')"))
      end

      it 'normalizes ANY (ARRAY[...]) with a cast element' do
        expect(described_class.normalize_condition_sql("state = ANY (ARRAY['draft'::text])"))
          .to eq(described_class.normalize_condition_sql("state IN ('draft')"))
      end

      it 'normalizes ANY (ARRAY[...]) with numeric elements' do
        expect(described_class.normalize_condition_sql('price = ANY (ARRAY[1, 2, 3])'))
          .to eq(described_class.normalize_condition_sql('price IN (1, 2, 3)'))
      end

      it 'normalizes ANY (ARRAY[...]) with float elements' do
        expect(described_class.normalize_condition_sql('price = ANY (ARRAY[1.5, 2.5])'))
          .to eq(described_class.normalize_condition_sql('price IN (1.5, 2.5)'))
      end

      it 'normalizes a Postgres indexdef-style ANY array wrapped in extra parentheses' do
        expect(described_class.normalize_condition_sql(
                 "((state)::text = ANY ((ARRAY['draft'::character varying, " \
                 "'canon'::character varying])::text[]))"
               ))
          .to eq(described_class.normalize_condition_sql("state IN ('draft', 'canon')"))
      end
    end

    context 'with real-world partial-index predicates' do
      it 'strips outer parens when a literal has unmatched parens and normalizes booleans' do
        expect(described_class.normalize_condition_sql("((label = 'Region (North)') AND active = TRUE)"))
          .to eq(described_class.normalize_condition_sql("active = 1 AND label = 'Region (North)'"))
      end
    end
  end
end
