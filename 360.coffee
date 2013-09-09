### Util (open) {{{1 ###
# General Util {{{2
floatPart = (n) -> n - Math.floor(n)
extend = (target, sources...) ->
  for source in sources
    for key, val of source
      target[key] = val 
  target
nextTick = (fn) -> setTimeout fn, 0
identityFn = (e) -> e
runOnce = (fn) -> (args...) -> if fn then fn args...; fn = undefined else undefined
asyncEach = (arr, fn, done) -> #{{{3
  done = runOnce done
  remaining = arr.length
  next = (err) ->
    done err if err
    done() if not --remaining
  fn elem, next for elem in arr
  undefined
# Browser abstractions, only added here, because of requirement of no dependencies, - would otherwise use jquery or similar {{{2
xhr =
setStyle = (elem, obj) -> elem.style[key] = val for key, val of obj
onComplete = (fn) -> do f = -> if document.readyState == "interactive" or document.readyState == "complete" then fn() else setTimeout f, 10
elemAddEventListener = (elem, type, fn) ->
  if elem.addEventListener
    elem.addEventListener type, fn, false
  else
    elem.attachEvent? "on"+type, fn
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

  document.body.appendChild oldbody
  for node in (node for node in document.body.childNodes)
    oldbody.appendChild node if node != oldbody
  document.body.appendChild elem

  ->
    for node in (node for node in oldbody.childNodes)
      document.body.appendChild node
    oldbody.remove()
    if nextSibling
      elem.insertBefore nextSibling
    else
      parent.appendChild elem

# Touch handler {{{2
touchHandler = undefined
do ->
  # TODO: mostly dummy so far...
  touches = []
  multitouch = false
  touch = false

  startTouch = (e, handler) ->
    touch =
      handler: handler
      x0: e.clientX
      y0: e.clientY
      x: e.clientX
      y: e.clientY
    updateTouch touch, e
    touch.ctx = handler.start(touch)

  updateTouch = (touch, e) ->
    x = e.clientX
    y = e.clientY
    touch.event = e
    touch.ddx = x - touch.x || 0
    touch.ddy = y - touch.y || 0
    touch.dx = x - touch.x0
    touch.dy = y - touch.y0
    touch.x = x
    touch.y = y

  moveTouch = (e) ->
    updateTouch touch, e
    touch.ctx = touch.handler.move touch

  stopTouch = (e) ->
    updateTouch touch, e
    touch.handler.endtouch
    touch = undefined

  windowTouch = runOnce ->
    elemAddEventListener window, "mousemove", (e) ->
      return undefined if !touch
      e.preventDefault()
      moveTouch e

    elemAddEventListener window, "touchmove", (e) ->
      return undefined if !touch
      e.preventDefault()
      moveTouch e.touches[0]

    elemAddEventListener window, "mouseup", (e) ->
      return undefined if !touch
      e.preventDefault()
      stopTouch e

    elemAddEventListener window, "touchend", (e) ->
      return undefined if !touch
      e.preventDefault()
      stopTouch e.touches[0]

  touchHandler = (handler) ->
    elemAddEventListener handler.elem, "mousedown", (e) ->
      e.preventDefault()
      startTouch e, handler

    elemAddEventListener handler.elem, "touchstart", (e) ->
      e.preventDefault()
      startTouch e.touches[0], handler

    windowTouch()
    handler.start ||= identityFn
    handler.move ||= identityFn
    handler.end ||= identityFn

# 360º specific (proprietary) {{{1
### Notes {{{2
{{{3 TODO

- cursor icon
- icons - zoom-lense(desktop), fullscreen, close(fullscreen)
- logo
- fullscreen(on both desktop and mobile)
- zoom(on desktop, mobile postponed)
- multitouch
- talk with api
- labels/markers
- browser-support: IE8+, iOS 5+ Android 4+

{{{3 Done

- image caching / preloader
- rotate - drag
- singletouch
- animate on load
- drag

{{{3 Interaction

- drag left/right: rotate
  - rotation = x-drag scaled
- tap/click: fullscreen, click on X or outside centered image to close
- zoom (multitouch+multidrag: iOS + android 2.3.3+, zoom-button with lens on desktop)

{{{3 Why img.src replacement

When targeting mobile devices,  
and possibly several 360º views on a page,
memory is more likely to be bottleneck than CPU.

We therefore just preload the compressed images
into the browsers component cache, 
and decompress them at render time.

The actual rendering is then just replacing
the `src` of an image tag, - also making it work
in non-HTML5 browsers, such as IE8, 
which we also need to support.

###
# Controller {{{2 

do ->
  default360Config = #{{{3
    autorotate: true
    imageURLs: undefined

  # Add 360 elem to page {{{3
  window.onetwo360 = (cfg) ->

    currentAngle = 0
    width = undefined

    # Create img element for writing animation to {{{3
    elem = document.getElementById cfg.elem_id
    img = new Image()
    elem.appendChild img
    nextTick -> get360Config()

    # get config+imagelist from server {{{3
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
          img.onload = -> setTimeout showNext, 10
        else
          done()
      showNext()
  
    updateImage = -> #{{{3
      img.src = cfg.imageURLs[floatPart(currentAngle/Math.PI/2) * cfg.imageURLs.length | 0]

    # init controls {{{3
    init360Controls = ->
      touchHandler
        elem: img
        start: (t) -> undefined
        move: (t) ->
          currentAngle -= 2 * Math.PI * t.ddx / width
          updateImage()
        end: (t) -> undefined
