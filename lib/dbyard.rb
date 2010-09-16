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

delete '/:schema' do
  status 200  
  begin
    config = config_from_schema(params[:schema])
    DB.run("drop schema #{config[:schema]}")
    DB.run("drop user #{config[:username]}")
  rescue Exception => e
    puts e
    status 404
  end
end

post '/' do
  connection_command create_db
end

def connection_command(config)
  "mysql -u #{config[:username]} --password=#{config[:password]} -h #{ENV['DBYARD_DB_HOST']} #{config[:schema]}\n"
end

def create_db
  config = create_config
  DB.run("create schema #{config[:schema]}")
  DB.run("create user #{config[:username]} identified by password '#{config[:password]}'")
  permissions = "alter, create, create temporary tables, delete, drop, index, insert, lock tables, select, update"
  DB.run("grant #{permissions} on #{config[:schema]}.* to #{config[:username]}@'%' identified by '#{config[:password]}'")
  DB.run("flush privileges")
  config
end

def create_config
  uuid = Digest::SHA1.hexdigest(Time.now.to_s)
  puts uuid
  schema = "s" + uuid
  username = "u" + uuid[0,14]
  password = "p" + uuid
  {
    :username => username,
    :password => password,
    :schema => schema
  }  
end

def config_from_schema(schema)
  {
    :username => "u" + schema.sub('s','')[0,14],
    :password => schema.sub('^s', 'p'),
    :schema => schema
  }
end

__END__

@@ index
<h1>DByard</h1>
<form method="post" action="/create">
  <input type="submit" value="Make me a database" />
</form>





