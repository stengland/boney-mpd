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

  get "/search/title/:query" do
    content_type "application/json"
    @@mpd.search('title',params[:query]).to_json
  end

  get '/playlist' do
    content_type "application/json"
    @@mpd.playlist.to_json
  end

  post '/playlist' do
    request.body.rewind  # in case someone already read it
    data = JSON.parse request.body.read
    @@mpd.add(data['file'])
  end

end
