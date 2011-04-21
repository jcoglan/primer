class Comment < ActiveRecord::Base
  belongs_to :post
  include Primer::Watcher
end

