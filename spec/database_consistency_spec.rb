# frozen_string_literal: true

RSpec.describe DatabaseConsistency, :sqlite, :mysql, :postgresql do
  it 'has a version number' do
    expect(DatabaseConsistency::VERSION).not_to be nil
  end
end
