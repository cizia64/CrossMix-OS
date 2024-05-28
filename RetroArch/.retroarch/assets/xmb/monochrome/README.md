XMB Monochrome Theme
====================

Guidelines
----------

### Palette

 * The icons have only one color, pure white (#ffffff).
 * No semi transparent parts except for anti-aliasing purpose.

### Layout

 * The shape should be easily recognizable.
 * The shapes should be, when possible, aligned to a 64x64 grid, but exported as 256x256 PNGs, to downscale nicely.
 * The shapes should be included in a circle of radius 31px (except when the shape is itself a circle, then we make it smaller), to insure consistent sizes.
 * Some special icons have a superelliptic shape with a substracted symbol. They have an associated content icon figuring the same symbol. Symbols should match.

### Style

 * The border radius are either 1px, or 2px.
 * Lines are 2px.
 * The level of detail is reduced, we try to represent every button, but we can void representing stickers or color changes.

### Export

The PNGs are better exported by the old Inkscape v0.48.5. Later versions causes a premultiplied alpha issue with our mipmaping and blending code.

### Theme Font
 * This theme uses the [M+ P Type-1 Regular](http://mplus-fonts.osdn.jp/design.html#mplus_p1) typeface by the [M+ Fonts Project](http://mplus-fonts.osdn.jp/) covered under the [Free License](http://mplus-fonts.osdn.jp/about-en.html#license).
