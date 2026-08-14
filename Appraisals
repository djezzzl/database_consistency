# frozen_string_literal: true

customize_gemfiles do
  {
    single_quotes: true,
    heading: <<~HEADING
      frozen_string_literal: true
    HEADING
  }
end

# rubocop is a development dependency of the gemspec, which every gemfile pulls
# in via `gemspec path: '../'`. No single rubocop version spans Ruby 2.6 to 4.0,
# so the gemspec keeps a broad allowance and each appraisal pins the version
# that works for its Ruby, the same way the DB adapters are pinned.
#
#   rubocop 1.50.x -> ruby >= 2.6
#   rubocop 1.75.x -> ruby >= 2.7
RUBOCOP_LEGACY = '~> 1.50.0' # ruby 2.6
RUBOCOP_CURRENT = '~> 1.75'  # ruby >= 2.7

appraise 'ar_4_2' do
  remove_gem 'appraisal'
  gem 'activerecord', '~> 4.2.0'
  gem 'mysql2', '~> 0.4.0'
  gem 'pg', '~> 0.2'
  gem 'sqlite3', '~> 1.3.9'
  gem 'rubocop', RUBOCOP_LEGACY
end

%w[5.2 6.0 6.1 7.0 7.1].each do |version|
  appraise "ar_#{version.gsub('.', '_')}" do
    remove_gem 'appraisal'
    gem 'concurrent-ruby', '1.3.4'
    gem 'activerecord', "~> #{version}.0"
    gem 'mysql2', '~> 0.5'
    gem 'pg', '>= 0.2'
    gem 'sqlite3', '~> 1.3'
    gem 'rubocop', RUBOCOP_CURRENT
  end
end

%w[7.2 8.0 8.1].each do |version|
  appraise "ar_#{version.gsub('.', '_')}" do
    remove_gem 'appraisal'
    gem 'activerecord', "~> #{version}.0"
    gem 'mysql2', '~> 0.5'
    gem 'pg', '>= 0.2'
    gem 'sqlite3', '>= 2.0'
    gem 'rubocop', RUBOCOP_CURRENT
  end
end

appraise 'ar_main' do
  remove_gem 'appraisal'
  gem 'activerecord', git: 'https://github.com/rails/rails', branch: 'main'
  gem 'mysql2', '~> 0.5'
  gem 'pg', '>= 0.2'
  gem 'sqlite3', '>= 2.0'
  gem 'rubocop', RUBOCOP_CURRENT
end
