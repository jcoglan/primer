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
    
    Primer::Watcher.enable!
  end
  
  after do
    @person.delete
  end
  
  def should_publish(*message)
    Primer.bus.should_receive(:publish).with(message)
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
    should_publish("ActiveRecord", "Person", @person.id, "name")
    @person.update_attribute(:name, "Aaron")
  end
  
  it "publishes messages when an object is deleted" do
    should_publish("ActiveRecord", "Person", @person.id, "id")
    should_publish("ActiveRecord", "Person", @person.id, "name")
    should_publish("ActiveRecord", "Person", @person.id, "age")
    should_publish("ActiveRecord", "BlogPost", @post.id, "person")
    @person.destroy
  end
  
  it "publishes a message about a belongs_to association when the foreign key changes" do
    should_publish("ActiveRecord", "Person", @person.id, "blog_posts")
    BlogPost.create(:person => @person, :title => "How to make a time machine")
  end
  
  it "publishes a message about a belongs_to association when the object changes" do
    should_publish("ActiveRecord", "BlogPost", @post.id, "person_id")
    should_publish("ActiveRecord", "BlogPost", @post.id, "person")
    @post.update_attribute(:person, @impostor)
  end
  
  it "publishes a message when a has_many collection gains a member" do
    should_publish("ActiveRecord", "Person", @person.id, "blog_posts")
    BlogPost.create(:person => @person, :title => "How to make a time machine")
  end
  
  it "publishes a message when a has_many collection loses a member" do
    should_publish("ActiveRecord", "BlogPost", @post.id, "id")
    should_publish("ActiveRecord", "BlogPost", @post.id, "person_id")
    should_publish("ActiveRecord", "BlogPost", @post.id, "title")
    should_publish("ActiveRecord", "BlogPost", @post.id, "person")
    should_publish("ActiveRecord", "Person", @person.id, "blog_posts")
    @post.destroy
  end
  
  it "publishes a message when an object is pushed to a has_many :through has_many" do
    should_publish("ActiveRecord", "Concert", @concert.id, "performances")
    should_publish("ActiveRecord", "Artist", @artist.id, "performances")
    should_publish("ActiveRecord", "Artist", @artist.id, "concerts")
    @artist.concerts << @concert
  end
  
  it "publishes a message when a join object is pushed to a has_many" do
    should_publish("ActiveRecord", "Concert", @concert.id, "performances")
    should_publish("ActiveRecord", "Artist", @artist.id, "performances")
    should_publish("ActiveRecord", "Artist", @artist.id, "concerts")
    @artist.performances << Performance.new(:concert => @concert)
  end
  
  it "publishes a message when a join object is created for has_many :through has_many" do
    should_publish("ActiveRecord", "Concert", @concert.id, "performances")
    should_publish("ActiveRecord", "Artist", @artist.id, "performances")
    should_publish("ActiveRecord", "Artist", @artist.id, "concerts")
    Performance.create(:concert => @concert, :artist => @artist)
  end
  
  it "publishes messages when a join object is deleted from a has_many :through collection" do
    perf_id = @festival.performances.first.id
    should_publish("ActiveRecord", "Performance", perf_id, "artist_id")
    should_publish("ActiveRecord", "Performance", perf_id, "artist")
    should_publish("ActiveRecord", "Performance", perf_id, "concert_id")
    should_publish("ActiveRecord", "Performance", perf_id, "concert")
    should_publish("ActiveRecord", "Performance", perf_id, "id")
    should_publish("ActiveRecord", "Artist", @artist.id, "performances")
    should_publish("ActiveRecord", "Artist", @artist.id, "concerts")
    should_publish("ActiveRecord", "Concert", @festival.id, "performances")
    @artist.performances.first.destroy
  end
  
  it "publishes messages when a member is deleted from a has_many :through collection" do
    perf_id = @festival.performances.first.id
    should_publish("ActiveRecord", "Performance", perf_id, "artist_id")
    should_publish("ActiveRecord", "Performance", perf_id, "artist")
    should_publish("ActiveRecord", "Performance", perf_id, "concert_id")
    should_publish("ActiveRecord", "Performance", perf_id, "concert")
    should_publish("ActiveRecord", "Performance", perf_id, "id")
    should_publish("ActiveRecord", "Artist", @artist.id, "performances")
    should_publish("ActiveRecord", "Artist", @artist.id, "concerts")
    should_publish("ActiveRecord", "Concert", @festival.id, "performances")
    should_publish("ActiveRecord", "Concert", @festival.id, "date")
    should_publish("ActiveRecord", "Concert", @festival.id, "id")
    should_publish("ActiveRecord", "Concert", @festival.id, "venue")
    @artist.concerts.first.destroy
  end
end

