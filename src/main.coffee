_ = require('underscore')
$ = require('../node_modules/zepto/zepto.min.js') # FIXME: A bit messy
Backbone = require('backbone')


class Block extends Backbone.Model
  move: (x, y) ->
    @set {x: x, y: y}
    
  addTo: (collection) =>
    collection.add(@)
    @

    
class Board extends Backbone.Collection
  model: Block
  generate: (width, height) =>
    blocks = []
    bottom = height - 1
    
    fill = (x1, y1, x2, y2, attributes) ->
      xRange = _.range(x1, x2 + 1)
      yRange = _.range(y1, y2 + 1)
      mapped = _.map xRange, (x) ->
        _.map yRange, (y) ->
          _.extend({x: x, y: y}, attributes)
      _.flatten(mapped)
      
    # water
    blocks.push.apply(blocks, fill(0, bottom - Math.round(Math.random() * 3), width, bottom, type: 'water'))
  
    # hills
    amplitude = Math.ceil(Math.random() * 5)
    offset = Math.random() * 10
    stretch = Math.random() * 0.6
    _.times(width, (x) ->
      blocks.push.apply(blocks, fill(x, Math.floor(bottom + (Math.sin(x * stretch + offset) * amplitude)), x, bottom, type: 'dirt')) 
    )
    
    # TODO: blocks on top of blocks should stomp (consider the 2d array approach)
    # TODO: remove blocks outside of the width and height window
            
    # top with trees
    # add them to the collection
    @add(blocks)
  
class BoardView extends Backbone.View
  tagName: 'canvas'
  className: 'board'
  attributes:
    width: 980
    height: 700
    
  currentBlockType: 'dirt'
  
  styleMap:
    'dirt':
      'default': [576, 865]
      'loner': [576, 793]
      'top': [504, 577]
      'color': 'green'
    'rock': 
      'default': [504, 289]
      'color': 'red'
    'water':
      'default': [432, 649]
      'color': 'blue'
  
  events:
    'mousedown': 'mouseDown'
    'mouseup': 'mouseUp'
  
  initialize: () =>
    @blockTypes = _.keys(@styleMap)
  
    @tileWidth = @tileHeight = 70
    
    @collection.on('all', @render)
    
    Zepto ($) =>
      $('body').append(@el)
    
  render: () =>
    @ctx ?= @el.getContext('2d')
    @ctx.fillStyle = 'black'
    @ctx.fillRect(0, 0, @el.width, @el.height)
    
    @collection.each (block) =>
      @ctx.fillStyle = @styleMap[block.get('type')]['color']
      @ctx.fillRect(block.get('x') * @tileWidth, block.get('y') * @tileHeight, @tileWidth, @tileHeight)
      
  pixelCoordToTileCoord: (x, y) =>
    [Math.floor(x / @tileWidth), Math.floor(y / @tileHeight)]
    
  tap: (event) =>
    [x, y] = @pixelCoordToTileCoord(event.x, event.y)
    block = @collection.findWhere({x: x, y: y})
    if block
      i = _.indexOf(@blockTypes, block.get('type')) + 1
      i = 0 if i == @blockTypes.length
      @currentBlockType =  @blockTypes[i]
      block.set('type', @currentBlockType)
    else
      new Block({x: x, y: y, type: @currentBlockType}).addTo(@collection)
      
  longTap: (event) =>
    [x, y] = @pixelCoordToTileCoord(event.x, event.y)
    @collection.remove(@collection.findWhere({x: x, y: y}))
   
  mouseDown: (event) =>
    @lastMouseDown = 
      time: Date.now()
      x: event.x
      y: event.y
      
  mouseUp: (event) =>
    if Date.now() - @lastMouseDown.time > 500 and Math.abs(event.x - @lastMouseDown.x) < 5  and Math.abs(event.y - @lastMouseDown.y) < 5
      @longTap(event)
    else
      @tap(event)

board = new Board()
boardView = new BoardView(collection: board)
board.generate(14, 10)