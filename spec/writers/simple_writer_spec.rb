# frozen_string_literal: true

RSpec.describe DatabaseConsistency::Writers::SimpleWriter, :sqlite, :mysql, :postgresql do
  let!(:config) { DatabaseConsistency::Configuration.new }

  describe '#write' do
    subject(:write) { described_class.write([report], config: config) }

    context 'when the error slug is plural' do
      let(:report) do
        DatabaseConsistency::Checkers::ForeignKeyTypeChecker::Report.new(
          checker_name: 'ForeignKeyTypeChecker',
          table_or_model_name: 'User',
          column_or_attribute_name: 'company',
          status: :fail,
          error_slug: :inconsistent_types,
          error_message: nil,
          pk_name: 'id',
          pk_type: 'bigint',
          fk_name: 'company_id',
          fk_type: 'integer',
          table_to_change: 'users',
          type_to_set: ['bigint']
        )
      end

      it 'writes the message of the matching writer' do
        expect { write }.to output(
          'ForeignKeyTypeChecker fail User company foreign key (company_id) with type (integer) ' \
          "does not match primary key (id) with type (bigint)\n"
        ).to_stdout
      end
    end
  end
end
