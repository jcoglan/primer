require 'spec_helper'

describe Primer::Watcher::ActiveRecordMacros do
  before do
    @person = Person.create(:name => "Abe")
    @id = @person.id
    Primer::Watcher.enable!
  end
  
  after do
    @person.destroy
  end
  
  describe "#primer_identifier" do
    it "returns a tuple that tells us enough to find the object" do
      @person.primer_identifier.should == ["ActiveRecord", "Person", @person.id]
    end
  end
  
  it "is mixed in automatically when using Primer with ActiveRecord" do
    Person.should be_kind_of(Primer::Watcher::ActiveRecordMacros)
  end
  
  it "automatically watches ActiveRecord attributes" do
    @person.name.should == "Abe"
    Primer::Watcher.call_log.should == [[@person, :name, [], nil, "Abe"]]
  end
  
  it "logs calls made inside other methods" do
    @person.all_attributes.should == [@id, "Abe"]
    Primer::Watcher.call_log.should == [
      [@person, :id,   [], nil, @id  ],
      [@person, :name, [], nil, "Abe"]
    ]
  end
end

