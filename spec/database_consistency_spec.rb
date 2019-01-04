# frozen_string_literal: true

RSpec.describe DatabaseConsistency do
  it 'has a version number' do
    expect(DatabaseConsistency::VERSION).not_to be nil
  end
end
