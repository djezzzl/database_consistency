# frozen_string_literal: true

RSpec.describe DatabaseConsistency::RescueError, :sqlite, :mysql, :postgresql do
  def error
    1 / 0
  rescue StandardError => e
    e
  end

  specify do
    expect($stdout).to receive(:puts).exactly(4).times
    expect(File).to receive(:open).once
    described_class.call(error)
  end
end
