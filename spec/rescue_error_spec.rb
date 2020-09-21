# frozen_string_literal: true

RSpec.describe DatabaseConsistency::RescueError do
  def error
    1 / 0
  rescue StandardError => e
    e
  end

  specify do
    expect(File).to receive(:open).once
    described_class.call(error)
  end
end
