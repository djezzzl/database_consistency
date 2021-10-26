# frozen_string_literal: true

RSpec.describe DatabaseConsistency::Checkers::ForeignKeyChecker, sqlite: true do
  subject(:checker) { described_class.new(model, association) }

  let(:model) { entity_class }
  let(:association) { entity_class.reflect_on_all_associations.first }
  let!(:country_class) { define_class('Country', :countries) }
  let!(:entity_class) do
    define_class do |klass|
      klass.belongs_to :country
    end
  end

  if ActiveRecord::VERSION::MAJOR < 5
    specify do
      expect(checker.report).to be_nil
    end
  end
end
