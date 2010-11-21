require 'spec_helper'

shared_examples_for "primer event bus" do
  before do
    @message = nil
    bus.subscribe { |message| @message = message }
  end
  
  it "transmits messages verbatim" do
    bus.publish ["series", "of", "params"]
    sleep 1.0
    @message.should == ["series", "of", "params"]
  end
end

describe Primer::Bus::Memory do
  let(:bus) { Primer::Bus::Memory.new }
  it_should_behave_like "primer event bus"
end

describe Primer::Bus::AMQP do
  let(:bus) { Primer::Bus::AMQP.new(:queue => 'data_changes') }
  it_should_behave_like "primer event bus"
end

