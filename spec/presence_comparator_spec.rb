RSpec.describe DatabaseConsistency::Comparators::PresenceComparator do
  subject(:compare) do
    described_class.compare(klass.validators.first, klass.columns.first)
  end

  let!(:database) do
    ActiveRecord::Base.establish_connection(
      adapter: 'sqlite3',
      database: ':memory:'
    )
    ActiveRecord::Schema.verbose = false

    options = field_options
    ActiveRecord::Schema.define(version: 1) do
      create_table :entities, id: false do |t|
        t.string :field, options
      end
    end
  end

  let(:klass) do
    options = validates_options
    Class.new(ActiveRecord::Base) do |klass|
      klass.table_name = :entities
      klass.validates :field, options
    end
  end

  context 'when database has null: false' do
    let(:field_options) { { null: false } }

    context 'when presence: true' do
      let(:validates_options) { { presence: true } }

      specify do
        expect(compare).to eq(status: :ok)
      end

      context 'when allow_nil/allow_blank/if/unless is true' do
        let(:validates_options) { { presence: true, allow_nil: true } }

        specify do
          expect(compare).to eq(
            status: :fail,
            message: 'possible null value insert'
          )
        end
      end
    end
  end

  context 'when database has null: true' do
    let(:field_options) { { null: true } }

    context 'when presence: true' do
      let(:validates_options) { { presence: true } }

      specify do
        expect(compare).to eq(
          status: :fail,
          message: 'database field should have: "null: false"'
        )
      end

      context 'when allow_nil/allow_blank/if/unless is true' do
        let(:validates_options) { { presence: true, allow_nil: true } }

        specify do
          expect(compare).to eq(status: :ok)
        end
      end
    end
  end
end
