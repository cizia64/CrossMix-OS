# ozone menu driver assets

## Icons
To generate icons, go to `src/xmb/monochrome` and run `export_ozone.sh`. You will need inkscape and imagemagick.

## Fonts
The ozone fonts are a merger of the Inter UI font and the XMB menu driver font. 

To generate them (I used fontforge) :
- Font list (name, source(s), target) :
    - `regular.ttf`, XMB menu driver font, Inter UI Regular
    - `bold.ttf`, `mplus-1p-bold.ttf`& XMB menu driver font, Inter UI Bold
- For each font : 
    - Convert the source font to 2816 EM to match Inter UI
    - Open the target font and merge it with the source font
