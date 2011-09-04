require 'rubygems'
require 'bundler'
Bundler.require

class Mopidy < MPD
  def pause
    send_command 'pause'
  end
end

class MeatBox < Sinatra::Base
  set :root, File.dirname(__FILE__)
  set :static, true

  use Faye::RackAdapter, :mount      => '/faye'

  class PlayerStatus
    @@env = nil

    def initialize(app)
      @app = app
    end

    def call(env)
      @@env = env
      @app.call(env)
    end

    class << self
      def current_song(song)
        @current_song = song
        send_message('current_song', song)
      end

      def state(s)
        @state = s
        send_message('state', s)
      end

      def playlist(count)
        @playlist_count = count
        send_message('playlist_count', count)
      end

      def send_message(*data)
        puts "CALLBACK: #{data.inspect}"
        @@env['faye.client'].publish('/playerstate', data) unless @@env.nil?
      end
    end
  end
  use PlayerStatus

  configure do
    Compass.configuration do |config|
      config.project_path = File.dirname(__FILE__)
      config.sass_dir = 'views'
    end


    set :scss, Compass.sass_engine_options

    begin
      @@mpd = Mopidy.new 'localhost', 6600
      @@mpd.connect(true)

      @@mpd.register_callback( PlayerStatus.method('current_song'), MPD::CURRENT_SONG_CALLBACK )
      @@mpd.register_callback( PlayerStatus.method('state'), MPD::STATE_CALLBACK )
      @@mpd.register_callback( PlayerStatus.method('playlist'), MPD::PLAYLIST_CALLBACK )
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

end
