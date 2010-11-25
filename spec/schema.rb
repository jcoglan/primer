ActiveRecord::Schema.define do |version|
  create_table :artists, :force => true do |t|
    t.belongs_to :calendar
    t.string :name
  end
  
  create_table :calendars, :force => true do |t|
  end
  
  create_table :concerts, :force => true do |t|
    t.belongs_to :calendar
    t.date :date
    t.string :venue
  end
  
  create_table :performances, :force => true do |t|
    t.belongs_to :artist
    t.belongs_to :concert
  end
  
  create_table :blog_posts, :force => true do |t|
    t.belongs_to :person
    t.string :title
  end
  
  create_table :people, :force => true do |t|
    t.string  :name
    t.integer :age
  end
end

