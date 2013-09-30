# ![.](https://ssl.solsort.com/_solsort.png) 360º viewer component
## Done

- Full version up and running
- browser-support: IE8+, iOS 5+ Android 4+
- rotate on drag
- handle touch and mouse
- zoom-lens effect(on desktop+mobile)
- zoom on click (on desktop) and on hold (on mobile)
- cursor icon
- image caching / preloader
- animate on load

## TODO
### Initial version

- avoid moving zoom-lens beyond image / constraint on edge
- gif progress indicator
- connect with API
    - test/make sure it works also wit small data sets of 1. picture
- zoom button
- fullscreen button
- labels/markers/interaction points
- logo on top w/ fade-in/fade-out (maybe hide on touch after first interaction)
    - nb. a la http://hammerti.me/workspace/photosphere
- customer logo
- fullscreen(on both desktop and mobile)
- talk with api
- multitouch - see if we can enable zoom/scroll by no-preventDefault when multifinger

### Future

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
