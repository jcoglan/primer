require 'spec_helper'

shared_examples_for "primer event bus" do
  before do
    @message = nil
    bus.subscribe(:changes) { |message| @message = message }
  end
  
  it "transmits messages verbatim" do
    bus.publish :changes, ["series", "of", "params"]
    sleep 1.0
    @message.should == ["series", "of", "params"]
  end
  
  it "routes messages to the right channel" do
    bus.publish :other, "something"
    sleep 1.0
    @message.should be_nil
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

