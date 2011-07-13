class Post < ActiveRecord::Base
  include Primer::Watcher
  has_many :comments
end

