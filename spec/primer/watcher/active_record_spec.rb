require 'spec_helper'

describe Primer::Watcher::ActiveRecordMacros do
  before do
    @person   = Person.create(:name => "Abe")
    @impostor = Person.create(:name => "Aaron")
    @post     = BlogPost.create(:person => @person, :title => "web scale")
    @id       = @person.id
    
    Primer::Watcher.enable!
  end
  
  after do
    @person.delete
  end
  
  describe "#primer_identifier" do
    it "returns a tuple that tells us enough to find the object" do
      @person.primer_identifier.should == ["ActiveRecord", "Person", @person.id]
    end
  end
  
  it "is mixed in automatically when using Primer with ActiveRecord" do
    Person.should be_kind_of(Primer::Watcher::ActiveRecordMacros)
  end
  
  it "watches ActiveRecord attributes" do
    @person.name.should == "Abe"
    Primer::Watcher.call_log.should == [[@person, :name, [], nil, "Abe"]]
  end
  
  it "watches calls to has_many associations" do
    @person.blog_posts.count.should == 1
    Primer::Watcher.call_log.should include([@person, :blog_posts, [], nil, [@post]])
  end
  
  it "watches calls to belongs_to associations" do
    @post.person.should == @person
    Primer::Watcher.call_log.should include([@post, :person, [], nil, @person])
  end
  
  it "logs calls made inside other methods" do
    @person.all_attributes.should == [@id, "Abe"]
    Primer::Watcher.call_log.should == [
      [@person, :id,   [], nil, @id  ],
      [@person, :name, [], nil, "Abe"]
    ]
  end
  
  it "publishes a message when an attribute changes" do
    Primer.bus.should_receive(:publish).with(["ActiveRecord", "Person", @person.id, "name"])
    @person.update_attribute(:name, "Aaron")
  end
  
  it "publishes messages when an object is deleted" do
    Primer.bus.should_receive(:publish).with(["ActiveRecord", "Person", @person.id, "id"])
    Primer.bus.should_receive(:publish).with(["ActiveRecord", "Person", @person.id, "name"])
    Primer.bus.should_receive(:publish).with(["ActiveRecord", "Person", @person.id, "age"])
    @person.destroy
  end
  
  it "publishes a message when a has_many collection gains a member" do
    Primer.bus.should_receive(:publish).with(["ActiveRecord", "Person", @person.id, "blog_posts"])
    BlogPost.create(:person => @person, :title => "How to make a time machine")
  end
  
  it "publishes a message when a has_many collection loses a member" do
    Primer.bus.should_receive(:publish).with(["ActiveRecord", "BlogPost", @post.id, "id"])
    Primer.bus.should_receive(:publish).with(["ActiveRecord", "BlogPost", @post.id, "person_id"])
    Primer.bus.should_receive(:publish).with(["ActiveRecord", "BlogPost", @post.id, "title"])
    Primer.bus.should_receive(:publish).with(["ActiveRecord", "BlogPost", @post.id, "person"])
    Primer.bus.should_receive(:publish).with(["ActiveRecord", "Person", @person.id, "blog_posts"])
    @post.destroy
  end
  
  it "publishes a message about a belongs_to association when the foreign key changes" do
    Primer.bus.should_receive(:publish).with(["ActiveRecord", "Person", @person.id, "blog_posts"])
    BlogPost.create(:person => @person, :title => "How to make a time machine")
  end
  
  it "publishes a message about a belongs_to association when the object changes" do
    Primer.bus.should_receive(:publish).with(["ActiveRecord", "BlogPost", @post.id, "person_id"])
    Primer.bus.should_receive(:publish).with(["ActiveRecord", "BlogPost", @post.id, "person"])
    @post.update_attribute(:person, @impostor)
  end
end

