class MeatBox < Sinatra::Base
  set :root, File.dirname(__FILE__)
  set :static, true

  configure do
    # Load options from config.yml (can override above)
    #set YAML.load_file('config.yml')
    @@mpd = MPD.new 'localhost', 6600
    @@mpd.connect
  end

  get '/application.js' do
    content_type "text/javascript"
    coffee :application
  end

  get '/' do
    File.read(File.join('public', 'index.html'))
  end

  get '/search' do

  end

  get '/playlist' do
    content_type "application/json"
    @@mpd.playlist.to_json
  end

end
