require 'spec_helper'

describe Primer::Cache::Redis do
  let(:cache) { Primer::Cache::Redis.new }
  it_should_behave_like "primer cache"
  
  after do
    redis = Redis.new
    redis.keys.each(&redis.method(:del))
  end
end

