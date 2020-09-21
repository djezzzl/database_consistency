# frozen_string_literal: true

RSpec.shared_examples 'match' do
  it 'matches' do
    expect(checker.report).to have_attributes(
      checker_name: 'ForeignKeyTypeChecker',
      table_or_model_name: company_class.name,
      column_or_attribute_name: association.name.to_s,
      status: :ok,
      message: nil
    )
  end
end

RSpec.shared_examples 'mismatch' do
  it 'mismatches' do
    expect(checker.report).to have_attributes(
      checker_name: 'ForeignKeyTypeChecker',
      table_or_model_name: company_class.name,
      column_or_attribute_name: association.name.to_s,
      status: :fail,
      message: "associated model key (#{associated}) with type (#{associated_representation}) " \
               "mismatches key (#{base}) with type (#{base_representation})"
    )
  end
end

RSpec.shared_examples 'check matches' do |matches, mismatches|
  matches.each do |type, representation|
    context "when associated key has #{type} type" do
      let(:associated_type) { type }
      let(:associated_representation) { representation }

      include_examples 'match'
    end
  end

  mismatches.each do |type, representation|
    context "when associated key has #{type} type" do
      let(:associated_type) { type }
      let(:associated_representation) { representation }

      include_examples 'mismatch'
    end
  end
end
