require 'fileutils'
require 'rubygems'
require 'active_record'

dir = File.expand_path(File.dirname(__FILE__))

FileUtils.mkdir_p(dir + '/../db')
dbfile = dir + '/../db/blog.sqlite3'
ActiveRecord::Base.establish_connection(:adapter  => 'sqlite3', :database => dbfile)

