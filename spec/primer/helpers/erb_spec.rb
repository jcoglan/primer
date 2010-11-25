require 'spec_helper'

module RenderingHelper
  include Primer::Helpers::ERB
  attr_accessor :name
end

class Context
  include RenderingHelper
end

shared_examples_for "erb helper" do
  before { context.name = "Aaron" }
  
  before do
    Primer.cache = Primer::Cache::Memory.new
    Primer.cache.routes = Primer::RouteSet.new do
      get('/user') { "Master" }
    end
  end
  
  describe "#primer" do
    describe "with an empty cache" do
      it "renders the contents of the block" do
        output.should == "Welcome, Master\nHello, Aaron\nThanks\n"
      end
      
      it "uses the model to get data" do
        context.should_receive(:name).and_return("Abe")
        output.should == "Welcome, Master\nHello, Abe\nThanks\n"
      end
      
      it "writes the block result to the cache" do
        Primer.cache.should_receive(:put).with("/user", "Master")
        Primer.cache.should_receive(:put).with("/cache/key", "Hello, Aaron")
        output
      end
    end
    
    describe "with a value in the cache" do
      before { Primer.cache.put("/cache/key", "Text from the cache") }
      
      it "does not use the model to get data" do
        context.should_not_receive(:name)
        output
      end
      
      it "renders the cached value into the template" do
        output.should == "Welcome, Master\nText from the cache\nThanks\n"
      end
    end
  end
end

describe "Rails3 ERB templates" do
  class ApplicationController < ActionController::Base
    def self._helpers
      RenderingHelper
    end
  end
  
  before do
    view_context = context
    controller.stub(:view_context).and_return(view_context)
  end
  
  let(:controller) { ApplicationController.new }
  let(:context)    { controller.view_context   }

  let :output do
    controller.render(:file => "spec/templates/page.erb", :action => "show") rescue
    body = controller.response_body
    Array === body ? body.first : body
  end
  
  it_should_behave_like "erb helper"
end

describe "Sinatra ERB templates" do
  let(:context) { Context.new }
  
  let :output do
    template = Tilt[:erb].new("spec/templates/page.erb", 0, :outvar => "@_out_buf")
    template.render(context)
  end
  
  it_should_behave_like "erb helper"
end

