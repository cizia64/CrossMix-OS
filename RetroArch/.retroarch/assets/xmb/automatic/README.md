Automatic Theme for RetroArch & Lakka
====================

About Automatic
-----------------
Automatic is a theme that is inspired by the outline artwork on Nintendo's Super Famicom box and Apple's line drawings of 1984-2014 Mac models that were featured on the 30 Years of Mac site.  Automatic builds on the work of the Systematic theme by using an outlined top-down system icon and media icons such as cartridges or discs. User interface icons use an outlined square to underscore the simplicity of the design.


Guidelines
----------

### Palette

 * Icons use white (#ffffff). If you've ever created Monochrome icons, this should feel very familiar.  Before January 2018, it was 5% gray (#2f2f2) but it was changed to white for recoloring in code, like Ozone and Monochrome.
 * Use of gradients and translucency is prohibited.  It's all about the outline.

### Layout

 * The icons should be set to a 256x256 canvas and should be centered on a 64x64 grid. 
 * The icon must have an 8px margin, effectively reducing the icon size to 240x240.
 
### Style

 * Icons design elements use an outline that is 4px thick.
 * Snap design points to the grid wherever possible to provide maximum clarity and scalability.

### Export
When converting from PDF source files, the SVG files can be created using [Alfrix’s conversion script] (https://forums.libretro.com/t/neoactive-retroactive-and-systematic-theme-support-and-feedback/9501/26) and PNG files are converted via the ImageMagick Mogrify command (mogrify -density 288 -resize 25% -format png *.pdf).

### File Names
This theme follows the naming syntax demonstrated by the Monochromatic theme.  If there are system variations, refer to the model number where possible and attach a code where necessary.

 * T = Tower or Vertical Configuration
 * (As) = Asia
 * (B) = Brazil
 * (E) = Europe
 * (J) = Japan
 * (U) = United States
 * (W) = World


Colophon
----------

### Theme Font
 * This theme uses the [Titilium Web Regular](https://fonts.google.com/specimen/Titillium+Web) typeface by the [Accademia di Belle Arti di Urbino](http://www.accademiadiurbino.it/) covered under the [Open Font License](http://scripts.sil.org/cms/scripts/page.php?site_id=nrsi&id=OFL_web).

### Support
 * If you have questions or concerns about this theme, please visit the [Libretro Forum Thread] (https://forums.libretro.com/t/neoactive-retroactive-and-systematic-theme-support-and-feedback/9501/) or the [GitHub tetrarch-assets issues page] (https://github.com/libretro/retroarch-assets/issues).