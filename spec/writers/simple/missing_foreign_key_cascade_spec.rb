# frozen_string_literal: true

RSpec.describe DatabaseConsistency::Writers::Simple::MissingForeignKeyCascade, :sqlite, :mysql, :postgresql do
  subject(:writer) { described_class.new(report, config: config) }

  let!(:config) { DatabaseConsistency::Configuration.new }
  let(:report) do
    DatabaseConsistency::Checkers::ForeignKeyCascadeChecker::Report.new(
      checker_name: 'ForeignKeyCascadeChecker',
      table_or_model_name: 'User',
      column_or_attribute_name: 'posts',
      status: :fail,
      error_slug: :missing_foreign_key_cascade,
      error_message: nil,
      cascade_option: cascade_option,
      primary_table: 'users',
      foreign_table: 'posts',
      primary_key: 'id',
      foreign_key: 'user_id'
    )
  end

  describe '#msg' do
    context 'when a single on_delete option is required' do
      let(:cascade_option) { [:nullify] }

      it 'names the option' do
        expect(writer.msg).to eq(
          'ForeignKeyCascadeChecker fail User posts should have a foreign key with on_delete: :nullify in the database'
        )
      end
    end

    context 'when the foreign key may also have no on_delete option' do
      let(:cascade_option) { [nil, :restrict] }

      it 'names both alternatives' do
        expect(writer.msg).to eq(
          'ForeignKeyCascadeChecker fail User posts should have a foreign key with on_delete: :restrict ' \
          'or without on_delete in the database'
        )
      end
    end
  end
end
