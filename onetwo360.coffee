#{{{1 Minification
#
# define `isNodeJs` and `runTest` in such a way that they will be fully removed by `uglifyjs -mc -d isNodeJs=false -d runTest=false `
#
if typeof isNodeJs == "undefined" or typeof runTest == "undefined" then do ->
  root = if typeof global == "undefined" then window else global
  root.isNodeJs = (typeof window == "undefined") if typeof isNodeJs == "undefined"
  root.runTest = true if typeof runTest == "undefined"

#{{{1 Testing
if runTest
  if isNodeJs
    testcount = 0
  else
    testcount = 6
  currentTestId = 0
  console.log "1..#{testcount}"
  expect = (expected, result, description) ->
    if JSON.stringify(expected) == JSON.stringify(result)
      console.log "ok #{++currentTestId} #{description || ""}"
    else
      console.log "not ok #{++currentTestId} + #{description || ""}" +
        "expected:#{JSON.stringify expected}" +
        "got:#{JSON.stringify result}"
 
#{{{1 Version 2
if !isNodeJs
  #{{{2 utility
  #{{{2 shim
  Object.keys ?= (obj) -> (key for key, _ of obj)
  #{{{3 ajax
  XHR = XMLHttpRequest
  legacy = false
  if typeof (new XHR).withCredentials != "boolean"
    legacy = true
    XHR = XDomainRequest

  ajax = (url, data, cb) ->
    xhr = new XHR()
    xhr.onload = -> cb? (if xhr.status == 200 then null else xhr.status), xhr.responseText
    xhr.open (if data then "POST" else "GET"), url, !!cb
    xhr.send data
    return xhr.responseText if !cb

  if runTest then do ->
    ajax "//cors-test.appspot.com/test", undefined, (err, result) -> expect result, '{"status":"ok"}', "async ajax"
    ajax "//cors-test.appspot.com/test", "foo", (err, result) -> expect result, '{"status":"ok"}', "async ajax post"
    
  #{{{3 extend
  extend = (target, source) ->
    for key, val of source
      target[key] = val
    return target

  if runTest then do ->
    a = {a: 1, b:2}
    expect (extend a, {b:3, c:4}), {a:1,b:3,c:4}, "extend"
    expect a, {a:1,b:3,c:4}, "extend"

  #{{{3 deepCopy
  deepCopy = (obj) ->
    if typeof obj == "object"
      if obj.constructor == Array
        result = []
        result.push deepCopy(e) for e in obj
      else
        result = {}
        result[key] = deepCopy(val) for key, val of obj
      return result
    else
      return obj

  if runTest then do ->
    a = {a: [1,2,3]}
    b = deepCopy a
    b.b = "c"
    b.a[1] = 3
    expect a, {a: [1,2,3]}, "deepcopy original unmutated"
    expect b, {a: [1,3,3], b: "c"}, "deepcopy copy with mutations"

  #{{{2 Model
  #
  # The model is just a json object that is passed around. This has all the state for the onetwo360 viewer
  #
  defaultModel =
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
    spinOnLoadFPS: 60
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
    @defaultWidth = model.width || domElem.offsetWidth
    @defaultHeight = model.height || domElem.offsetHeight

    #{{{4 Style
    ###
    extend domElem.style,
      display: "inline-block"
      width: @defaultWidth + "px"
      height: @defaultHeight + "px"
      ###
    @style =
      root:
        display: "inline-block"
        cursor: "url(res/cursor_rotate.cur),move"

      # NB: order of the following keys needs to be the exactly same as the children of the dom root node
      image:
        width: "100%"
        height: "100%"
      zoomLens:
        display: "block"
        position: "absolute"
        overflow: "hidden"
        width: @model.zoom.lensSize
        height: @model.zoom.lensSize
        border: "0px solid black"
        cursor: "default"
        backgroundColor: if !legacy then "rgba(100,100,100,0.8)" else undefined
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
      backgroundColor: if !legacy then "rgba(255,255,255,0)" else undefined
      top: "80%"
      fontSize: @defaultHeight * .08
      padding: @defaultHeight * .02
    extend @style.btnFull, buttonStyle
    extend @style.btnZoom, buttonStyle

    #{{{4 Dom element creation
    @elems = {}
    @elems.root = document.createElement "div"
    @elems.root.innerHTML =
      '<img>' +
      '<div class="onetwo360-zoom-lens"></div>' +
      '<i class="icon-OneTwo360Logo"></i>' +
      '<i class="fa fa-fullscreen onetwo360-fullscreen-button"></i>' +
      '<i class="fa fa-search onetwo360-fullscreen-button"></i>' +
      '<img src="spinner.gif">'
    domElem.appendChild @elems.root

    elemNames = Object.keys @style
    for i in [1..elemNames.length-1]
      @elems[elemNames[i]] = @elems.root.childNodes[i-1]

    #{{{4 Properties that will be initialised later
    @width = undefined
    @height = undefined
    @logoFade = undefined
    @imgSrc = undefined

    #{{{4 Data structure for optimised style update
    @elemStyle = {}
    @styleCache = {}
    for key, _ of @elems
      @elemStyle[key] = @elems[key].style
      @styleCache[key] = {}

    #{{{4 Connect to parent dom node (`domId`), and get its width/height

    #{{{4 Update view
    @update()
    return this

  #{{{3 `View#update()` draw the view based on current content of the model
  View.prototype.update = ->
    @_fullscreen()
    @_root()
    @_logo()
    @_zoomLens()
    @_image()
    @_applyStyle()

  #{{{3 private utility functions for updating the view
  View.prototype._fullscreen= -> #{{{4
    if @model.fullscreen
      extend @style.root,
        position: "absolute"
        top: 0
        left: 0
        width: (@width = window.innerWidth || document.documentElement.clientWidth || document.body.clientWidth)
        height: (@height = window.innerHeight || document.documentElement.clientHeight || document.body.clientHeight)
    else
      extend @style.root,
        position: "relative"
        top: 0
        left: 0
        width: (@width = @defaultWidth)
        height: (@height = @defaultHeight)

  View.prototype._root = -> #{{{4
    undefined
    #extend @style.root,
      #backgroundImage: "url(#{@model.frames.normal.urls[@model.frames.current]})"
      #backgroundSize: "#{@width}px #{@height}px"

  View.prototype._logo = -> #{{{4
        top: @height*.35 + "px"
        left: @width*.25  + "px"
        fontSize: @height*.2 + "px"
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

  View.prototype._image = -> #{{{4
    imgSrc = @model.frames.normal.urls[@model.frames.current]
    if imgSrc != undefined && imgSrc != @imgSrc
      @elems.image.src = imgSrc
      @imgSrc = imgSrc

  View.prototype._applyStyle = -> #{{{4
    for elemId, css of @style
      for key, val of css
        if @styleCache[elemId][key] != val
          val = val + "px" if typeof val == "number"
          if true || !runTest
            @elemStyle[elemId][key] = val
          else
            try
              @elemStyle[elemId][key] = val
            catch e
              console.log "Cannot set #{key}:#{val} on #{elemId}"
              throw e

          @styleCache[elemId][key] = val

  #{{{3 test
  if runTest
    testModel = deepCopy(defaultModel)
    testView = undefined
    do ->
      for frames in [testModel.frames.normal, testModel.frames.zoom]
        testModel.width = frames.width = 1000
        testModel.height = frames.height = 447
        for i in [1..52]
          frames.urls.push "/testdata/#{i}.jpg"
      t0 = +(new Date())
      testView = new View(testModel, "threesixtyproduct")
      t1 = +(new Date())
      testModel.frames.current = 0
      testModel.fullscreen = true
      testView.update()


  #{{{2 Loader / caching
 
  #{{{3 Cache frames
  cacheFrames = (frameset, cb) ->
    frameset.loaded = []
    count = 0
    for i in [0..frameset.urls.length - 1]
      img = new Image()
      img.onload = ((i) -> -> frameset.loaded[i] = +(new Date()); (cb?() if ++count == frameset.urls.length))(i)
      img.src = frameset.urls[i]

  #{{{3 Incremental load
  incrementalLoad = (model, view, cb) ->
    loadStart = +(new Date())
    lastTime = 0
    lastSetFrame = 0
    allLoaded = false
    model.frames.current = 0
    incrementalUpdate = ->
      count = 0
      maxTime = loadStart
      while model.frames.normal.loaded[count]
        maxTime = Math.max(model.frames.normal.loaded[count], maxTime)
        ++count
      if count > model.frames.current + 1
        now = +(new Date())
        loadTime = (maxTime - loadStart) / count
        if lastTime + Math.max(loadTime, 1000/model.spinOnLoadFPS) < now
          lastTime = now
          lastSetFrame = ++model.frames.current
          view.update()
      if (model.frames.current == lastSetFrame) && (model.frames.current < model.frames.normal.urls.length - 1)
        setTimeout incrementalUpdate, 0
      else
        cb()

    if model.spinOnLoadFPS
      cacheFrames model.frames.normal, -> console.log "loaded"
      incrementalUpdate()
    else
      cacheFrames model.frames.normal cb


  #{{{3 test
  if runTest
    incrementalLoad testModel, testView, -> console.log "spinned"


  #{{{2 main
  window.onetwo360 = (cfg) ->
    undefined
#{{{1 Dummy/test-server
if isNodeJs
  express = require "express"
  app = express()
  app.use express.static __dirname
  app.use "/api", (req, res, next) ->
    data = ""
    req.on "data", (d) -> data += d
    req.on "end", ->
      res.header 'Access-Control-Allow-Origin', "*"
      res.header 'Access-Control-Allow-Methods', 'GET,PUT,POST,DELETE'
      res.header 'Access-Control-Allow-Headers', 'Content-Type'
      console.log req.originalUrl, data
      res.json {ok:true}
      res.end()



  port = 4444
  app.listen port
  console.log "devserver running on port #{port}"
