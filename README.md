# ![.](https://ssl.solsort.com/_solsort.png) 360º Notes
## TODO
### Initial version

- cursor icon
- icons - zoom-lense(desktop), fullscreen, close(fullscreen)
- logo
- fullscreen(on both desktop and mobile)
- zoom(on desktop, mobile postponed)
- multitouch
- talk with api
- labels/markers
- browser-support: IE8+, iOS 5+ Android 4+

### Future

- animate during load, instead of animate on load

## Done

- image caching / preloader
- rotate - drag
- singletouch
- animate on load
- drag

## Interaction

- drag left/right: rotate
  - rotation = x-drag scaled
- tap/click: fullscreen, click on X or outside centered image to close
- zoom (multitouch+multidrag: iOS + android 2.3.3+, zoom-button with lens on desktop)

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
