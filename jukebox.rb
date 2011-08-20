require 'rubygems'
require 'bundler'
Bundler.require

class Mopidy < MPD
  def pause
    send_command 'pause'
  end
end

class Sinatra::Request
  include Skinny::Helpers
end

class MeatBox < Sinatra::Base
  set :root, File.dirname(__FILE__)
  set :static, true

  class PlayerState
    class << self
      attr_accessor :sockets

      def current_song(song)
        send_message('current_song', song)
      end

      def send_message(*data)
        puts "CALLBACK: #{data.inspect}"
        @sockets.each do |soc|
          puts "MESSAGE #{soc}"
          soc.send_message data.to_json
        end
      end
    end
  end

  configure do
    Compass.configuration do |config|
      config.project_path = File.dirname(__FILE__)
      config.sass_dir = 'views'
    end

    set :scss, Compass.sass_engine_options

    PlayerState.sockets = []

    begin
      @@mpd = Mopidy.new 'localhost', 6600
      @@mpd.connect(true)

      @@mpd.register_callback( PlayerState.method('current_song'), MPD::CURRENT_SONG_CALLBACK )
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
    content_type 'text/css', :charset => 'utf-8'
    scss :style
  end

  get '/' do
    headers "Access-Control-Allow-Headers" => "x-requested-with"
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
    @@mpd.find('album',params[:title]).
      reject{|t| t['album'] != params[:title]}.
      uniq(&:title).
      sort{|a,b| a['track'].to_i <=> b['track'].to_i }.
      to_json
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

  get '/messages' do
    if request.websocket?
      request.websocket!(
        :protocol => "Meatbox Message Push",
        :on_start => proc do |websocket|
          puts "OPEN sock"
          PlayerState.sockets << websocket
          websocket.on_close do |websocket|
            puts "CLOSE sock"
            PlayerState.sockets.delete( websocket )
          end
        end)
    else
      ['Nothing to see here']
    end
  end

end
