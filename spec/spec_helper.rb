#require 'simplecov'
#SimpleCov.start

require File.join(File.dirname(__FILE__), '..', 'app.rb')

require 'sinatra'
require 'rack/test'
require 'webmock/rspec'
require 'factory_girl'
require 'database_cleaner'

# setup test environment
set :environment, :test
set :run, false
set :raise_errors, true
set :logging, false

def app
  HangpersonApp.new!
end

# The following lines disable web usage and causes the external API to be stubbed out,
# eliminating randomness to aid in testing
def stub_random_word(word)
  stub_request(:post, 'http://watchout4snakes.com/wo4snakes/Random/RandomWord').to_return(:body => word)
end

WebMock.disable_net_connect!(allow_localhost: true)

RSpec.configure do |config|
  config.include Rack::Test::Methods
  config.before(:each) do
    stub_request(:post, "http://watchout4snakes.com/wo4snakes/Random/RandomWord").to_return(:body => "foobar")
  end
  config.color = true
  config.include FactoryGirl::Syntax::Methods

  config.before(:suite) do
    DatabaseCleaner.clean_with(:truncation)
  end

  config.before(:each) do
    DatabaseCleaner.strategy = :transaction
  end

  config.before(:each, :js => true) do
    DatabaseCleaner.strategy = :truncation
  end

  config.before(:each) do
    DatabaseCleaner.start
  end

  config.after(:each) do
    DatabaseCleaner.clean
  end

end

FactoryGirl.definition_file_paths = %w{./factories ./test/factories ./spec/factories}
FactoryGirl.find_definitions
