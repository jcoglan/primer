class BlogPost < ActiveRecord::Base
  include Primer::Watcher
  include Primer::Lazyness
  
  belongs_to :person
end

