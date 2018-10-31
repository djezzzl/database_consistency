require_relative 'database_context'

RSpec.describe DatabaseConsistency::Comparators::PresenceComparator do
  include_context 'database context'

  subject(:compare) do
    described_class.compare(klass.validators.first, klass.columns.first)
  end

  context 'when database has null: false' do
    before do
      define_database { |t| t.string :field, null: false }
    end

    context 'when presence: true' do
      let(:klass) do
        define_class { |klass| klass.validates :field, presence: true }
      end

      specify do
        expect(compare).to include(status: :ok)
      end

      context 'when allow_nil/allow_blank/if/unless is true' do
        let(:klass) do
          define_class do |klass|
            klass.validates :field, presence: true, allow_nil: true
          end
        end

        specify do
          expect(compare).to include(
            status: :fail,
            message: 'column field of table entities is required but possible null value insert'
          )
        end
      end
    end
  end

  context 'when database has null: true' do
    before do
      define_database { |t| t.string :field, null: true }
    end

    context 'when presence: true' do
      let(:klass) do
        define_class { |klass| klass.validates :field, presence: true }
      end

      specify do
        expect(compare).to include(
          status: :fail,
          message: 'column field of table entities should be required in the database'
        )
      end

      context 'when allow_nil/allow_blank/if/unless is true' do
        let(:klass) do
          define_class do |klass|
            klass.validates :field, presence: true, allow_nil: true
          end
        end

        specify do
          expect(compare).to include(status: :ok)
        end
      end
    end
  end
end
