require 'spec_helper'

describe Primer::Watcher do
  class Watchable
    include Primer::Watcher
    watch_calls_to :name
    
    def initialize(name)
      @name = name
    end
    
    def name
      @name
    end
  end
  
  let(:watchable) { Watchable.new("Aaron") }
  after { Primer::Watcher.reset! }
  
  describe "with watching disabled" do
    before { Primer::Watcher.disable! }
    
    it "lets methods run as usual" do
      watchable.name.should == "Aaron"
    end
    
    it "does not log method calls" do
      watchable.name
      Primer::Watcher.call_log.should be_empty
    end
  end
  
  describe "with watching enabled" do
    before { Primer::Watcher.enable! }
    
    it "lets methods return their usual return values" do
      watchable.name.should == "Aaron"
    end
    
    it "logs the monitored method calls" do
      watchable.name
      Primer::Watcher.call_log.should == [[watchable, :name]]
    end
  end
end

