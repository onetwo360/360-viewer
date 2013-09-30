### Util (open) {{{1 ###
# General Utility functions {{{2
floatPart = (n) -> n - Math.floor(n)
nextTick = (fn) -> setTimeout fn, 0
identityFn = (e) -> e
nop = -> undefined
runOnce = (fn) -> (args...) -> if fn then fn args...; fn = undefined else undefined
extend = (target, sources...) -> #{{{3
  for source in sources
    for key, val of source
      target[key] = val
  target
asyncEach = (arr, fn, done) -> #{{{3
  done = runOnce done
  remaining = arr.length
  next = (err) ->
    done err if err
    done() if not --remaining
  fn elem, next for elem in arr
  undefined

# Browser abstractions, only added here, because of requirement of no dependencies, - would otherwise use jquery or similar {{{2
onComplete = (fn) -> do f = -> if document.readyState == "interactive" or document.readyState == "complete" then fn() else setTimeout f, 10 #{{{3
setStyle = (elem, obj) -> #{{{3
  for key, val of obj
    try
      elem.style[key] = val
    catch e
      e
  elem
elemAddEventListener = (elem, type, fn) -> #{{{3
  if elem.addEventListener
    elem.addEventListener type, fn, false
  else
    elem.attachEvent "on"+type, fn

# Browser shims {{{2
Date.now ?= -> (+ new Date())
body = document.getElementsByTagName("body")[0] # TODO: run this after onload

# Browser utils {{{2
cacheImgs = (urls, callback) -> #{{{3
  loadImg = (url, done) ->
    img = new Image()
    img.src = url
    img.onload = -> done()
  asyncEach urls, loadImg, callback

maximize = (elem) -> #{{{3
  oldbody = document.createElement "div"
  oldbody.style.display = "none"
  parent = elem.parentElement
  nextSibling = elem.nextSibling

  body.appendChild oldbody
  for node in (node for node in body.childNodes)
    oldbody.appendChild node if node != oldbody
  body.appendChild elem

  ->
    for node in (node for node in oldbody.childNodes)
      body.appendChild node
    oldbody.remove()
    if nextSibling
      elem.insertBefore nextSibling
    else
      parent.appendChild elem

# Touch handler {{{2
touchHandler = undefined
setTouch = undefined
do ->
  touch = undefined
  setTouch = (t) -> touch = t

  tapLength = 500 # maximum time for a click, - turns into a hold after that
  tapDist2 = 10*10 # maximum dragged (squared) distance for a click

  updateTouch = (touch, e) -> #{{{3
    x = e.clientX
    y = e.clientY
    touch.event = e
    touch.ddx = x - touch.x || 0
    touch.ddy = y - touch.y || 0
    touch.dx = x - touch.x0
    touch.dy = y - touch.y0
    touch.maxDist2 = touch.dx * touch.dx + touch.dy * touch.dy
    touch.time = Date.now() - touch.startTime
    touch.x = x
    touch.y = y

  startTouch = (e, handler, touchObj) -> #{{{3
    touch = touchObj
    touch.handler = handler
    touch.x0 = e.clientX
    touch.y0 = e.clientY
    touch.x = e.clientX
    touch.y = e.clientY
    touch.startTime = Date.now()
    updateTouch touch, e
    touch.ctx = handler.start(touch)
    holdHandler = ->
      if touch && !touch.holding && touch.maxDist2 < tapDist2
        touch.holding = true
        touch.handler.hold touch
    setTimeout holdHandler, tapLength

  moveTouch = (e) -> #{{{3
    updateTouch touch, e
    touch.ctx = touch.handler.move touch || touch.ctx

  stopTouch = (e) -> #{{{3
    touch.handler.end touch
    touch.handler.click touch if touch.maxDist2 < tapDist2 && touch.time < tapLength
    touch = undefined

  condCall = (fn) -> (e) -> #{{{3
    return undefined if !touch
    e.preventDefault?()
    fn(e.touches?[0] || e)

  documentTouch = runOnce -> #{{{3
    elemAddEventListener document, "mousemove", condCall moveTouch
    elemAddEventListener document, "touchmove", condCall moveTouch
    elemAddEventListener document, "mouseup", condCall stopTouch
    elemAddEventListener document, "touchend", condCall stopTouch

  touchHandler = (handler) -> #{{{3
    elemAddEventListener handler.elem, "mousedown", (e) ->
      e.preventDefault?()
      startTouch e, handler, {isMouse: true}
    elemAddEventListener handler.elem, "touchstart", (e) ->
      e.preventDefault?()
      startTouch e.touches[0], handler, {}

    documentTouch()
    handler.start ||= nop
    handler.move ||= nop
    handler.end ||= nop
    handler.drag ||= nop
    handler.click ||= nop
    handler.hold ||= nop

    handler

