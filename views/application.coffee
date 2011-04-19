class Track extends Backbone.Model

class Tracklist extends Backbone.Collection
  model: Track

class Playlist extends Tracklist
  url: '/playlist'

class Search extends Tracklist
  url: ->
    "/search/#{@type}/#{@query}"

class PlayerView extends Backbone.View
  events:
    'click .play'  : 'play'
    'click .pause' : 'pause'
  play: ->
    $.get('/play')
  pause: ->
    $.get('/pause')

class TracklistView extends Backbone.View
  tagName: 'ul'
  className: 'tracklist'
  addOne: (track) =>
    trackView = new TrackView(model: track)
    $(@el).append(trackView.render().el)
  render: =>
    $(@el).html('')
    @collection.each(@addOne)
    this

class TrackView extends Backbone.View
  tagName:  'li'
  template: _.template('''
    <%= track.get('title') %>
    <%= track.get('artist') %>
    <%= track.get('album') %>
    <button class="add">Add</button>
  ''')
  events:
    'click .add' : 'addToPlayList'
  addToPlayList: =>
    playlist.create(@model) #posts the model to the playlist
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
    this

search = new Search
class SearchView extends Backbone.View
  initialize: ->
    @tracklistView = new TracklistView({ collection: search })
    super
  events:
    "change #query":          "search"
  search: ->
    window.location.hash = "search/title/#{$('#query').val()}"
  render: =>
    $(@el).append(@tracklistView.render().el)
    this

class PlayerController extends Backbone.Controller
  routes:
    'playlist'            : 'playlist',
    'search/:type/:query' : 'search'

  playlist: ->
    playlist.fetch({
      success: (playlist, response) ->
        playlistView.render()
    })

  search: (type, query) ->
    search.type = type
    search.query = query
    search.fetch({
      success: ->
        searchView.render()
    })

playlistView = null
searchView = null

$ ->
  playerView = new PlayerView({ el: $('#player')} )
  playlistView = new PlaylistView({ el: $('#playlist') })
  searchView = new SearchView({ el: $('#search') })
  new PlayerController()
  Backbone.history.start()

