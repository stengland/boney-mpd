class Track extends Backbone.Model

class Tracklist extends Backbone.Collection
  model: Track

class Playlist extends Tracklist
  url: '/playlist'

class Search extends Tracklist
  url: (query, type = 'title') ->
    "/search/#{type}/#{query}"

class TracklistView extends Backbone.View
  tagName: 'ul'
  className: 'tracklist'
  initialize: ->
    super
    _.bindAll(this, 'addOne')
  addOne: (track) ->
    trackView = new TrackView(model: track)
    $(@el).html(trackView.render().el)
  render: =>
    $(@el).html('test')
    @collection.each(@addOne)
    this

class TrackView extends Backbone.View
  tagName:  'li'
  template: _.template('''
    <%= track.get('title') %>
    <%= track.get('artist') %>
    <%= track.get('album') %>
  ''')
  render: =>
    alert "render track #{@model.get('title')}"
    $(@el).html(@template(track: @model))
    this

class PlayerView extends Backbone.View
  initialize: ->
    @el = $('#player')
    @render()
  render: =>
    playlistView = new TracklistView({ id: 'playlist', collection: playlist })
    $(@el).append(playlistView.render().el)
    this

playlist = new Playlist

class PlayerController extends Backbone.Controller
  routes:
    'current' : 'current'

  current: ->
    alert 'Hello'

$ ->
  playlist.fetch({
    success: (playlist, response) ->
      playerView = new PlayerView
  })

