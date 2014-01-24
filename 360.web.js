(function() {
    var asyncEach, body, cacheImgs, elemAddEventListener, extend, floatPart, identityFn, log, logfrequency, logurl, nextTick, nop, onComplete, post, runOnce, setStyle, setTouch, sleep, touchHandler, _ref, __slice = (window[360] = {}, 
    [].slice);
    sleep = function(time, fn) {
        return setTimeout(fn, 1e3 * time);
    }, floatPart = function(n) {
        return n - Math.floor(n);
    }, nextTick = function(fn) {
        return setTimeout(fn, 0);
    }, null == window.requestAnimationFrame && (window.requestAnimationFrame = window.mozRequestAnimationFrame || window.webkitRequestAnimationFrame || nextTick), 
    identityFn = function(e) {
        return e;
    }, nop = function() {
        return void 0;
    }, runOnce = function(fn) {
        return function() {
            var args;
            return args = 1 <= arguments.length ? __slice.call(arguments, 0) : [], fn ? (fn.apply(null, args), 
            fn = void 0) : void 0;
        };
    }, extend = function() {
        var key, source, sources, target, val, _i, _len;
        for (target = arguments[0], sources = 2 <= arguments.length ? __slice.call(arguments, 1) : [], 
        _i = 0, _len = sources.length; _len > _i; _i++) {
            source = sources[_i];
            for (key in source) val = source[key], target[key] = val;
        }
        return target;
    }, asyncEach = function(arr, fn, done) {
        var elem, next, remaining, _i, _len;
        for (done = runOnce(done), remaining = arr.length, next = function(err) {
            return err && done(err), --remaining ? void 0 : done();
        }, _i = 0, _len = arr.length; _len > _i; _i++) elem = arr[_i], fn(elem, next);
        return void 0;
    }, null == Date.now && (Date.now = function() {
        return +new Date();
    }), body = document.getElementsByTagName("body")[0], onComplete = function(fn) {
        var f;
        return (f = function() {
            return "interactive" === document.readyState || "complete" === document.readyState ? fn() : setTimeout(f, 10);
        })();
    }, setStyle = function(elem, obj) {
        var e, key, val;
        for (key in obj) {
            val = obj[key];
            try {
                elem.style[key] = val;
            } catch (_error) {
                e = _error;
            }
        }
        return elem;
    }, elemAddEventListener = function(elem, type, fn) {
        return elem.addEventListener ? elem.addEventListener(type, fn, !1) : elem.attachEvent("on" + type, fn);
    }, post = function(url, data, asyncCallback) {
        var xhr;
        return xhr = new XMLHttpRequest(), xhr.open("POST", url, !!asyncCallback), xhr.setRequestHeader("Content-type", "text/plain"), 
        asyncCallback && (xhr.onreadystatechange = function() {
            return 4 === xhr.readyState ? asyncCallback(200 === xhr.status ? null : xhr.status, xhr.responseText) : void 0;
        }), xhr.send(data), xhr.responseText;
    }, cacheImgs = function(urls, callback) {
        var loadImg;
        return loadImg = function(url, done) {
            var img;
            return img = new Image(), img.src = url, img.onload = function() {
                return done();
            };
        }, asyncEach(urls, loadImg, callback);
    }, logurl = "/logger", logfrequency = 10, log = function() {
        var logContent, logsession, schedule, scheduled;
        return logsession = String(Math.random()).slice(2), scheduled = !1, logContent = "" + Date.now() + " " + logsession + "\n", 
        schedule = function() {
            return scheduled ? void 0 : (scheduled = !0, sleep(logfrequency, function() {
                var data;
                return scheduled = !1, data = logContent, logContent = "" + Date.now() + " " + logsession + "\n", 
                post(logurl, data, function(err) {
                    return err ? (logContent = data + logContent, schedule()) : void 0;
                });
            }));
        }, elemAddEventListener(window, "beforeunload", function() {
            var e;
            log("beforeunload");
            try {
                post(logurl, logContent);
            } catch (_error) {
                e = _error;
            }
            return void 0;
        }), elemAddEventListener(window, "error", function(err) {
            return log("window.onerror", null != err ? err.message : void 0);
        }), function() {
            var arg, args, e;
            return args = 1 <= arguments.length ? __slice.call(arguments, 0) : [], console.log.apply(console, args), 
            args = function() {
                var _i, _len, _results;
                for (_results = [], _i = 0, _len = args.length; _len > _i; _i++) {
                    arg = args[_i];
                    try {
                        _results.push(JSON.stringify(arg));
                    } catch (_error) {
                        e = _error, _results.push("[" + typeof arg + "]");
                    }
                }
                return _results;
            }(), logContent += "" + Date.now() + " " + args.join(" ") + "\n", schedule();
        };
    }(), log("logging enabled", window.performance, window.screen, null != (_ref = window.navigator) ? _ref.userAgent : void 0), 
    touchHandler = void 0, setTouch = void 0, function() {
        var condCall, documentTouch, moveTouch, startTouch, stopTouch, tapDist2, tapLength, touch, updateTouch;
        return touch = void 0, setTouch = function(t) {
            return touch = t;
        }, tapLength = 500, tapDist2 = 100, updateTouch = function(touch, e) {
            var x, y;
            return x = e.clientX, y = e.clientY, touch.event = e, touch.ddx = x - touch.x || 0, 
            touch.ddy = y - touch.y || 0, touch.dx = x - touch.x0, touch.dy = y - touch.y0, 
            touch.maxDist2 = touch.dx * touch.dx + touch.dy * touch.dy, touch.time = Date.now() - touch.startTime, 
            touch.x = x, touch.y = y;
        }, startTouch = function(e, handler, touchObj) {
            var holdHandler;
            return touch = touchObj, touch.handler = handler, touch.x0 = e.clientX, touch.y0 = e.clientY, 
            touch.x = e.clientX, touch.y = e.clientY, touch.startTime = Date.now(), updateTouch(touch, e), 
            touch.ctx = handler.start(touch), holdHandler = function() {
                return touch && !touch.holding && touch.maxDist2 < tapDist2 ? (touch.holding = !0, 
                touch.handler.hold(touch)) : void 0;
            }, setTimeout(holdHandler, tapLength);
        }, moveTouch = function(e) {
            return updateTouch(touch, e), touch.ctx = touch.handler.move(touch || touch.ctx);
        }, stopTouch = function() {
            return touch.handler.end(touch), touch.maxDist2 < tapDist2 && touch.time < tapLength && touch.handler.click(touch), 
            touch = void 0;
        }, condCall = function(fn) {
            return function(e) {
                var _ref1;
                return touch ? ("function" == typeof e.preventDefault && e.preventDefault(), fn((null != (_ref1 = e.touches) ? _ref1[0] : void 0) || e)) : void 0;
            };
        }, documentTouch = runOnce(function() {
            return elemAddEventListener(document, "mousemove", condCall(moveTouch)), elemAddEventListener(document, "touchmove", condCall(moveTouch)), 
            elemAddEventListener(document, "mouseup", condCall(stopTouch)), elemAddEventListener(document, "touchend", condCall(stopTouch));
        }), touchHandler = function(handler) {
            return elemAddEventListener(handler.elem, "mousedown", function(e) {
                return "function" == typeof e.preventDefault && e.preventDefault(), startTouch(e, handler, {
                    isMouse: !0
                });
            }), elemAddEventListener(handler.elem, "touchstart", function(e) {
                return "function" == typeof e.preventDefault && e.preventDefault(), startTouch(e.touches[0], handler, {});
            }), documentTouch(), handler.start || (handler.start = nop), handler.move || (handler.move = nop), 
            handler.end || (handler.end = nop), handler.drag || (handler.drag = nop), handler.click || (handler.click = nop), 
            handler.hold || (handler.hold = nop), handler;
        };
    }(), function() {
        var callbackNo, default360Config, eventHandler, untouched, zoomHeight, zoomSize, zoomWidth;
        return callbackNo = 0, zoomWidth = void 0, zoomHeight = void 0, zoomSize = 200, 
        eventHandler = void 0, untouched = !0, default360Config = {
            autorotate: !0,
            imageURLs: void 0
        }, onComplete(function() {
            var zoomLens;
            return body = document.getElementsByTagName("body")[0], zoomLens = document.createElement("div"), 
            setStyle(zoomLens, {
                position: "absolute",
                overflow: "hidden",
                width: zoomSize + "px",
                height: zoomSize + "px",
                border: "0px solid black",
                cursor: "default",
                backgroundColor: "rgba(100,100,100,0.8)",
                borderRadius: zoomSize / 2 + "px",
                boxShadow: "0px 0px 40px 0px rgba(255,255,255,.7) inset, 4px 4px 9px 0px rgba(0,0,0,0.5)",
                display: "none"
            }), zoomLens.id = "zoomLens360", body.appendChild(zoomLens);
        }), window.onetwo360 = function(cfg) {
            var autorotate, cache360Images, container, currentAngle, doZoom, elem, endZoom, fullScreenOriginalState, get360Config, height, img, init360Controls, init360Elem, logoElem, overlay, toggleFullScreen, updateImage, width, zoomSrc;
            return log("onetwo360", cfg), currentAngle = 0, width = void 0, height = void 0, 
            doZoom = void 0, endZoom = void 0, logoElem = void 0, elem = document.getElementById(cfg.elem_id), 
            container = document.createElement("div"), setStyle(container, {
                display: "inline-block",
                position: "relative"
            }), img = new Image(), eventHandler = touchHandler({
                elem: elem
            }), elem.appendChild(container), container.appendChild(img), img.src = "spinner.gif", 
            setStyle(img, {
                position: "absolute",
                top: "49%",
                left: "49%"
            }), overlay = function() {
                var buttonStyle, fullScreenElem, h, w, zoomElem;
                return setStyle(img, {
                    top: "0px",
                    left: "0px"
                }), "undefined" != typeof spinnerElem && null !== spinnerElem && spinnerElem.remove(), 
                w = cfg.request_width, h = cfg.request_height, logoElem = document.createElement("i"), 
                logoElem.className = "icon-OneTwo360Logo", container.appendChild(logoElem), setStyle(logoElem, {
                    position: "absolute",
                    top: .35 * h + "px",
                    left: .25 * w + "px",
                    opacity: "0.7",
                    textShadow: "0px 0px 5px white",
                    fontSize: .2 * h + "px",
                    color: "#333",
                    transition: "opacity 1s"
                }), logoElem.onmouseover = function() {
                    return logoElem.style.opacity = "0";
                }, buttonStyle = function(el) {
                    return setStyle(el, {
                        position: "absolute",
                        color: "#333",
                        opacity: "0.7",
                        textShadow: "0px 0px 5px white",
                        backgroundColor: "rgba(255,255,255,0)",
                        fontSize: .08 * h + "px",
                        padding: .02 * h + "px"
                    }), el;
                }, fullScreenElem = document.createElement("i"), fullScreenElem.className = "fa fa-fullscreen", 
                fullScreenElem.ontouchstart = fullScreenElem.onmousedown = toggleFullScreen, container.appendChild(fullScreenElem), 
                setStyle(buttonStyle(fullScreenElem), {
                    top: .85 * h + "px",
                    left: w - .15 * h + "px"
                }), zoomElem = document.createElement("i"), zoomElem.className = "fa fa-search", 
                container.appendChild(zoomElem), setStyle(buttonStyle(zoomElem), {
                    top: .85 * h + "px",
                    left: "0px"
                });
            }, nextTick(function() {
                return get360Config();
            }), get360Config = function() {
                var callbackName, scriptTag;
                return callbackName = "callback" + ++callbackNo, window[callbackName] = function(data) {
                    var file, serverConfig;
                    return log("data from embed.onetwo360.com:", data), serverConfig = {
                        imageURLs: function() {
                            var _i, _len, _ref1, _results;
                            for (_ref1 = data.files, _results = [], _i = 0, _len = _ref1.length; _len > _i; _i++) file = _ref1[_i], 
                            _results.push(data.baseUrl + file.normal);
                            return _results;
                        }(),
                        zoomURLs: function() {
                            var _i, _len, _ref1, _results;
                            for (_ref1 = data.files, _results = [], _i = 0, _len = _ref1.length; _len > _i; _i++) file = _ref1[_i], 
                            _results.push(data.baseUrl + file.zoom);
                            return _results;
                        }(),
                        request_width: data.width,
                        request_height: data.width
                    }, zoomWidth = data.zoomWidth, zoomHeight = data.zoomHeight, cfg = extend({}, default360Config, serverConfig, cfg), 
                    init360Elem(), scriptTag.remove(), setStyle(elem, {
                        display: "inline-block",
                        width: data.width + "px",
                        height: data.height + "px",
                        overflow: "hidden"
                    }), setStyle(container, {
                        width: data.width + "px",
                        height: data.height + "px"
                    }), delete window[callbackName];
                }, scriptTag = document.createElement("script"), scriptTag.src = "http://embed.onetwo360.com/" + cfg.product_id + "?callback=" + callbackName, 
                document.getElementsByTagName("head")[0].appendChild(scriptTag);
            }, init360Elem = function() {
                return cache360Images(function() {
                    return setStyle(img, {
                        width: cfg.request_width + "px",
                        height: cfg.request_height + "px",
                        cursor: "url(res/cursor_rotate.cur),move"
                    }), width = cfg.request_width, height = cfg.request_height, overlay(), init360Controls(), 
                    cfg.autorotate ? autorotate(nop) : void 0;
                });
            }, cache360Images = function(done) {
                return cacheImgs(cfg.imageURLs, done);
            }, autorotate = function(done) {
                var showNext;
                return untouched = !0, currentAngle = 0, (showNext = function() {
                    return untouched && currentAngle < 2 * Math.PI ? (currentAngle += .2, updateImage(), 
                    setTimeout(showNext, 60)) : done();
                })();
            }, updateImage = function() {
                return requestAnimationFrame(function() {
                    var imgsrc;
                    return img.src = cfg.imageURLs[floatPart(currentAngle / Math.PI / 2) * cfg.imageURLs.length | 0], 
                    imgsrc = img.src, fullScreenOriginalState ? sleep(.5, function() {
                        var largeImage;
                        return largeImage = new Image(), largeImage.onload = function() {
                            return console.log("here", imgsrc, img.src), imgsrc === img.src && (img.src = largeImage.src), 
                            cache360Images(nop);
                        }, largeImage.src = cfg.zoomURLs[floatPart(currentAngle / Math.PI / 2) * cfg.imageURLs.length | 0];
                    }) : void 0;
                });
            }, init360Controls = function() {
                return eventHandler.move = function(t) {
                    return t.holding || t.zoom360 ? nextTick(function() {
                        return doZoom(t);
                    }) : (currentAngle -= 2 * Math.PI * t.ddx / width, updateImage());
                }, eventHandler.hold = function(t) {
                    return nextTick(function() {
                        return doZoom(t);
                    });
                }, eventHandler.start = function() {
                    return setStyle(logoElem, {
                        opacity: "0"
                    }), untouched = !1;
                }, eventHandler.end = function(t) {
                    return nextTick(function() {
                        return endZoom(t);
                    });
                }, eventHandler.click = function(t) {
                    return t.isMouse ? (t.zoom360 = !0, nextTick(function() {
                        return setTouch(t);
                    })) : void 0;
                };
            }, zoomSrc = void 0, doZoom = function(t) {
                var bgLeft, bgTop, imgHeight, imgPos, imgWidth, largeSrc, loadZoom, maxX, maxY, minX, minY, normalSrc, touchX, touchY, x, y, zoomLeftPos, zoomLens, zoomTopPos;
                return zoomLens = document.getElementById("zoomLens360"), void 0 === zoomSrc && (normalSrc = cfg.imageURLs[floatPart(currentAngle / Math.PI / 2) * cfg.zoomURLs.length | 0], 
                largeSrc = cfg.zoomURLs[floatPart(currentAngle / Math.PI / 2) * cfg.zoomURLs.length | 0], 
                zoomSrc = normalSrc, loadZoom = new Image(), loadZoom.onload = function() {
                    return zoomSrc === normalSrc ? (zoomSrc = largeSrc, doZoom(t)) : void 0;
                }, loadZoom.src = largeSrc), imgPos = img.getBoundingClientRect(), minY = imgPos.top, 
                maxY = imgPos.bottom, minX = imgPos.left, maxX = imgPos.right, imgWidth = maxX - minX, 
                imgHeight = maxY - minY, touchX = .5, touchY = t.isMouse ? .5 : 1.1, y = Math.min(maxY, Math.max(minY, t.y)), 
                x = Math.min(maxX, Math.max(minX, t.x)), zoomLeftPos = x + body.scrollLeft - zoomSize * touchX, 
                zoomTopPos = y + body.scrollTop - zoomSize * touchY, bgLeft = zoomSize * touchX - (x - imgPos.left) * zoomWidth / imgWidth, 
                bgTop = zoomSize * touchY - (y - imgPos.top) * zoomHeight / imgHeight, setStyle(zoomLens, {
                    display: "block",
                    position: "absolute",
                    left: zoomLeftPos + "px",
                    top: zoomTopPos + "px",
                    backgroundImage: "url(" + zoomSrc + ")",
                    backgroundSize: "" + zoomWidth + "px " + zoomHeight + "px",
                    backgroundPosition: "" + bgLeft + "px " + bgTop + "px",
                    backgroundRepeat: "no-repeat"
                });
            }, endZoom = function() {
                return zoomSrc = void 0, img.style.cursor = "url(res/cursor_rotate.cur),move", document.getElementById("zoomLens360").style.display = "none", 
                cache360Images(nop);
            }, fullScreenOriginalState = void 0, toggleFullScreen = function(e) {
                var heightPad, scaleFactor, scaleStr, style, widthPad;
                return scaleFactor = Math.min(window.innerWidth / width, window.innerHeight / height), 
                e.preventDefault(), e.stopPropagation(), fullScreenOriginalState ? (setStyle(elem, fullScreenOriginalState), 
                fullScreenOriginalState = void 0) : (style = elem.style, fullScreenOriginalState = {
                    position: style.position,
                    top: style.top,
                    left: style.top,
                    zoom: style.zoom,
                    transform: style.transform,
                    webkitTransform: style.webkitTransform,
                    transformOrigin: style.transformOrigin,
                    webkitTransformOrigin: style.webkitTransformOrigin,
                    margin: style.margin,
                    padding: style.padding
                }, scaleStr = "scale(" + scaleFactor + ", " + scaleFactor + ")", widthPad = (window.innerWidth / (scaleFactor * width) - 1) / 2 * width, 
                heightPad = (window.innerHeight / (scaleFactor * height) - 1) / 2 * height, setStyle(elem, {
                    margin: "0",
                    padding: "" + heightPad + "px " + widthPad + "px " + heightPad + "px " + widthPad + "px",
                    position: "fixed",
                    top: "0px",
                    left: "0px"
                }), "" === style.transform || "" === style.webkitTransform ? setStyle(elem, {
                    transform: scaleStr,
                    webkitTransform: scaleStr,
                    transformOrigin: "0 0",
                    webkitTransformOrigin: "0 0"
                }) : elem.style.zoom = scaleFactor), updateImage(), !1;
            };
        };
    }();
}).call(this);
