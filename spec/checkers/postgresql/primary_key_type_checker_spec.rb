# frozen_string_literal: true

RSpec.describe DatabaseConsistency::Checkers::PrimaryKeyTypeChecker, :postgresql do
  subject(:checker) { described_class.new(model, column) }

  let(:model) { klass }
  let(:column) { klass.columns.first }
  let(:klass) { define_class { |klass| klass.primary_key = :id } }

  before do
    model.connection.execute(<<~SQL)
      CREATE OR REPLACE FUNCTION public.prefixed_uuid_generate_v4(prefix character varying)
      RETURNS character varying
      AS $$
      SELECT prefix || '_00000000-0000-4000-8000-000000000000'
      $$ LANGUAGE SQL;
    SQL

    model.connection.execute(<<~SQL)
      CREATE TABLE entities (
        id character varying DEFAULT public.prefixed_uuid_generate_v4('veh'::character varying) NOT NULL PRIMARY KEY
      )
    SQL
  end

  specify do
    expect(checker.report).to have_attributes(
      checker_name: 'PrimaryKeyTypeChecker',
      table_or_model_name: klass.name,
      column_or_attribute_name: 'id',
      status: :ok,
      error_slug: nil,
      error_message: nil
    )
  end
end
