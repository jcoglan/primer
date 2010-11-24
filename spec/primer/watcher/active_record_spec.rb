require 'spec_helper'

describe Primer::Watcher::ActiveRecordMacros do
  before do
    @person   = Person.create(:name => "Abe")
    @impostor = Person.create(:name => "Aaron")
    @post     = @person.blog_posts.create(:title => "web scale")
    @id       = @person.id
    
    @artist   = Artist.create(:name => "Wolf Parade")
    @concert  = Concert.create(:date => 6.months.ago, :venue => "Borderline")
    @festival = Concert.create(:date => 3.months.ago, :venue => "End of the Road")
    
    @artist.concerts << @festival
    
    Primer::Worker::ActiveRecordAgent.bind_to_bus
    Primer::Watcher.enable!
  end
  
  after do
    @person.delete
  end
  
  def should_publish(topic, *message)
    @publish ||= Primer.bus.method(:publish)
    Primer.bus.should_receive(:publish).with(topic, message, &@publish)
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
    should_publish(:active_record, :update, @person)
    should_publish(:changes, "ActiveRecord", "Person", @person.id, "name")
    @person.update_attribute(:name, "Aaron")
  end
  
  it "publishes messages when an object is deleted" do
    should_publish(:active_record, :destroy, @person)
    should_publish(:changes, "ActiveRecord", "Person", @person.id, "id")
    should_publish(:changes, "ActiveRecord", "Person", @person.id, "name")
    should_publish(:changes, "ActiveRecord", "Person", @person.id, "age")
    should_publish(:changes, "ActiveRecord", "BlogPost", @post.id, "person")
    @person.destroy
  end
  
  it "publishes a message about a belongs_to association when the foreign key changes" do
    should_publish(:active_record, :create, anything)
    should_publish(:changes, "ActiveRecord", "Person", @person.id, "blog_posts")
    BlogPost.create(:person => @person, :title => "How to make a time machine")
  end
  
  it "publishes a message about a belongs_to association when the object changes" do
    should_publish(:active_record, :update, @post)
    should_publish(:changes, "ActiveRecord", "BlogPost", @post.id, "person_id")
    should_publish(:changes, "ActiveRecord", "BlogPost", @post.id, "person")
    @post.update_attribute(:person, @impostor)
  end
  
  it "publishes a message when a has_many collection gains a member" do
    should_publish(:active_record, :create, anything)
    should_publish(:changes, "ActiveRecord", "Person", @person.id, "blog_posts")
    BlogPost.create(:person => @person, :title => "How to make a time machine")
  end
  
  it "publishes a message when a has_many collection loses a member" do
    should_publish(:active_record, :destroy, @post)
    should_publish(:changes, "ActiveRecord", "BlogPost", @post.id, "id")
    should_publish(:changes, "ActiveRecord", "BlogPost", @post.id, "person_id")
    should_publish(:changes, "ActiveRecord", "BlogPost", @post.id, "title")
    should_publish(:changes, "ActiveRecord", "BlogPost", @post.id, "person")
    should_publish(:changes, "ActiveRecord", "Person", @person.id, "blog_posts")
    @post.destroy
  end
  
  it "publishes a message when an object is pushed to a has_many :through has_many" do
    should_publish(:active_record, :create, anything)
    should_publish(:changes, "ActiveRecord", "Concert", @concert.id, "performances")
    should_publish(:changes, "ActiveRecord", "Artist", @artist.id, "performances")
    should_publish(:changes, "ActiveRecord", "Artist", @artist.id, "concerts")
    @artist.concerts << @concert
  end
  
  it "publishes a message when a join object is pushed to a has_many" do
    should_publish(:active_record, :create, anything)
    should_publish(:changes, "ActiveRecord", "Concert", @concert.id, "performances")
    should_publish(:changes, "ActiveRecord", "Artist", @artist.id, "performances")
    should_publish(:changes, "ActiveRecord", "Artist", @artist.id, "concerts")
    @artist.performances << Performance.new(:concert => @concert)
  end
  
  it "publishes a message when a join object is created for has_many :through has_many" do
    should_publish(:active_record, :create, anything)
    should_publish(:changes, "ActiveRecord", "Concert", @concert.id, "performances")
    should_publish(:changes, "ActiveRecord", "Artist", @artist.id, "performances")
    should_publish(:changes, "ActiveRecord", "Artist", @artist.id, "concerts")
    Performance.create(:concert => @concert, :artist => @artist)
  end
  
  it "publishes messages when a join object is deleted from a has_many :through collection" do
    performance = @festival.performances.first
    should_publish(:active_record, :destroy, @artist.performances.first)
    should_publish(:changes, "ActiveRecord", "Performance", performance.id, "artist_id")
    should_publish(:changes, "ActiveRecord", "Performance", performance.id, "artist")
    should_publish(:changes, "ActiveRecord", "Performance", performance.id, "concert_id")
    should_publish(:changes, "ActiveRecord", "Performance", performance.id, "concert")
    should_publish(:changes, "ActiveRecord", "Performance", performance.id, "id")
    should_publish(:changes, "ActiveRecord", "Artist", @artist.id, "performances")
    should_publish(:changes, "ActiveRecord", "Artist", @artist.id, "concerts")
    should_publish(:changes, "ActiveRecord", "Concert", @festival.id, "performances")
    @artist.performances.first.destroy
  end
  
  it "publishes messages when a member is deleted from a has_many :through collection" do
    performance = @festival.performances.first
    should_publish(:active_record, :destroy, performance)
    should_publish(:changes, "ActiveRecord", "Performance", performance.id, "artist_id")
    should_publish(:changes, "ActiveRecord", "Performance", performance.id, "artist")
    should_publish(:changes, "ActiveRecord", "Performance", performance.id, "concert_id")
    should_publish(:changes, "ActiveRecord", "Performance", performance.id, "concert")
    should_publish(:changes, "ActiveRecord", "Performance", performance.id, "id")
    should_publish(:changes, "ActiveRecord", "Artist", @artist.id, "performances")
    should_publish(:changes, "ActiveRecord", "Artist", @artist.id, "concerts")
    should_publish(:active_record, :destroy, @festival)
    should_publish(:changes, "ActiveRecord", "Concert", @festival.id, "performances")
    should_publish(:changes, "ActiveRecord", "Concert", @festival.id, "date")
    should_publish(:changes, "ActiveRecord", "Concert", @festival.id, "id")
    should_publish(:changes, "ActiveRecord", "Concert", @festival.id, "venue")
    @artist.concerts.first.destroy
  end
end

