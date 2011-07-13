class Comment < ActiveRecord::Base
  include Primer::Watcher
  belongs_to :post
end

