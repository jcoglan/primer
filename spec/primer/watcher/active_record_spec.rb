require 'spec_helper'

describe Primer::Watcher::ActiveRecordMacros do
  class Person < ActiveRecord::Base
    include Primer::Watcher
  end
  
  before do
    @person = Person.create(:name => "Abe")
    Primer::Watcher.enable!
  end
  
  after do
    @person.destroy
  end
  
  it "is mixed in automatically when using Primer with ActiveRecord" do
    Person.should be_kind_of(Primer::Watcher::ActiveRecordMacros)
  end
  
  it "automatically watches ActiveRecord attributes" do
    @person.name.should == "Abe"
    Primer::Watcher.call_log.should == [[@person, :name, [], nil, "Abe"]]
  end
end

