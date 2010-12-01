require 'spec_helper'

describe Primer::Lazyness do
  before do
    @artist    = Artist.create(:name => "Menomena")
    @artist_id = @artist.id
  end
  
  it "does not call the database when finding a record" do
    Artist.should_not_receive(:find_by_sql)
    Artist.find(@artist_id)
  end
  
  it "does not call the database when getting the primary key" do
    Artist.should_not_receive(:find_by_sql)
    Artist.find_by_id(@artist_id).id.should == @artist_id
  end
  
  it "calls the database to get attributes" do
    Artist.should_receive(:find_by_sql).and_return([@artist])
    Artist.find(@artist_id).name.should == "Menomena"
  end
  
  it "does not call the database to get the attribute we searched on" do
    Artist.should_not_receive(:find_by_sql)
    Artist.find_by_name("Menomena").name.should == "Menomena"
  end
  
  it "calls the database to get the primary key if needed" do
    Artist.should_receive(:find_by_sql).and_return([@artist])
    Artist.find_by_name("Menomena").id.should == @artist_id
  end
  
  it "should be able to tell that an object doesn't really exist" do
    Artist.find_by_name("The National").should == nil
    Artist.find_by_name("The National").should be_nil
  end
  
  it "does not call the database to get all the records" do
    Artist.should_not_receive(:find_by_sql)
    Artist.find(:all)
    Artist.all
  end
  
  it "calls the database when we enumerate all the records" do
    Artist.should_receive(:find_by_sql).and_return([@artist])
    Artist.all.should == [@artist]
  end
  
  it "does not call the database to get the first record" do
    Artist.should_not_receive(:find_by_sql)
    Artist.find(:first)
    Artist.first
  end
  
  it "calls the database when we want an attribute from the first record" do
    Artist.should_receive(:find_by_sql).and_return([@artist])
    Artist.first.name.should == "Menomena"
  end
end

