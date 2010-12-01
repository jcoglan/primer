class BlogPost < ActiveRecord::Base
  belongs_to :person
  include Primer::Watcher
  include Primer::Lazyness
end

