urls = ("testimg/#{i}.jpg" for i in [1..36])
rootElem = document.getElementById "img360"

### Notes {{{1

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

----

Wanted features

- performant, and working on IE8+,mobile,...
  - component caching
- rotate
- zoom
- labels
- touch

###

### Util {{{1 ###
nextTick = (fn) -> setTimeout fn, 0
setStyle = (elem, obj) -> elem.style[key] = val for key, val of obj
### maximize {{{2 ###
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

### Image caching {{{1 

Creating a temporary DOM object for each image
is enough to get them loaded. 

####
cacheImgs = (urls) -> (new Image).src = url for url in urls
cacheImgs urls

### Create image element {{{1 ###
img = new Image()
img.src = urls[0]
img.onload = ->
  setStyle img,
    width: img.width + "px"
    height: img.height + "px"
rootElem.appendChild(img)
img.onmousemove = (e) ->

fullscreen = new Image()
fullscreen.src = "fullscreenIcon"
setStyle fullscreen,
  position: "absolute"
  top: "0px"
  left: "0px"

### Event / gesture handling {{{1 ###
move = (x) -> img.src = urls[urls.length - 1 - ((20 + Math.round(x / 20)) % urls.length)]
img.ontouchstart = img.ontouchend = (e) -> e.preventDefault()
img.ontouchmove = (e) -> move e.touches[0].clientX
img.onmousemove = (e) -> move e.clientX
img.onclick = -> img.onclick = maximize img

