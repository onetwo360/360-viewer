# ![.](https://ssl.solsort.com/_solsort.png) 360º viewer component
## Done

### Milestone 0 - September 2013

- Version up and running
- Browser-support: IE8+, iOS 5+ Android 4+
- Rotate on drag
- Handle touch and mouse
- Zoom-lens effect(on desktop+mobile)
- Zoom on click (on desktop) and on hold (on mobile)
- Cursor icon
- Image caching / preloader
- Animate on load

### Milestone 1 - October/November 2013
- avoid moving zoom-lens beyond image / constraint on edge
- allow interaction during rotate
- gif spinner indicator
- logo on top with fade-out 
- zoom button
- fullscreen button
- fullscreen(on both desktop and mobile)

## TODO

### Initial version

- connect with API (implemented with local version, waiting for proper jsonp on backend)
- labels/markers/interaction points
- customer logo
- multitouch - see if we can enable zoom/scroll by no-preventDefault when multifinger
- IE - test

### Future

- dynamic load hi-res images (on fullscreen after 2s same image + zoom use scaled lo-res when starting) + recache lo-res
- fullscreen issues on android when user-scaleable
- maybe close fullscreen on click outside image
- test/make sure it works also wit small data sets of 1. picture
- icons / documentation - zoom-lense(desktop), fullscreen, close(fullscreen)
- animate during load, instead of animate on load
- thumbnails when few pictures (maybe instead of drag)
- smoother animate on load

## Why img.src replacement

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
