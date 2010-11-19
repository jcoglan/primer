require 'spec_helper'

describe Primer::Watcher do
  class Watchable
    include Primer::Watcher
    watch_calls_to :name, :is_called?
    
    def initialize(name)
      @name = name
    end
    
    def name
      @name
    end
    
    def is_called?(name)
      @name == name
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
      Primer::Watcher.call_log.should == [[watchable, :name, [], nil, "Aaron"]]
    end
    
    it "logs arguments given to methods" do
      watchable.is_called?("Aaron")
      watchable.is_called?("Abe")
      Primer::Watcher.call_log.should == [
        [watchable, :is_called?, ["Aaron"], nil, true ],
        [watchable, :is_called?, ["Abe"],   nil, false]
      ]
    end
    
    it "logs blocks passed to methods" do
      block = lambda {}
      watchable.name(&block)
      Primer::Watcher.call_log.should == [[watchable, :name, [], block, "Aaron"]]
    end
    
    it "does not log after you disable the watcher" do
      Primer::Watcher.disable!
      watchable.name.should == "Aaron"
      watchable.is_called?("Aaron").should be_true
      watchable.is_called?("Abe").should be_false
      Primer::Watcher.call_log.should be_empty
    end
  end
end

