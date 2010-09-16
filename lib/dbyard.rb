require "rubygems"
require "bundler"
Bundler.setup
require 'sinatra'
require 'digest'
require 'sequel'
require 'json'

DB = Sequel.connect(ENV['DBYARD_DB_URI'])

get '/' do
  "dbyard for #{ENV['DBYARD_DB_HOST']}"
end

get '/create' do
  connection_command create_db
end

get '/create.json' do
  content_type :json
  create_db.to_json
end

post '/' do
  connection_command create_db
end

def connection_command(config)
  "mysql -u #{config[:username]} --password=#{config[:password]} -h #{ENV['DBYARD_DB_HOST']} #{config[:schema]}"
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
  {
    :username => username,
    :password => password,
    :schema => schema
  }
end

def dbrun(command)
  puts command
  DB.run(command)
end