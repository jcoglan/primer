require 'spec_helper'

describe Primer::Cache::Memory do
  let(:cache) { Primer::Cache::Memory.new }
  it_should_behave_like "primer cache"
end

