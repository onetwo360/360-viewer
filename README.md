# 360-viewer 0.0.8

Widget for showing OneTwo360 images/animations
[![ci](https://secure.travis-ci.org/onetwo360/360-viewer.png)](http://travis-ci.org/onetwo360/360-viewer)

[![browser support](https://ci.testling.com/onetwo360/360-viewer.png)](http://ci.testling.com/onetwo360/360-viewer)


# Documentation
## Roadmap
### Done

#### Milestone 2 - December 2013 / January 2014

- log util, sending log to server
- locally cached development data for easier development / automated testing
- requestAnimationFrame for smoother animation
- open source - available on github
- use solapp for automatic minification and easier development

#### Milestone 1 - October/November 2013

- avoid moving zoom-lens beyond image / constraint on edge
- allow interaction during rotate
- connect with API
- gif spinner indicator
- logo on top with fade-out 
- zoom button
- fullscreen button
- fullscreen(on both desktop and mobile)
- dynamic load hi-res images (on fullscreen after .5s same image + zoom use scaled lo-res when starting) + recache lo-res

#### Milestone 0 - September 2013

- Version up and running
- Browser-support: IE8+, iOS 5+ Android 4+
- Rotate on drag
- Handle touch and mouse
- Zoom-lens effect(on desktop+mobile)
- Zoom on click (on desktop) and on hold (on mobile)
- Cursor icon
- Image caching / preloader
- Animate on load

### TODO
#### Initial version

- refactor
- collect statistics
- fix android full-screen issues
- IE - test
  - IE8 issues: zoom lense not working as we are using css positioned background

#### Future

- multitouch - see if we can enable zoom/scroll by no-preventDefault when multifinger (no, difficult, look into this later)
- customer logo(postponed due to no customer logo links in sample data from the api)
- labels/markers/interaction points (postponed due to no markers/interaction points in the sample data from the api)
- fullscreen issues on android when user-scaleable
- maybe close fullscreen on click outside image
- test/make sure it works also wit small data sets of 1 picture
- icons / documentation - zoom-lense(desktop), fullscreen, close(fullscreen)
- animate during load, instead of animate on load
- thumbnails when few pictures (maybe instead of drag)
- smoother animate on load


## Technical approach

### Rendering

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

## Refactor notes

- compatibility layer
- element with 360-rotation
  - current frame
  - current-frame overlays (
  - zoom lens
  - general overlays
- event handling
- cache handling

- model
  - current frame
  - 
# Literate source code
The globalDefines sets `isTesting`, `isDevServer` and `isNodeJs` predicates which can be used for conditional code, ie. code present in the file used for test and development that will be removed from the production build. The line wil automatically be removed in production builds

    require("solapp").globalDefines global if typeof isNodeJs != "boolean"
    

use dummy data, grep and remove when moving into production

    devMode = true
    

## Utilities

    if !isNodeJs

### General Utility functions

      sleep = (time, fn) -> setTimeout fn, time*1000
      floatPart = (n) -> n - Math.floor(n)
      nextTick = (fn) -> setTimeout fn, 0
      window.requestAnimationFrame ?= window.mozRequestAnimationFrame || window.webkitRequestAnimationFrame || nextTick
      identityFn = (e) -> e
      nop = -> undefined
      runOnce = (fn) -> (args...) -> if fn then fn args...; fn = undefined else undefined
      extend = (target, sources...) -> #{{{4
        for source in sources
          for key, val of source
            target[key] = val
        target
      asyncEach = (arr, fn, done) -> #{{{4
        done = runOnce done
        remaining = arr.length
        next = (err) ->
          done err if err
          done() if not --remaining
        fn elem, next for elem in arr
        undefined
      

### Browser abstractions and utilities

Added here, because of requirement of no dependencies, - would otherwise use jquery or similar


      Date.now ?= -> (+ new Date())
      removeElem = (elem) -> elem?.parentElement.removeChild elem # elem.remove() not available on IE8
      body = document.getElementsByTagName("body")[0] # TODO: make sure this runs after onload
      onComplete = (fn) -> do f = -> if document.readyState == "complete" then fn() else setTimeout f, 10
      setStyle = (elem, obj) -> #{{{4
        for key, val of obj
          try
            elem.style[key] = val
          catch e
            e
        elem
      elemAddEventListener = (elem, type, fn) -> #{{{4
        if elem.addEventListener
          elem.addEventListener type, fn, false
        else
          elem.attachEvent "on"+type, fn
      

#### CORS `post` request to send data to the server

used for logging

      post = (url, data, asyncCallback) ->
        xhr = new XMLHttpRequest()
    
        xhr.open "POST", url, !! asyncCallback
    

Haven't done IE8/9 compat yet, but when we do
only text/plain is possible, due to bug in that
implementation (and it is XDomainRequest, instead of xhr)

        xhr.setRequestHeader "Content-type", "text/plain"
    
        if !! asyncCallback
          xhr.onreadystatechange = ->
            if xhr.readyState == 4
              asyncCallback (if xhr.status == 200 then null else xhr.status), xhr.responseText
    
        xhr.send data
        if !asyncCallback
          return xhr.responseText
        else
          undefined
    

### Web utilities

      cacheImgs = (urls, callback) -> #{{{4
        loadImg = (url, done) ->
          img = new Image()
          img.src = url
          img.onload = -> done()
        asyncEach urls, loadImg, callback

#### maximize

implementation disable at the moment, as we have another approach

      if false
        maximize = (elem) ->
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
            removeElem oldbody
            if nextSibling
              elem.insertBefore nextSibling
            else
              parent.appendChild elem
        

### Logging

url for api, where log is pushed

      logurl = "/logger"
    

how many seconds between each log push

      logfrequency = 1
    

actual implementation

      log = do ->

session stamp random number

        logsession = String(Math.random()).slice(2)
    
        scheduled = false
        logContent = "#{Date.now()} #{logsession}\n"
        schedule = ->
          return if scheduled
          scheduled = true
          sleep logfrequency, ->
            scheduled = false
            data = logContent
            logContent = "#{Date.now()} #{logsession}\n"
            post logurl, data, (err, result) ->
              if err
                logContent = data + logContent
                schedule()
        elemAddEventListener window, "beforeunload", ->
          log "beforeunload"
          try
            post logurl, logContent
          catch e
            undefined
          return undefined
    
        elemAddEventListener window, "error", (err) ->
          log "window.onerror", err?.message
    
        return (args...) ->
          console?.log? args...
          args = for arg in args
            try
              JSON.stringify arg
            catch e
              "[#{typeof arg}]"
          logContent += "#{Date.now()} #{args.join " "}\n"
          schedule()
    
      log "logging enabled", window.performance, window.screen, window.navigator?.userAgent
    
    
    
    

### Touch handler

      touchHandler = undefined
      setTouch = undefined
      do ->
        touch = undefined
        setTouch = (t) -> touch = t
      
        tapLength = 500 # maximum time for a click, - turns into a hold after that
        tapDist2 = 10*10 # maximum dragged (squared) distance for a click
      
        updateTouch = (touch, e) -> #{{{4
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
      
        startTouch = (e, handler, touchObj) -> #{{{4
          touch = touchObj
          touch.handler = handler
          touch.x0 = e.clientX
          touch.y0 = e.clientY
          touch.x = e.clientX
          touch.y = e.clientY
          log "startTouch", touch.x, touch.y
          touch.startTime = Date.now()
          updateTouch touch, e
          touch.ctx = handler.start(touch)
          holdHandler = ->
            if touch && !touch.holding && touch.maxDist2 < tapDist2
              touch.holding = true
              touch.handler.hold touch
          setTimeout holdHandler, tapLength
      
        moveTouch = (e) -> #{{{4
          updateTouch touch, e
          log "moveTouch", touch.x, touch.y
          touch.ctx = touch.handler.move touch || touch.ctx
      
        stopTouch = (e) -> #{{{4
          log "stopTouch"
          touch.handler.end touch
          touch.handler.click touch if touch.maxDist2 < tapDist2 && touch.time < tapLength
          touch = undefined
      
        condCall = (fn) -> (e) -> #{{{4
          return undefined if !touch
          e.preventDefault?()
          fn(e.touches?[0] || e)
      
        documentTouch = runOnce -> #{{{4
          elemAddEventListener document, "mousemove", condCall moveTouch
          elemAddEventListener document, "touchmove", condCall moveTouch
          elemAddEventListener document, "mouseup", (e) -> log "mouseup"; (condCall stopTouch)(e)
          elemAddEventListener document, "touchend", condCall stopTouch
      
        touchHandler = (handler) -> #{{{4
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
      

## 360º specific

      do ->
        callbackNo = 0
        zoomWidth = undefined
        zoomHeight = undefined
        zoomSize = 200
        eventHandler = undefined
        untouched = true
        default360Config = #{{{3
          autorotate: true
          imageURLs: undefined
      

#### Create zoom lens element

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

borderBottomRightRadius: (zoomSize/5) + "px"

            boxShadow: "0px 0px 40px 0px rgba(255,255,255,.7) inset, 4px 4px 9px 0px rgba(0,0,0,0.5)"
            display: "none"
          zoomLens.id = "zoomLens360"
          body.appendChild zoomLens
      

#### Add 360 elem to page

        window.onetwo360 = (cfg) ->
          log "onetwo360", cfg
      
          currentAngle = 0
          width = undefined
          height = undefined
          doZoom = undefined
          endZoom = undefined
          logoElem = undefined
      

#### Create img element for writing animation to

          elem = document.getElementById cfg.elem_id
          container = document.createElement "div"
          setStyle container,
            display: "inline-block"
            position: "relative"
          img = new Image()
          eventHandler = touchHandler {elem: elem}
          elem.appendChild container
          container.appendChild img
          img.src = "spinner.gif"
          setStyle img,
            position: "absolute"
            top: "49%"
            left: "49%"
      
      
          overlay = ->
            setStyle img,
              top: "0px"
              left: "0px"
            w = cfg.request_width
            h = cfg.request_height
            logoElem = document.createElement "i"
            logoElem.className = "icon-OneTwo360Logo"
            container.appendChild logoElem
            setStyle logoElem,
              position: "absolute"
              top: h*.35 + "px"
              left: w*.25  + "px"
              opacity: "0.7"
              textShadow: "0px 0px 5px white"
              fontSize: h*.2 + "px"
              color: "#333"
              transition: "opacity 1s"
            logoElem.onmouseover = ->
              logoElem.style.opacity = "0"
              sleep 1, ->
                logoElem.style.display = "none"
    
      
            buttonStyle = (el) ->
              setStyle el,
                position: "absolute"
                color: "#333"
                opacity: "0.7"
                textShadow: "0px 0px 5px white"
                backgroundColor: "rgba(255,255,255,0)"
                fontSize: h * .08 + "px"
                padding: h*.02 +"px"
              el
      
            fullScreenElem = document.createElement "i"
            fullScreenElem.className = "fa fa-fullscreen"
            fullScreenElem.ontouchstart = fullScreenElem.onmousedown = toggleFullScreen
            container.appendChild fullScreenElem
            setStyle (buttonStyle fullScreenElem),
              top: h *.85 + "px"
              left : w - h *.15 + "px"
      
            zoomElem = document.createElement "i"
            zoomElem.className = "fa fa-search"
            container.appendChild zoomElem
            setStyle (buttonStyle zoomElem),
              top: h *.85 + "px"
              left : 0 + "px"
      
          nextTick -> get360Config()
      
      

#### Get config+imagelist from server

          get360Config = ->
            callbackName = "callback" + ++callbackNo
            callbackName = "callback" if devMode
            window.xxx = scriptTag = undefined
            window[callbackName] = (data) ->
              log "data from embed.onetwo360.com:", data
              serverConfig =
                imageURLs: (data.baseUrl + file.normal for file in data.files)
                zoomURLs: (data.baseUrl + file.zoom for file in data.files)
                request_width: data.width
                request_height: data.width
              zoomWidth = data.zoomWidth
              zoomHeight = data.zoomHeight
              cfg = extend {}, default360Config, serverConfig, cfg
              init360Elem()
              removeElem scriptTag
              setStyle elem,
                display: "inline-block"
                width: data.width + "px"
                height: data.height + "px"
                overflow: "hidden"
              setStyle container,
                width: data.width + "px"
                height: data.height + "px"
              try
                delete window[callbackName]
              catch e
                undefined
            window.xxx = scriptTag = document.createElement "script"
            scriptTag.src = "http://embed.onetwo360.com/" + cfg.product_id + "?callback=" + callbackName
            scriptTag.src = "/testdata/config.js" if devMode
            document.getElementsByTagName("head")[0].appendChild scriptTag
        

#### Initialise the 360º object

          init360Elem = ->
            cache360Images ->
              setStyle img,
                width: cfg.request_width + "px"
                height: cfg.request_height + "px"
                cursor: "url(res/cursor_rotate.cur),move"
              width = cfg.request_width
              height = cfg.request_height
      
              overlay()
              init360Controls()
              if cfg.autorotate
                autorotate nop
        

#### Load images into cache, and possibly autorotate

          cache360Images = (done) -> cacheImgs cfg.imageURLs, done
      

#### Autorotate

          autorotate = (done) ->
            untouched = true
            currentAngle = 0
            showNext = ->
              if untouched and currentAngle < Math.PI * 2
                currentAngle = currentAngle + 0.2
                updateImage()

img.onload = -> setTimeout showNext, 10 # doesnt work in ie8

                setTimeout showNext, 60
              else
                done()
            showNext()
        

#### Update the current viewed image

          updateImage = -> requestAnimationFrame ->
            img.src = cfg.imageURLs[floatPart(currentAngle/Math.PI/2) * cfg.imageURLs.length | 0]
            imgsrc = img.src
            if fullScreenOriginalState
              sleep .5, ->
                largeImage = new Image
                largeImage.onload = ->
                  if imgsrc == img.src
                    img.src = largeImage.src
                  cache360Images nop
                largeImage.src = cfg.zoomURLs[floatPart(currentAngle/Math.PI/2) * cfg.imageURLs.length | 0]
      

#### init controls

          init360Controls = ->
            eventHandler.move = (t) ->
              if t.holding || t.zoom360
                nextTick -> doZoom t
              else
                currentAngle -= 2 * Math.PI * t.ddx / width
                updateImage()
            eventHandler.hold = (t) -> nextTick -> doZoom t
            eventHandler.start = (t) ->
              setStyle logoElem,
                opacity: "0"
              untouched = false
            eventHandler.end = (t) -> nextTick -> endZoom t
            eventHandler.click = (t) -> if t.isMouse
              log "click"
              t.zoom360 = true
              nextTick -> setTouch t
      

#### Zoom handling

          zoomSrc = undefined
          doZoom = (t) ->
            zoomLens = document.getElementById "zoomLens360"
            if zoomSrc == undefined
              normalSrc = cfg.imageURLs[floatPart(currentAngle/Math.PI/2) * cfg.zoomURLs.length | 0]
              largeSrc = cfg.zoomURLs[floatPart(currentAngle/Math.PI/2) * cfg.zoomURLs.length | 0]
              zoomSrc = normalSrc
              loadZoom = new Image
              loadZoom.onload = -> if zoomSrc == normalSrc
                zoomSrc = largeSrc
                doZoom t
              loadZoom.src = largeSrc
            imgPos = img.getBoundingClientRect()
            minY = imgPos.top
            maxY = imgPos.bottom
            minX = imgPos.left
            maxX = imgPos.right
            imgWidth = maxX - minX
            imgHeight = maxY - minY
            touchX = .5
            touchY = if t.isMouse then .5 else 1.1
            y = Math.min(maxY, Math.max(minY, t.y))
            x = Math.min(maxX, Math.max(minX, t.x))
            zoomLeftPos = x + body.scrollLeft - zoomSize * touchX
            zoomTopPos = y + body.scrollTop - zoomSize * touchY
            bgLeft = zoomSize*touchX-((x-imgPos.left) * zoomWidth / (imgWidth))
            bgTop = zoomSize*touchY-((y-imgPos.top) * zoomHeight / (imgHeight))
            setStyle zoomLens,
              display: "block"
              position: "absolute"
              left: zoomLeftPos + "px"
              top: zoomTopPos + "px"
              backgroundImage: "url(#{zoomSrc})"
              backgroundSize: "#{zoomWidth}px #{zoomHeight}px"
              backgroundPosition: "#{bgLeft}px #{bgTop}px"
              backgroundRepeat: "no-repeat"

img.style.cursor = "crosshair" # cannot reset cursor style, as it will mess up zoom lens on iOS

      
      
      
          endZoom = (t) ->
            zoomSrc = undefined
            img.style.cursor = "url(res/cursor_rotate.cur),move"
            (document.getElementById "zoomLens360").style.display = "none"
            cache360Images nop
      

#### fullscreen

          fullScreenOriginalState = undefined
          toggleFullScreen = (e)->
            scaleFactor = Math.min(window.innerWidth / width, window.innerHeight / height)
            e.preventDefault()
            e.stopPropagation()
      
            if fullScreenOriginalState
              setStyle elem,
                fullScreenOriginalState
              fullScreenOriginalState = undefined
            else
              style = elem.style
              fullScreenOriginalState =
                position: style.position
                top: style.top
                left: style.top
                zoom: style.zoom
                transform: style.transform
                webkitTransform: style.webkitTransform
                transformOrigin: style.transformOrigin
                webkitTransformOrigin: style.webkitTransformOrigin
                margin: style.margin
                padding: style.padding
              scaleStr = "scale(#{scaleFactor}, #{scaleFactor})"
              widthPad = ((window.innerWidth  / (scaleFactor * width)) - 1)/2 * width
              heightPad = ((window.innerHeight  / (scaleFactor * height)) - 1)/2 * height
              setStyle elem,
                margin: "0"
                padding: "#{heightPad}px #{widthPad}px #{heightPad}px #{widthPad}px"
                position: "fixed"
                top: "0px"
                left: "0px"
              if style.transform == "" || style.webkitTransform == ""
                setStyle elem,
                  transform: scaleStr
                  webkitTransform: scaleStr
                  transformOrigin: "0 0"
                  webkitTransformOrigin: "0 0"
              else
                elem.style.zoom = scaleFactor
            updateImage()
            false

## Development code
The following code is used during development.
It will automatically be removed when it is compiled and minified.
### Meta information about the application
This is primarily used for the README.md and to make sure necessary css are included when the devserver is running, and also that the minified version `webjs` is build.

    if isNodeJs
      exports.about =
        title: "360º Viewer"
        description: "Widget for showing OneTwo360 images/animations"
        owner: "onetwo360"
        name: "360"
        html5:
          userScaleable: true
          css: [
            "http://onetwo360.com/themes/onetwo360/site/360logofont.css"
            "//netdna.bootstrapcdn.com/font-awesome/4.0.1/css/font-awesome.css"
          ]
        webjs: true
        package:
          dependencies:
            solapp: "*"
    

### Test/experiment

    if isDevServer and !isNodeJs then do ->
      sa = require "solapp"
      exports.main = (solapp) ->

actual htmlcontent, defined as json

        solapp.setContent ["div"
          ["center"
              style:

width: 500
height: 500

                width: 1000
                height: 447
            ["span#threesixtyproduct", {style: {background: "#ccc"}}]]]

invoke the threesixty component

        onetwo360
          elem_id: "threesixtyproduct"
          product_id: "lukub2ip"

request_width: 600
request_height: 400

          request_width: 1000
          request_height: 447
    
      setTimeout (->
        blah = document.createElement "div"
        document.body.appendChild blah
        blah.innerHTML = Date.now()
        setInterval (->
          blah.innerHTML = "#{window.innerHeight} #{window.innerWidth} #{body.scrollTop} #{body.scrollLeft}"
        ), 1000
    
        sleep 3, ->
          njn()
      ), 0
    

### REST server for logging

    if isNodeJs then do ->
      exports.devServerMain = (app) ->
        app.use "/logger", (req, res, next) ->
          data = ""
          req.on "data", (d) -> data += d
          req.on "end", ->
            res.header 'Access-Control-Allow-Origin', "*"
            res.header 'Access-Control-Allow-Methods', 'GET,PUT,POST,DELETE'
            res.header 'Access-Control-Allow-Headers', 'Content-Type'
            console.log data
            res.json {ok:true}
            res.end()
    
    
    

# Minification

define `isNodeJs` and `runTest` in such a way that they will be fully removed by `uglifyjs -mc -d isNodeJs=false -d runTest=false `


    if typeof isNodeJs == "undefined" or typeof runTest == "undefined" then do ->
      root = if typeof global == "undefined" then window else global
      root.isNodeJs = (typeof window == "undefined") if typeof isNodeJs == "undefined"
      root.runTest = true if typeof runTest == "undefined"
    

# Testing

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
     

# Version 2

    if !isNodeJs

## utility
## shim

      Object.keys ?= (obj) -> (key for key, _ of obj)

### ajax

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
        

### extend

      extend = (target, source) ->
        for key, val of source
          target[key] = val
        return target
    
      if runTest then do ->
        a = {a: 1, b:2}
        expect (extend a, {b:3, c:4}), {a:1,b:3,c:4}, "extend"
        expect a, {a:1,b:3,c:4}, "extend"
    

### deepCopy

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
    

## Model

The model is just a json object that is passed around. This has all the state for the onetwo360 viewer


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
        fullscreen:
          false
        zoom:
          lensSize: 200
          enabled: false

x/y-position on image normalised in [0;1]

          x: undefined
          y: undefined
        domElem:
          width: undefined
          height: undefined
          domId: undefined
    
    

## View

The html of the view is static, only updated through css-changes. 

### `View` constructor, - create a view and bind it to a dom element

Create the view, - and bind it to a dom element


      View = (model, domId) ->
        @model = model
        domElem = document.getElementById(domId)
        @defaultWidth = model.width || domElem.offsetWidth
        @defaultHeight = model.height || domElem.offsetHeight
    

#### Style
##

        extend domElem.style,
          display: "inline-block"
          width: @defaultWidth + "px"
          height: @defaultHeight + "px"

##

        @style =
          root:
            display: "inline-block"
            cursor: "url(res/cursor_rotate.cur),move"
    

NB: order of the following keys needs to be the exactly same as the children of the dom root node

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

borderBottomRightRadius: (zoomSize/5)

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
    

#### Dom element creation

        @elems = {}
        @elems.root = document.createElement "div"
        @elems.root.innerHTML =
          '<div class="onetwo360-zoom-lens"></div>' +
          '<i class="icon-OneTwo360Logo"></i>' +
          '<i class="fa fa-fullscreen onetwo360-fullscreen-button"></i>' +
          '<i class="fa fa-search onetwo360-fullscreen-button"></i>' +
          '<img src="spinner.gif">'
        domElem.appendChild @elems.root
    
        elemNames = Object.keys @style
        for i in [1..elemNames.length-1]
          @elems[elemNames[i]] = @elems.root.childNodes[i-1]
    

#### Properties that will be initialised later

        @width = undefined
        @height = undefined
        @logoFade = undefined
    

#### Data structure for optimised style update

        @elemStyle = {}
        @styleCache = {}
        for key, _ of @elems
          @elemStyle[key] = @elems[key].style
          @styleCache[key] = {}
    

#### Connect to parent dom node (`domId`), and get its width/height

    

#### Update view

        @update()
    

### `View#update()` draw the view based on current content of the model

      View.prototype.update = ->
        @_fullscreen()
        @_root()
        @_logo()
        @_zoomLens()
        @_applyStyle()
    

### private utility functions for updating the view

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
    
      View.prototype._applyStyle = -> #{{{4
        for elemId, css of @style
          for key, val of css
            if @styleCache[elemId][key] != val
              val = val + "px" if typeof val == "number"
              @elemStyle[elemId][key] = val
              @styleCache[elemId][key] = val
    

### test

      if runTest then do ->
        model = deepCopy(defaultModel)
        for frames in [model.frames.normal, model.frames.zoom]
          model.width = frames.width = 1000
          model.height = frames.height = 447
          for i in [1..52]
            frames.urls.push "/testdata/#{i}.jpg"
        view = new View(model, "threesixtyproduct")
    
    

## main

      window.onetwo360 = (cfg) ->
        undefined

# Dummy/test-server

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
    

----

README.md autogenerated from `360.coffee`, `onetwo360.coffee` ![solsort](https://ssl.solsort.com/_reputil_onetwo360_360-viewer.png)
