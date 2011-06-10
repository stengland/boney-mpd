class Mopidy < MPD
  def pause
    send_command 'pause'
  end
end

class MeatBox < Sinatra::Base
  set :root, File.dirname(__FILE__)
  set :static, true

  configure do
    begin
      # Load options from config.yml (can override above)
      #set YAML.load_file('config.yml')fluffy clouds
      @@mpd = Mopidy.new 'localhost', 6600
      @@mpd.connect
    rescue Errno::ECONNREFUSED => e
      puts "Could not connect to Mopidy: #{e}"
      exit
    end
  end

  get '/application.js' do
    content_type "text/javascript"
    coffee :application
  end

  get '/style.css' do
    content_type 'text/css; charset=utf-8'
    scss :style
  end

  get '/' do
    File.read(File.join('public', 'index.html'))
  end

  %w(play pause next previous stop clear).each do |action|
    get "/#{action}" do
      @@mpd.send(action)
    end
  end

  %w(any title artist album).each do |type|
    get "/search/#{type}/:query" do
      content_type "application/json"
      @@mpd.search(type,params[:query]).to_json
    end
  end

  get "/album/:title" do
    content_type "application/json"
    @@mpd.find('album',params[:title]).to_json
  end

  get '/playlist' do
    content_type "application/json"
    @@mpd.playlist.to_json
  end

  post '/playlist' do
    content_type "application/json"
    request.body.rewind  # in case someone already read it
    data = JSON.parse request.body.read
    @@mpd.add(data['file'])
    @@mpd.playlist.last.to_json
  end

  delete '/playlist/:id' do
    @@mpd.deleteid(%{"#{ params[:id] }"})
  end

end
