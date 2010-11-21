class Person < ActiveRecord::Base
  has_many :blog_posts
  
  include Primer::Watcher
  
  def all_attributes
    [id, the_name]
  end
  
  def the_name
    name
  end
end

