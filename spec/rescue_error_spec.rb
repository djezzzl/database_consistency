# frozen_string_literal: true

RSpec.describe DatabaseConsistency::RescueError do
  def error
    1 / 0
  rescue StandardError => error
    error
  end

  specify do
    expect(File).to receive(:open).once
    expect { described_class.call(error) }.to output(/Thank you/).to_stdout
  end
end
