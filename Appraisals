# frozen_string_literal: true

customize_gemfiles do
  {
    single_quotes: true,
    heading: <<~HEADING
      frozen_string_literal: true
    HEADING
  }
end

appraise 'ar_4_2' do
  remove_gem 'appraisal'
  gem 'activerecord', '~> 4.2.0'
  gem 'mysql2', '~> 0.4.0'
  gem 'pg', '~> 0.2'
  gem 'sqlite3', '~> 1.3.9'
end

%w[5.2 6.0 6.1 7.0 7.1].each do |version|
  appraise "ar_#{version.gsub('.', '_')}" do
    remove_gem 'appraisal'
    gem 'activerecord', "~> #{version}.0"
    gem 'sqlite3', '~> 1.3'
  end
end

%w[8.0].each do |version|
  appraise "ar_#{version.gsub('.', '_')}" do
    remove_gem 'appraisal'
    gem 'activerecord', "~> #{version}.0"
    gem 'sqlite3', '>= 2.0'
  end
end

appraise 'ar_main' do
  remove_gem 'appraisal'
  gem 'activerecord', git: 'https://github.com/rails/rails', branch: 'main'
  gem 'sqlite3', '>= 2.0'
end
