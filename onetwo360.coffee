#{{{1 Minification
#
# define `isNodeJs` and `runTest` in such a way that they will be fully removed by `uglifyjs -mc -d isNodeJs=false -d runTest=false `
#
global = window if typeof "global" == undefined and (typeof isNodeJs == "undefined" or typeof runTest == "undefined")
global.isNodeJs = (typeof window == "undefined") if typeof isNodeJs == "undefined"
global.runTest = true if typeof runTest == "undefined"

#{{{1 Version 2
if !isNodeJs
  #{{{2 utility
  #{{{3 extend
  #{{{2 Model
  #
  # The model is just a json object that is passed around. This has all the state for the onetwo360 viewer
  #
  defaultModel = ->
    frames:
      current: 0
      normal:
        width: undefined
        height: undefined
        urls: []
      zoom:
        width: undefined
        height: undefined
        urls: []
    fullscreen:
      false
    zoom:
      lensSize: 200
      enabled: false
      # x/y-position on image normalised in [0;1]
      x: undefined
      y: undefined
    domElem:
      width: undefined
      height: undefined
      domId: undefined


  #{{{2 View
  #
  # The html of the view is static, only updated through css-changes. 
  #
  #{{{3 `View` constructor, - create a view and bind it to a dom element
  #
  # Create the view, - and bind it to a dom element
  #
  View = (model, domId) ->
    @model = model
    domElem = document.getElementById(domId)
    @defaultWidth = domElem.offsetWidth
    @defaultHeigh = domElem.offsetHeight

    #{{{4 Style
    extend domElem.style,
      display: "inline-block"
      width: @defaultWidth + "px"
      height: @defaultHeight + "px"
    @style =
      root:
        cursor: "url(res/cursor_rotate.cur),move"

      # NB: order of the following keys needs to be the exactly same as the children of the dom root node
      zoomLens:
        display: "block"
        position: "absolute"
        overflow: "hidden"
        width: @model.zoom.lensSize
        height: @model.zoom.lensSize
        border: "0px solid black"
        cursor: "default"
        backgroundColor: "rgba(100,100,100,0.8)"
        borderRadius: (@model.zoom.lensSize/2)
        #borderBottomRightRadius: (zoomSize/5)
        boxShadow: "0px 0px 40px 0px rgba(255,255,255,.7) inset, 4px 4px 9px 0px rgba(0,0,0,0.5)"
        backgroundRepeat: "no-repeat"
      logo:
        position: "absolute"
        opacity: "0.7"
        textShadow: "0px 0px 5px white"
        color: "#333"
        transition: "opacity 1s"
      btnFull:
        left: "90%"
      btnZoom:
        left: "5%"
      spinner:
        position: "absolute"
        top: "49%"
        left: "49%"

    buttonStyle =
      position: "absolute"
      color: "#333"
      opacity: "0.7"
      textShadow: "0px 0px 5px white"
      backgroundColor: "rgba(255,255,255,0)"
      top: "80%"
      fontSize: @defaultHeight * .08
      padding: @defaultHeight * .02
    extend @style.btnFull, buttonStyle
    extend @style.btnZoom, buttonStyle

    #{{{4 Dom element creation
    @elems = {}
    @elems.root = document.createElement "div"
    @elems.root.innerHTML =
      '<div class="onetwo360-zoom-lens"></div>' +
      '<i class="icon-OneTwo360Logo"></div>' +
      '<i class="fa fa-fullscreen onetwo360-fullscreen-button"></div>' +
      '<i class="fa fa-search onetwo360-fullscreen-button"></div>' +
      '<img src="spinner.gif">'
    domElem.addChild @elems.root

    elemNames = Object.keys @style
    for i in [1..elemNames.length]
      @elems[elemNames[i]] = @elems.root.getChild(i-1)

    #{{{4 Properties that will be initialised later
    @width = undefined
    @height = undefined
    @logoFade = undefined

    #{{{4 Data structure for optimised style update
    @elemStyle = {}
    @styleCache = {}
    for key, _ of @elems
      @elemStyle[key] = @elems[key].style
      @styleCache[key] = {}

    #{{{4 Connect to parent dom node (`domId`), and get its width/height

    #{{{4 Update view
    @update()

  #{{{3 `View#update()` draw the view based on current content of the model
  View.prototype.update = ->
    @_fullscreen()
    @_root()
    @_logo()
    @_zoomLens()
    @_applyStyle()

  #{{{3 private utility functions for updating the view
  View.prototype._fullscreen= -> #{{{4
    if @model.fullscreen
      extend @style.root,
        position: "absolute"
        top: 0
        left: 0
        width: (@width = window.innerWidth)
        height: (@height = window.innerHeight)
    else
      extend @style.root,
        position: "relative"
        top: 0
        left: 0
        width: (@width = @defaultWidth)
        height: (@height = @defaultHeight)

  View.prototype._root = -> #{{{4
    extend @style.root,
      backgroundImage: "url(#{@model.frames.normal.urls[@model.frames.current]})"
      backgroundSize: "#{@width}px #{@height}px"

  View.prototype._logo = -> #{{{4
        top: h*.35 + "px"
        left: w*.25  + "px"
        fontSize: h*.2 + "px"
  View.prototype._zoomLens = -> #{{{4
    if @model.zoom.enabled
      current = @model.frames.current
      imgs = @model.frames.zoom # TODO only if current is loaded, else use @model.frames.normal
      extend @style.zoomLens,
        display: "block"
        left: 123
        top: 123
        backgroundImage: "url(#{imgs.urls[current]})" 
        backgroundSize: "#{imgs.width}px #{imgs.height}px"
        backgroundPosition: "#{123}px #{123}px"
    else
      extend @style.zoomLens,
        display: "none"

  View.prototype._applyStyle = -> #{{{4
    for elemId, css of @style
      for key, val of css
        if @styleCache[key] != val
          if typeof val == "number"
            @elemStyle[elemId][key] = "#{val}px"
          else
            @elemStyle[elemId][key] = val
          @styleCache[key] = val


  #{{{2 main
  window.newOneTwo360 = (cfg) ->
    undefined
#{{{1 Dummy/test-server
if isNodeJs
  express = require "express"
  app = express()
  app.use express.static __dirname
  port = 4444
  app.listen port
  console.log "devserver running on port #{port}"
