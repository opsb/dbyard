require "rubygems"
require "bundler"
Bundler.setup
require 'sinatra'
require 'digest'
require 'sequel'

DB = Sequel.connect(ENV['DBYARD_DB_URI'])

get '/' do
  "dbyard for #{ENV['DBYARD_DB_HOST']}"
end

get '/create' do
  create_db
end

post '/' do
  create_db
end

def create_db
  uuid = Digest::SHA1.hexdigest(Time.now.to_s)
  puts uuid
  schema = "s" + uuid
  username = "u" + uuid[0,14]
  password = "p" + uuid
  dbrun("create schema #{schema}")
  dbrun("create user #{username} identified by password '#{password}'")
  permissions = "alter, create, create temporary tables, delete, drop, index, insert, lock tables, select, update"
  dbrun("grant #{permissions} on #{schema}.* to #{username}@'%' identified by '#{password}'")
  dbrun("flush privileges")
  "mysql -u #{username} --password=#{password} -h #{ENV['DBYARD_DB_HOST']} #{schema}"
end

def dbrun(command)
  puts command
  DB.run(command)
end