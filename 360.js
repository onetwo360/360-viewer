// Generated by CoffeeScript 1.6.3
/* Util (open) {{{1*/


(function() {
  var asyncEach, body, cacheImgs, elemAddEventListener, extend, floatPart, get, identityFn, maximize, nextTick, nop, onComplete, runOnce, setStyle, setTouch, touchHandler,
    __slice = [].slice;

  floatPart = function(n) {
    return n - Math.floor(n);
  };

  nextTick = function(fn) {
    return setTimeout(fn, 0);
  };

  identityFn = function(e) {
    return e;
  };

  nop = function() {
    return void 0;
  };

  runOnce = function(fn) {
    return function() {
      var args;
      args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      if (fn) {
        fn.apply(null, args);
        return fn = void 0;
      } else {
        return void 0;
      }
    };
  };

  extend = function() {
    var key, source, sources, target, val, _i, _len;
    target = arguments[0], sources = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
    for (_i = 0, _len = sources.length; _i < _len; _i++) {
      source = sources[_i];
      for (key in source) {
        val = source[key];
        target[key] = val;
      }
    }
    return target;
  };

  asyncEach = function(arr, fn, done) {
    var elem, next, remaining, _i, _len;
    done = runOnce(done);
    remaining = arr.length;
    next = function(err) {
      if (err) {
        done(err);
      }
      if (!--remaining) {
        return done();
      }
    };
    for (_i = 0, _len = arr.length; _i < _len; _i++) {
      elem = arr[_i];
      fn(elem, next);
    }
    return void 0;
  };

  onComplete = function(fn) {
    var f;
    return (f = function() {
      if (document.readyState === "interactive" || document.readyState === "complete") {
        return fn();
      } else {
        return setTimeout(f, 10);
      }
    })();
  };

  setStyle = function(elem, obj) {
    var e, key, val;
    for (key in obj) {
      val = obj[key];
      try {
        elem.style[key] = val;
      } catch (_error) {
        e = _error;
        e;
      }
    }
    return elem;
  };

  elemAddEventListener = function(elem, type, fn) {
    if (elem.addEventListener) {
      return elem.addEventListener(type, fn, false);
    } else {
      return elem.attachEvent("on" + type, fn);
    }
  };

  if (Date.now == null) {
    Date.now = function() {
      return +new Date();
    };
  }

  body = document.getElementsByTagName("body")[0];

  get = function(url, callback) {
    var req;
    req = new XMLHttpRequest();
    req.onload = function() {
      return callback(null, req.responseText);
    };
    req.open("get", url, true);
    return req.send();
  };

  cacheImgs = function(urls, callback) {
    var loadImg;
    loadImg = function(url, done) {
      var img;
      img = new Image();
      img.src = url;
      return img.onload = function() {
        return done();
      };
    };
    return asyncEach(urls, loadImg, callback);
  };

  maximize = function(elem) {
    var nextSibling, node, oldbody, parent, _i, _len, _ref;
    oldbody = document.createElement("div");
    oldbody.style.display = "none";
    parent = elem.parentElement;
    nextSibling = elem.nextSibling;
    body.appendChild(oldbody);
    _ref = (function() {
      var _j, _len, _ref, _results;
      _ref = body.childNodes;
      _results = [];
      for (_j = 0, _len = _ref.length; _j < _len; _j++) {
        node = _ref[_j];
        _results.push(node);
      }
      return _results;
    })();
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      node = _ref[_i];
      if (node !== oldbody) {
        oldbody.appendChild(node);
      }
    }
    body.appendChild(elem);
    return function() {
      var _j, _len1, _ref1;
      _ref1 = (function() {
        var _k, _len1, _ref1, _results;
        _ref1 = oldbody.childNodes;
        _results = [];
        for (_k = 0, _len1 = _ref1.length; _k < _len1; _k++) {
          node = _ref1[_k];
          _results.push(node);
        }
        return _results;
      })();
      for (_j = 0, _len1 = _ref1.length; _j < _len1; _j++) {
        node = _ref1[_j];
        body.appendChild(node);
      }
      oldbody.remove();
      if (nextSibling) {
        return elem.insertBefore(nextSibling);
      } else {
        return parent.appendChild(elem);
      }
    };
  };

  touchHandler = void 0;

  setTouch = void 0;

  (function() {
    var condCall, documentTouch, moveTouch, startTouch, stopTouch, tapDist2, tapLength, touch, updateTouch;
    touch = void 0;
    setTouch = function(t) {
      return touch = t;
    };
    tapLength = 500;
    tapDist2 = 10 * 10;
    updateTouch = function(touch, e) {
      var x, y;
      x = e.clientX;
      y = e.clientY;
      touch.event = e;
      touch.ddx = x - touch.x || 0;
      touch.ddy = y - touch.y || 0;
      touch.dx = x - touch.x0;
      touch.dy = y - touch.y0;
      touch.maxDist2 = touch.dx * touch.dx + touch.dy * touch.dy;
      touch.time = Date.now() - touch.startTime;
      touch.x = x;
      return touch.y = y;
    };
    startTouch = function(e, handler, touchObj) {
      var holdHandler;
      touch = touchObj;
      touch.handler = handler;
      touch.x0 = e.clientX;
      touch.y0 = e.clientY;
      touch.x = e.clientX;
      touch.y = e.clientY;
      touch.startTime = Date.now();
      updateTouch(touch, e);
      touch.ctx = handler.start(touch);
      holdHandler = function() {
        if (touch && !touch.holding && touch.maxDist2 < tapDist2) {
          touch.holding = true;
          return touch.handler.hold(touch);
        }
      };
      return setTimeout(holdHandler, tapLength);
    };
    moveTouch = function(e) {
      updateTouch(touch, e);
      return touch.ctx = touch.handler.move(touch || touch.ctx);
    };
    stopTouch = function(e) {
      touch.handler.end(touch);
      if (touch.maxDist2 < tapDist2 && touch.time < tapLength) {
        touch.handler.click(touch);
      }
      return touch = void 0;
    };
    condCall = function(fn) {
      return function(e) {
        var _ref;
        if (!touch) {
          return void 0;
        }
        if (typeof e.preventDefault === "function") {
          e.preventDefault();
        }
        return fn(((_ref = e.touches) != null ? _ref[0] : void 0) || e);
      };
    };
    documentTouch = runOnce(function() {
      elemAddEventListener(document, "mousemove", condCall(moveTouch));
      elemAddEventListener(document, "touchmove", condCall(moveTouch));
      elemAddEventListener(document, "mouseup", condCall(stopTouch));
      return elemAddEventListener(document, "touchend", condCall(stopTouch));
    });
    return touchHandler = function(handler) {
      elemAddEventListener(handler.elem, "mousedown", function(e) {
        if (typeof e.preventDefault === "function") {
          e.preventDefault();
        }
        return startTouch(e, handler, {
          isMouse: true
        });
      });
      elemAddEventListener(handler.elem, "touchstart", function(e) {
        if (typeof e.preventDefault === "function") {
          e.preventDefault();
        }
        return startTouch(e.touches[0], handler, {});
      });
      documentTouch();
      handler.start || (handler.start = nop);
      handler.move || (handler.move = nop);
      handler.end || (handler.end = nop);
      handler.drag || (handler.drag = nop);
      handler.click || (handler.click = nop);
      handler.hold || (handler.hold = nop);
      return handler;
    };
  })();

  (function() {
    var default360Config, eventHandler, untouched, zoomHeight, zoomSize, zoomWidth;
    zoomWidth = void 0;
    zoomHeight = void 0;
    zoomSize = 200;
    eventHandler = void 0;
    untouched = true;
    default360Config = {
      autorotate: true,
      imageURLs: void 0
    };
    onComplete(function() {
      var zoomLens;
      body = document.getElementsByTagName("body")[0];
      zoomLens = document.createElement("div");
      setStyle(zoomLens, {
        position: "absolute",
        overflow: "hidden",
        width: zoomSize + "px",
        height: zoomSize + "px",
        border: "0px solid black",
        cursor: "default",
        backgroundColor: "rgba(100,100,100,0.8)",
        borderRadius: (zoomSize / 2) + "px",
        boxShadow: "0px 0px 40px 0px rgba(255,255,255,.7) inset, 4px 4px 9px 0px rgba(0,0,0,0.5)",
        display: "none"
      });
      zoomLens.id = "zoomLens360";
      return body.appendChild(zoomLens);
    });
    return window.onetwo360 = function(cfg) {
      var autorotate, cache360Images, container, currentAngle, doZoom, elem, endZoom, fullScreenOriginalState, get360Config, height, img, init360Controls, init360Elem, logoElem, overlay, recache, toggleFullScreen, updateImage, width;
      currentAngle = 0;
      width = void 0;
      height = void 0;
      doZoom = void 0;
      endZoom = void 0;
      recache = nop;
      logoElem = void 0;
      elem = document.getElementById(cfg.elem_id);
      container = document.createElement("div");
      setStyle(container, {
        display: "inline-block",
        position: "relative"
      });
      img = new Image();
      eventHandler = touchHandler({
        elem: elem
      });
      elem.appendChild(container);
      container.appendChild(img);
      img.src = "spinner.gif";
      setStyle(img, {
        position: "absolute",
        top: "49%",
        left: "49%"
      });
      overlay = function() {
        var buttonStyle, fullScreenElem, h, w, zoomElem;
        setStyle(img, {
          top: "0px",
          left: "0px"
        });
        if (typeof spinnerElem !== "undefined" && spinnerElem !== null) {
          spinnerElem.remove();
        }
        w = cfg.request_width;
        h = cfg.request_height;
        logoElem = document.createElement("i");
        logoElem.className = "icon-OneTwo360Logo";
        container.appendChild(logoElem);
        setStyle(logoElem, {
          position: "absolute",
          top: h * .35 + "px",
          left: w * .25 + "px",
          opacity: "0.7",
          textShadow: "0px 0px 5px white",
          fontSize: h * .2 + "px",
          color: "#333",
          transition: "opacity 1s"
        });
        logoElem.onmouseover = function() {
          return logoElem.style.opacity = "0";
        };
        buttonStyle = function(el) {
          setStyle(el, {
            position: "absolute",
            color: "#333",
            opacity: "0.7",
            textShadow: "0px 0px 5px white",
            backgroundColor: "rgba(255,255,255,0)",
            fontSize: h * .08 + "px",
            padding: h * .02 + "px"
          });
          return el;
        };
        fullScreenElem = document.createElement("i");
        fullScreenElem.className = "fa fa-fullscreen";
        fullScreenElem.ontouchstart = fullScreenElem.onmousedown = toggleFullScreen;
        container.appendChild(fullScreenElem);
        setStyle(buttonStyle(fullScreenElem), {
          top: h * .85 + "px",
          left: w - h * .15 + "px"
        });
        zoomElem = document.createElement("i");
        zoomElem.className = "fa fa-search";
        container.appendChild(zoomElem);
        return setStyle(buttonStyle(zoomElem), {
          top: h * .85 + "px",
          left: 0 + "px"
        });
      };
      nextTick(function() {
        return get360Config();
      });
      get360Config = function() {
        var callbackName, scriptTag;
        callbackName = "callback";
        window[callbackName] = function(data) {
          var file, serverConfig;
          serverConfig = {
            imageURLs: (function() {
              var _i, _len, _ref, _results;
              _ref = data.files;
              _results = [];
              for (_i = 0, _len = _ref.length; _i < _len; _i++) {
                file = _ref[_i];
                _results.push(data.baseUrl + file.normal);
              }
              return _results;
            })(),
            zoomURLs: (function() {
              var _i, _len, _ref, _results;
              _ref = data.files;
              _results = [];
              for (_i = 0, _len = _ref.length; _i < _len; _i++) {
                file = _ref[_i];
                _results.push(data.baseUrl + file.zoom);
              }
              return _results;
            })(),
            request_width: data.width,
            request_height: data.width
          };
          zoomWidth = data.zoomWidth;
          zoomHeight = data.zoomHeight;
          cfg = extend({}, default360Config, serverConfig, cfg);
          init360Elem();
          scriptTag.remove();
          setStyle(container, {
            width: data.width + "px",
            height: data.height + "px"
          });
          return delete window[callbackName];
        };
        scriptTag = document.createElement("script");
        scriptTag.src = "" + cfg.product_id + "?callback=" + callbackName;
        return document.getElementsByTagName("head")[0].appendChild(scriptTag);
      };
      init360Elem = function() {
        return cache360Images(function() {
          setStyle(img, {
            width: cfg.request_width + "px",
            height: cfg.request_height + "px",
            cursor: "url(res/cursor_rotate.cur),move"
          });
          width = cfg.request_width;
          height = cfg.request_height;
          overlay();
          init360Controls();
          if (cfg.autorotate) {
            return autorotate(nop);
          }
        });
      };
      cache360Images = function(done) {
        return cacheImgs(cfg.imageURLs, done);
      };
      autorotate = function(done) {
        var showNext;
        untouched = true;
        currentAngle = 0;
        showNext = function() {
          if (untouched && currentAngle < Math.PI * 2) {
            currentAngle = currentAngle + 0.2;
            updateImage();
            return setTimeout(showNext, 60);
          } else {
            return done();
          }
        };
        return showNext();
      };
      updateImage = function() {
        return img.src = cfg.imageURLs[floatPart(currentAngle / Math.PI / 2) * cfg.imageURLs.length | 0];
      };
      init360Controls = function() {
        eventHandler.move = function(t) {
          if (t.holding || t.zoom360) {
            return nextTick(function() {
              return doZoom(t);
            });
          } else {
            currentAngle -= 2 * Math.PI * t.ddx / width;
            return updateImage();
          }
        };
        eventHandler.hold = function(t) {
          return nextTick(function() {
            return doZoom(t);
          });
        };
        eventHandler.start = function(t) {
          setStyle(logoElem, {
            opacity: "0"
          });
          return untouched = false;
        };
        eventHandler.end = function(t) {
          return nextTick(function() {
            return endZoom(t);
          });
        };
        return eventHandler.click = function(t) {
          if (t.isMouse) {
            t.zoom360 = true;
            return nextTick(function() {
              return setTouch(t);
            });
          }
        };
      };
      doZoom = function(t) {
        var bgLeft, bgTop, imgHeight, imgPos, imgWidth, largeUrl, maxX, maxY, minX, minY, touchX, touchY, x, y, zoomLeftPos, zoomLens, zoomTopPos;
        zoomLens = document.getElementById("zoomLens360");
        largeUrl = cfg.zoomURLs[floatPart(currentAngle / Math.PI / 2) * cfg.zoomURLs.length | 0];
        imgPos = img.getBoundingClientRect();
        minY = imgPos.top;
        maxY = imgPos.bottom;
        minX = imgPos.left;
        maxX = imgPos.right;
        imgWidth = maxX - minX;
        imgHeight = maxY - minY;
        touchX = .5;
        touchY = t.isMouse ? .5 : 1.1;
        y = Math.min(maxY, Math.max(minY, t.y));
        x = Math.min(maxX, Math.max(minX, t.x));
        zoomLeftPos = x + body.scrollLeft - zoomSize * touchX;
        zoomTopPos = y + body.scrollTop - zoomSize * touchY;
        bgLeft = zoomSize * touchX - ((x - imgPos.left) * zoomWidth / imgWidth);
        bgTop = zoomSize * touchY - ((y - imgPos.top) * zoomHeight / imgHeight);
        return setStyle(zoomLens, {
          display: "block",
          position: "absolute",
          left: zoomLeftPos + "px",
          top: zoomTopPos + "px",
          backgroundImage: "url(" + largeUrl + ")",
          backgroundPosition: "" + bgLeft + "px " + bgTop + "px",
          backgroundRepeat: "no-repeat"
        });
      };
      endZoom = function(t) {
        img.style.cursor = "url(res/cursor_rotate.cur),move";
        (document.getElementById("zoomLens360")).style.display = "none";
        return recache();
      };
      fullScreenOriginalState = void 0;
      return toggleFullScreen = function(e) {
        var heightPad, scaleFactor, scaleStr, style, widthPad;
        scaleFactor = Math.min(window.innerWidth / width, window.innerHeight / height);
        e.preventDefault();
        e.stopPropagation();
        if (fullScreenOriginalState) {
          setStyle(elem, fullScreenOriginalState);
          fullScreenOriginalState = void 0;
        } else {
          style = elem.style;
          fullScreenOriginalState = {
            position: style.position,
            top: style.top,
            left: style.top,
            zoom: style.zoom,
            transform: style.transform,
            webkitTransform: style.webkitTransform,
            transformOrigin: style.transformOrigin,
            webkitTransformOrigin: style.webkitTransformOrigin,
            margin: style.margin,
            padding: style.padding,
            background: style.background
          };
          scaleStr = "scale(" + scaleFactor + ", " + scaleFactor + ")";
          widthPad = ((window.innerWidth / (scaleFactor * width)) - 1) / 2 * width;
          heightPad = ((window.innerHeight / (scaleFactor * width)) - 1) / 2 * width;
          setStyle(elem, {
            margin: "0",
            padding: "" + heightPad + "px " + widthPad + "px " + heightPad + "px " + widthPad + "px",
            background: "blue",
            position: "fixed",
            top: "0px",
            left: "0px"
          });
          if (style.transform === "" || style.webkitTransform === "") {
            setStyle(elem, {
              transform: scaleStr,
              webkitTransform: scaleStr,
              transformOrigin: "0 0",
              webkitTransformOrigin: "0 0"
            });
          } else {
            elem.style.zoom = scaleFactor;
          }
        }
        return false;
      };
    };
  })();

}).call(this);
