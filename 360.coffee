### Util (open) {{{1 ###
# General Util {{{1
nextTick = (fn) -> setTimeout fn, 0
setStyle = (elem, obj) -> elem.style[key] = val for key, val of obj

# Creating a temporary DOM object for each image is enough to get them loaded into cache. 
identityFn = (e) -> e
asyncEach = (arr, fn, done) ->
  count = arr.len
  next = (err) -> if --count then done err; done = identityFn else done()
  fn elem, next for elem in arr
cacheImgs = (urls) -> (new Image).src = url for url in urls
onComplete = (fn) -> do f = -> if document.readyState == "interactive" or document.readyState == "complete" then fn() else setTimeout f, 10

### maximize {{{3 ###
maximize = (elem) ->
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

# 360º specific (proprietary) {{{1
### Notes {{{2


- nb cursoricon
- icon

- ikoner: linse(desktop), fullscreen, ect. luk
- zoom-lens, 
- mobile: fullscren
- animate on load
- iOS - 5+, Android 4+

------

{{{3 Comments on System specification

Idea for embedding: maybe just:
<img src="http://cdn.onetwo360.com/product.jpg" ...>, and then automatically transforms these into 360-scripts, ie. no javascript coding needed for embedding... but plugin can be configured with JS. 

{{{3 Done

- image caching / preloader
- rotate proof of concept

{{{3 Tasks/roadmap

- scale to elem-size
- touch handler/interpretion
- fullscreen
- communication with API

{{{3 Structure

- view component
- touch handler
- controller touch-events to view-changes

{{{3 Interaction

- drag left/right: rotate
  - rotation = x-drag scaled
- tap/click: fullscreen, click on X or outside centered image to close
- zoom (multitouch+multidrag: iOS + android 2.3.3+, zoom-button with lens on desktop)

-----
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

{{{3 Wanted features

- performant, and working on IE8+,mobile,...
  - component caching
- rotate
- zoom
- labels
- touch

###

# Controller {{{2 
urls = ("testimg/#{i}.jpg" for i in [1..36])

onComplete ->
  re = /^https?:\/\/cdn.onetwo360.com\//
  re = /^file:.*testimg\// # TODO: remove this line, temporarily here before deployment
  console.log "HERE"
  for elem in document.getElementsByTagName "img"
    if re.exec elem.src
      _360 elem

# 360º viewer {{{2 
_360 = (img) ->
  
  w = img.width
  h = img.height
  console.log w, h

  urls = urls.map (url) -> url.replace /(\?.*)?$/, "?#{w}x#{h}"
  cacheImgs urls

  ### Create image element {{{3 ###
  img.src = urls[0]
  img.onload = ->
    setStyle img,
      width: img.width + "px"
      height: img.height + "px"
  img.onmousemove = (e) ->
  
  fullscreen = new Image()
  fullscreen.src = "fullscreenIcon"
  setStyle fullscreen,
    position: "absolute"
    top: "0px"
    left: "0px"
  
  ### Event / gesture handling {{{2 ###
  scale = (x) -> ((x/w)*1.5*urls.length)|0
  move = (x) -> img.src = urls[urls.length - 1 - (scale(x) % urls.length)]
  img.ontouchstart = img.ontouchend = (e) -> e.preventDefault()
  img.ontouchmove = (e) -> move e.touches[0].clientX
  img.onmousemove = (e) -> move e.clientX
  img.onclick = -> img.onclick = maximize img
