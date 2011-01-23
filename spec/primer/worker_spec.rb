require "spec_helper"

shared_examples_for "primer worker" do
  let(:detachable) { Detachable.new }
  
  before do
    Primer.bus = bus
    Primer::Worker.bind_to_queue "concat"
    $concat_result = nil
  end
  
  describe "detached method" do
    it "returns a Deferrable" do
      detachable.concat.should be_kind_of(EM::Deferrable)
    end
    
    it "does not run the method immediately" do
      detachable.concat("these", "words")
      $concat_result.should be_nil
    end
    
    it "runs the method once it's picked off the queue" do
      detachable.concat("these", "words")
      sleep 1.0
      $concat_result.should == "these, words"
    end
  end
end

describe Primer::Worker do
  describe "with an in-memory bus" do
    let(:bus) { Primer::Bus::Memory.new(:async => true) }
    it_should_behave_like "primer worker"
  end
  
  describe "with an AMQP bus" do
    let(:bus) { Primer::Bus::AMQP.new(:queue => "data_changes_#{Helper.next_id}") }
    it_should_behave_like "primer worker"
  end
end
