# Viewer client for http://onetwo360.com/
#
#{{{1 Status
#
#{{{2 Current progress
#
# - backlog-current
#   - fix android full-screen issues
#   - IE8 issues: zoom lense not working as we are using css positioned background
#   - ensure portability IE/8+,Android/2.3+,iOS/6+,Opera/12+,Chrome,Firefox,Safari
#   - more documentation
# - in progress
#   - move technical documentation into relevant parts of source
#   - major rewrite - getting features from previous milestones to work
#   - unit testing, and continous integration with travis and testling
# - 0.1.0 - January/February 2014
#   - better decoupling of model, view and control
#   - support for sending statistics/logging to server
#   - automatic removal of tests and development code from production version (via uglify-js)
#   - optimise "Animate on load" to run during load, - increasing perceived load performance significantly
#
#{{{2 Changelog
#
# - 0.0.0-MILESTONE-2 - December 2013 / January 2014
#   - log util, sending log to server
#   - locally cached development data for easier development / automated testing
#   - requestAnimationFrame for smoother animation
#   - open source - available on github
#   - use solapp for automatic minification and easier development
# - 0.0.0-MILESTONE-1 - October/November 2013
#   - avoid moving zoom-lens beyond image / constraint on edge
#   - allow interaction during rotate
#   - connect with API
#   - gif spinner indicator
#   - logo on top with fade-out 
#   - zoom button
#   - fullscreen button
#   - fullscreen(on both desktop and mobile)
#   - dynamic load hi-res images (on fullscreen after .5s same image + zoom use scaled lo-res when starting) + recache lo-res
# - 0.0.0-MILESTONE-0 - September 2013
#   - Version up and running
#   - Browser-support: IE8+, iOS 5+ Android 4+
#   - Rotate on drag
#   - Handle touch and mouse
#   - Zoom-lens effect(on desktop+mobile)
#   - Zoom on click (on desktop) and on hold (on mobile)
#   - Cursor icon
#   - Image caching / preloader
#   - Animate on load
#
#{{{2 Backlog
# 
# - next
#   - icons not requiring full font-awesome
#   - bower-publish
# - later
#   - multitouch - see if we can enable zoom/scroll by no-preventDefault when multifinger (no, difficult, look into this later)
#   - customer logo(postponed due to no customer logo links in sample data from the api)
#   - labels/markers/interaction points (postponed due to no markers/interaction points in the sample data from the api)
#   - fullscreen issues on android when user-scaleable
#   - maybe close fullscreen on click outside image
#   - test/make sure it works also wit small data sets of 1 picture
#   - icons / documentation - zoom-lense(desktop), fullscreen, close(fullscreen)
#   - thumbnails when few pictures (maybe instead of drag)
# 
#
#
#{{{2 Refactor notes
#
# - compatibility layer
# - element with 360-rotation
#   - current frame
#   - current-frame overlays (
#   - zoom lens
#   - general overlays
# - event handling
# - cache handling
#
# - model
#   - current frame
#   - 
#{{{1 Literate source code
#{{{2 Minification
#
# define `isNodeJs` and `runTest` in such a way that they will be fully removed by `uglifyjs -mc -d isNodeJs=false -d runTest=false `
#
if typeof isNodeJs == "undefined" or typeof runTest == "undefined" then do ->
  root = if typeof global == "undefined" then window else global
  root.isNodeJs = (typeof window == "undefined") if typeof isNodeJs == "undefined"
  root.runTest = true if typeof runTest == "undefined"

#{{{2 Testing
if runTest && !isNodeJs
  testcount = 6
  currentTestId = 0
  console.log "1..#{testcount}"
  testDone = 0
  expect = (expected, result, description) ->
    if JSON.stringify(expected) == JSON.stringify(result)
      console.log "ok #{++currentTestId} #{description || ""}"
      log "test ok", currentTestId, description, expected
    else
      console.log "not ok #{++currentTestId} + #{description || ""}" +
        "expected:#{JSON.stringify expected}" +
        "got:#{JSON.stringify result}"
      log "test failed", currentTestId, description, expected, result
    ++testDone
    if testDone == testcount
      log "tests done"
      syncLog()
 
#{{{2 log
if !isNodeJs
  #
  # We want to send logging and statistics to server, 
  # but not drain battery nor exhaust the network,
  # so the log is saved to memory, and then only send across the network 
  # when more than `logBeforeSync` entries has been collected, 
  # or the user leaves the page. It is also throttled, 
  # so logging data are sent no more than once every `syncDelay` milliseconds.
  #
  # On legacy browsers we cannot send the log when the user leave the page,
  # so there we just send update every `syncDelay` milliseconds.
  #
  log = undefined
  syncLog = undefined
  do ->
    logId = Math.random()
    logUrl = "/api/log"
    logData = []
    logSyncing = false
    logsBeforeSync = 200
    syncDelay = 400
    syncLog = ->
      if !logSyncing
        try
          logContent = JSON.stringify logData
        catch e
          logContent = "Error stringifying log"
        logSyncing = logData
        logData = []
        ajax logUrl, logContent, (err, result) ->
          setTimeout (-> logSyncing = false), syncDelay
          if err
            log "logsync error", err
            logData = logSyncing.concat(logData)
          else
            logData.push [+(new Date()), "log sync'ed", logId]
            syncLog() if legacy && logData.length > 1

    log = (args...) ->
      logData.push [+(new Date()), args...]
      syncLog() if logData.length > logsBeforeSync || legacy

    setTimeout (->
      elemAddEventListener window, "error", -> log "window.onerror", err?.message
      elemAddEventListener window, "beforeunload", ->
        log "window.beforeunload"
        try
          ajax logUrl, JSON.stringify logData # blocking POST request
        catch e
          undefined
        undefined
    ), 0
    log "starting", logId, window.performance


