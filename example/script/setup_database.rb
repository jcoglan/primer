require File.expand_path(File.dirname(__FILE__)) + '/../application'

ActiveRecord::Schema.define do |version|
  create_table :blog_posts, :force => true do |t|
    t.timestamps
    t.string :title
    t.text   :body
    t.string :author
  end
end

