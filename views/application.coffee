class Track extends Backbone.Model

class Artist extends Backbone.Model

class AlbumList extends Backbone.Collection
  model: Album

class ArtistList extends Backbone.Collection
  model: Artist

class Tracklist extends Backbone.Collection
  model: Track

class Playlist extends Tracklist
  url: '/playlist'

class Album extends Tracklist
  url: ->
    "/album/#{@title}"

class Search extends Tracklist
  url: ->
    "/search/#{@type}/#{@query}"

class PlayerView extends Backbone.View
  events:
    'click command'  : 'action'
  render: =>
    if @current_song
      this.$('.track').html(@current_song.title)
      this.$('.artist').html(@current_song.artist)
      this.$('.album').html(@current_song.album)
  action: (e) ->
    $.get("/#{$(e.target).data('action')}")

class TracklistView extends Backbone.View
  tagName: 'ol'
  className: 'tracklist'
  renderOne: (track) =>
    trackView = new TrackView(model: track)
    $(@el).append(trackView.render().el)
  render: =>
    $(@el).html('')
    @collection.each(@renderOne)
    this

class TrackView extends Backbone.View
  tagName:  'li'
  template: _.template('''
    <span class="track"><%= track.get('title') %></span>
    <span class="artist"><%= track.get('artist') %></span>
    <span class="album"><%= track.get('album') %></span>
  ''')
  events:
    'click .track' : 'playListAction'
    'click .artist' : 'showArtist'
    'click .album' : 'showAlbum'
  showArtist: ->
    window.location.hash = "artist/#{@model.get('artist')}"
  showAlbum: ->
    window.location.hash = "album/#{@model.get('album')}"
  playListAction: =>
    if @model.get('pos')
      @model.destroy()
      this.remove()
    else
      playlist.create(@model.toJSON()) #posts the model to the playlist
  render: =>
    $(@el).html(@template(track: @model))
    this

playlist = new Playlist
class PlaylistView extends Backbone.View
  initialize: ->
    @tracklistView = new TracklistView({ collection: playlist })
    super
  render: =>
    $(@el).append(@tracklistView.render().el)
    toggleSection(@el)
    this

class BrowserView extends Backbone.View
  render: =>
    $(@el).html('')
    $(@el).append(@content.render().el)
    toggleSection(@el)
    this

class AlbumView extends Backbone.View
  className: 'album'
  template: _.template('''
    <h2><%= title %></h2>
  ''')
  events:
    'click h2' : 'addAlbum'
  addAlbum: =>
    playlist.create track for track in @collection.toJSON()
  render: =>
    $(@el).html(@template({title: @collection.title}))
    tracklistView = new TracklistView({ collection: @collection })
    $(@el).append(tracklistView.render().el)
    this

search = new Search
class SearchView extends Backbone.View
  initialize: ->
    @tracklistView = new TracklistView({ collection: search })
    super
  events:
    "change #query":          "search"
  search: ->
    window.location.hash = "search/any/#{$('#query').val()}"
  render: =>
    $(@el).append(@tracklistView.render().el)
    toggleSection(@el)
    this

class PlayerController extends Backbone.Controller
  routes:
    'playlist'            : 'playlist'
    'search'              : 'search'
    'search/:type/:query' : 'search'
    'album/:title'        : 'album'

  playlist: ->
    playlist.fetch({
      success: (playlist, response) ->
        playlistView.render()
    })

  search: (type, query) ->
    if type
      search.type = type
      search.query = query
      search.fetch({
        success: ->
          searchView.render()
      })
    else
      searchView.render()

  album: (title) ->
    album = new Album
    album.title = title
    album.fetch({
      success: (album, response) ->
        browserView.content = new AlbumView({ collection: album })
        browserView.render()
    })


playlistView = null
searchView = null
browserView = null
toggleSection = (section) ->
  $('section.active').removeClass('active')
  $(section).addClass('active')

$ ->
  playerView = new PlayerView({ el: $('#player')} )
  playlistView = new PlaylistView({ el: $('#playlist') })
  searchView = new SearchView({ el: $('#search') })
  browserView = new BrowserView({ el: $('#browser')})
  new PlayerController()
  connection = new WebSocket('ws://localhost:9292/messages')
  # When the connection is open, send some data to the server
  #connection.onopen = () ->
    #connection.send('Ping'); # Send the message 'Ping' to the server
  # Log errors`
  connection.onerror = (error) ->
    console.log('WebSocket Error ' + error)
  # Log messages from the server
  connection.onmessage = (e) ->
    console.log('Server: ' + e.data)
    parsed_data = eval(e.data)
    playerView[parsed_data[0]] = parsed_data[1]
    playerView.render()

  Backbone.history.start()