#{{{2 utility
if !isNodeJs
  #{{{3 shim
  Object.keys ?= (obj) -> (key for key, _ of obj)
  #{{{3 ajax
  XHR = XMLHttpRequest
  legacy = false
  if typeof (new XHR).withCredentials != "boolean"
    legacy = true
    XHR = XDomainRequest

  ajax = (url, data, cb) ->
    xhr = new XHR()
    xhr.onerror = (err) -> cb? err || true
    xhr.onload = -> cb? null, xhr.responseText
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


  #{{{3 add event listener
  elemAddEventListener = (elem, type, fn) ->
    if elem.addEventListener
      elem.addEventListener type, fn, false
    else
      elem.attachEvent "on"+type, fn

#{{{2 Model
if !isNodeJs
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
    spinOnLoadFPS: 30
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

  #{{{3 test
  if runTest
    testModel = deepCopy(defaultModel)
    do ->
      testModel.frames.zoom.width = 1000
      testModel.frames.zoom.height = 447
      #testModel.width = testModel.frames.normal.width = 1000
      #testModel.height = testModel.frames.normal.height = 447
      testModel.width = testModel.frames.normal.width = 500
      testModel.height = testModel.frames.normal.height = 223
      for i in [1..52] by 1
        testModel.frames.normal.urls.push "/testdata/#{i}.jpg"
        #testModel.frames.normal.urls.push "/testdata/#{i}.normal.jpg"
        testModel.frames.zoom.urls.push "/testdata/#{i}.jpg"

  #{{{2 View
if !isNodeJs
  #{{{2 doc/notes
  #
  # When targeting mobile devices,
  # and possibly several 360º views on a page,
  # memory is more likely to be bottleneck than CPU.
# 
# We therefore just preload the compressed images
# into the browsers component cache, 
# and decompress them at render time.
# (This is a time/space-tradeof).
#
# The actual rendering is just replacing
# the `src` of an image tag, - also making it work
# in non-HTML5 browsers, such as IE8, 
# which we also need to support.
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

  #{{{3 `View#update()` request redraw the view based on current content of the model
 
  View.prototype.update = ->
    return if @updateReq
    @updateReq = true
    self = this
    setTimeout (-> self._update(); self.updateReq = false), 0

  View.prototype._update = ->
    log "View#_update"
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
              log "Cannot set #{key}:#{val} on #{elemId}"
              throw e

          @styleCache[elemId][key] = val

  #{{{3 test
  if runTest
    testView = undefined
    do ->
      t0 = +(new Date())
      testView = new View(testModel, "threesixtyproduct")
      t1 = +(new Date())
      testModel.frames.current = 0
      testModel.fullscreen = false
      testView.update()


  #{{{2 Loader / caching
if !isNodeJs
  #{{{3 Cache frames
  cacheFrames = (frameset, cb) ->
    frameset.loaded = []
    count = 0
    log "caching frameset", frameset.urls[0]
    for i in [0..frameset.urls.length - 1]
      img = new Image()
      img.onload = ((i) -> ->
          frameset.loaded[i] = +(new Date())
          if ++count == frameset.urls.length
            log "done caching frameset", frameset.urls[0]
            cb?()
        )(i)
      img.src = frameset.urls[i]

  #{{{3 Incremental load
  incrementalLoad = (model, view, cb) ->
    loadStart = +(new Date())
    lastTime = undefined
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
        lastTime ?= now
        loadTime = (maxTime - loadStart) / count
        frameTime = Math.max(loadTime, 1000/model.spinOnLoadFPS)
        if lastTime + frameTime < now
          while lastTime + frameTime < now
            lastSetFrame = model.frames.current = Math.min(count - 1, model.frames.current + 1)
            lastTime += frameTime
          lastTime = now
          view.update()

      if (model.frames.current == lastSetFrame) && (model.frames.current < model.frames.normal.urls.length - 1)
        setTimeout incrementalUpdate, 0
      else
        log "finished incremental load animation"

    if model.spinOnLoadFPS
      cacheFrames model.frames.normal
      log "starting incremental load animation"
      incrementalUpdate()
    else
      cacheFrames model.frames.normal cb


  t0 = +new Date()
  #{{{3 test
  if runTest
    incrementalLoad testModel, testView, -> log "spinned #{+new Date() - t0}"

  #{{{2 User interaction/touch
  elemAddEventListener document, "mousemove", (e) -> log "mousemove", e.clientX, e.clientY
  elemAddEventListener document, "touchmove", (e) -> log "touchmove", e.touches

  #{{{2 main
if !isNodeJs
  window.onetwo360 = (cfg) ->
    console.log "HERE"
    undefined
#{{{2 Dummy/test-server
if isNodeJs
  express = require "express"
  app = express()
  app.use (req, res, next) ->
    res.header 'Cache-Control', "max-age=30, public"
    next()
  app.use express.static __dirname
  lastTime = 0
  app.use "/api", (req, res, next) ->
    data = ""
    req.on "data", (d) -> data += d
    req.on "end", ->
      res.header 'Access-Control-Allow-Origin', req.headers.origin || "*"
      res.header 'Access-Control-Max-Age', 0
      res.header 'Access-Control-Allow-Credentials', true
      res.header "Content-Type", "text/plain"
      res.json "{\"ok\":true}"
      res.end()
      try
        console.log req.originalUrl
        for event in JSON.parse data
          console.log event[0] - lastTime, event
          lastTime = event[0]
          if process.argv[2] == "test"
            process.exit 1 if event[1] == "test failed"
            process.exit 0 if event[1] == "tests done"
      catch e
        console.log e

  port = 4444
  app.listen port
  console.log "devserver running on port #{port}"
