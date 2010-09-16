require "rubygems"
require "bundler"
Bundler.setup
require 'sinatra'
require 'digest'
require 'sequel'
require 'json'

DB = Sequel.connect(ENV['DBYARD_DB_URI'])

get '/' do
  erb :index
end

post '/create' do
  connection_command create_db
end

post '/create.json' do
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
  DB.run("create schema #{schema}")
  DB.run("create user #{username} identified by password '#{password}'")
  permissions = "alter, create, create temporary tables, delete, drop, index, insert, lock tables, select, update"
  DB.run("grant #{permissions} on #{schema}.* to #{username}@'%' identified by '#{password}'")
  DB.run("flush privileges")
  {
    :username => username,
    :password => password,
    :schema => schema
  }
end

__END__

@@ index
<h1>DByard</h1>
<form method="post" url="/create">
  <input type="submit" value="Make me a database" />
</form>





