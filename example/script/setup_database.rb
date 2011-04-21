require File.expand_path(File.dirname(__FILE__)) + '/../db/connection'

ActiveRecord::Schema.define do |version|
  create_table :posts, :force => true do |t|
    t.timestamps
    t.string :title
    t.text   :body
    t.string :author
  end
  
  create_table :comments, :force => true do |t|
    t.timestamps
    t.belongs_to :post
    t.text       :body
  end
end

