# frozen_string_literal: true

RSpec.describe DatabaseConsistency::Databases::Factory, :sqlite, :mysql, :postgresql do
  describe '#type' do
    context 'when adapter is SQLite' do
      subject(:factory) { described_class.new('SQLite') }

      it 'returns a Sqlite type' do
        expect(factory.type('bigserial')).to be_a(DatabaseConsistency::Databases::Types::Sqlite)
      end
    end

    context 'when adapter is not SQLite' do
      subject(:factory) { described_class.new('PostgreSQL') }

      it 'returns a Base type' do
        expect(factory.type('bigint')).to be_a(DatabaseConsistency::Databases::Types::Base)
      end
    end
  end
end
