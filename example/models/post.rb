class Post < ActiveRecord::Base
  has_many :comments
  include Primer::Watcher
end