# 360º specific (proprietary) {{{1
do ->
  zoomSize = 200
  eventHandler = undefined
  default360Config = #{{{3
    autorotate: true
    imageURLs: undefined

  # Create zoom lens element{{{3
  onComplete ->
    body = document.getElementsByTagName("body")[0]
    zoomLens = document.createElement "div"
    setStyle zoomLens,
      position: "absolute"
      overflow: "hidden"
      width: zoomSize + "px"
      height: zoomSize + "px"
      border: "0px solid black"
      cursor: "default"
      backgroundColor: "rgba(100,100,100,0.8)"
      borderRadius: (zoomSize/2) + "px"
      #borderBottomRightRadius: (zoomSize/5) + "px"
      boxShadow: "0px 0px 40px 0px rgba(255,255,255,.7) inset, 4px 4px 9px 0px rgba(0,0,0,0.5)"
      display: "none"
    zoomLens.id = "zoomLens360"
    body.appendChild zoomLens

  # Add 360 elem to page {{{3
  window.onetwo360 = (cfg) ->

    currentAngle = 0
    width = undefined
    doZoom = undefined
    endZoom = undefined
    recache = nop # TODO: replace with function that reloads animation into cache

    # Create img element for writing animation to {{{3
    elem = document.getElementById cfg.elem_id
    img = new Image()
    eventHandler = touchHandler {elem: img}
    elem.appendChild img
    nextTick -> get360Config()

    # Get config+imagelist from server (DUMMY IMPLEMENTATION) {{{3
    get360Config = ->
      nextTick -> # TODO: replace with  async ajax from server
        serverConfig =
          imageURLs: ("testimg/#{i}.jpg" for i in [1..36])
        cfg = extend {}, default360Config, serverConfig, cfg
        init360Elem()
  
    # Initialise the 360º object {{{3
    init360Elem = ->
      cache360Images ->
        setStyle img,
          width: cfg.request_width + "px"
          height: cfg.request_height + "px"
          cursor: "url(res/cursor_rotate.cur),move"
        width = cfg.request_width

        if cfg.autorotate
          autorotate init360Controls
        else
          init360Controls()
  
    # Load images into cache, and possibly autorotate {{{3
    cache360Images = (done) -> cacheImgs cfg.imageURLs, done

    # Autorotate {{{3
    autorotate = (done) ->
      i = 0
      showNext = ->
        if i < cfg.imageURLs.length
          img.src = cfg.imageURLs[i++]
          #img.onload = -> setTimeout showNext, 10 # doesnt work in ie8
          setTimeout showNext, 100
        else
          done()
      showNext()
  
    # Update the current viewed image {{{3
    updateImage = ->
      img.src = cfg.imageURLs[floatPart(currentAngle/Math.PI/2) * cfg.imageURLs.length | 0]

    # init controls {{{3
    init360Controls = ->
      eventHandler.move = (t) ->
        if t.holding || t.zoom360
          nextTick -> doZoom t
        else
          currentAngle -= 2 * Math.PI * t.ddx / width
          updateImage()
      eventHandler.hold = (t) -> nextTick -> doZoom t
      eventHandler.end = (t) -> nextTick -> endZoom t
      eventHandler.click = (t) -> if t.isMouse
        t.zoom360 = true
        nextTick -> setTouch t

    # Zoom handling {{{3
    doZoom = (t) ->
      zoomLens = document.getElementById "zoomLens360"
      zoomWidth = 810
      zoomHeight = 789
      largeUrl = img.src
      imgPos = img.getBoundingClientRect()
      touchX = .5
      touchY = if t.isMouse then .5 else 1.1
      zoomLeftPos = t.x + body.scrollLeft - zoomSize * touchX
      zoomTopPos = t.y + body.scrollTop - zoomSize * touchY
      bgLeft = zoomSize*touchX-((t.x-imgPos.left) * zoomWidth / (img.width))
      bgTop = zoomSize*touchY-((t.y-imgPos.top) * zoomHeight / (img.height))
      setStyle zoomLens,
        display: "block"
        position: "absolute"
        left: zoomLeftPos + "px"
        top: zoomTopPos + "px"
        backgroundImage: "url(#{largeUrl})"
        backgroundPosition: "#{bgLeft}px #{bgTop}px"
        backgroundRepeat: "no-repeat"
      #img.style.cursor = "crosshair" # cannot reset cursor style, as it will mess up zoom lens on iOS

    endZoom = (t) ->
      img.style.cursor = "url(res/cursor_rotate.cur),move"
      (document.getElementById "zoomLens360").style.display = "none"
      recache()
