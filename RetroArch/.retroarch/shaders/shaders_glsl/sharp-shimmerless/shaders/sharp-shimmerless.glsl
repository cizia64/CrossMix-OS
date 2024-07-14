/*
 * sharp-shimmerless
 * Author: zadpos
 * License: Public domain
 * 
 * A retro gaming shader for sharpest pixels with no aliasing/shimmering.
 * Instead of pixels as point samples, this shader considers pixels as
 * ideal rectangles forming a grid, and interpolates pixel by calculating
 * the surface area an input pixel would occupy on an output pixel.
 */

#if defined(VERTEX)

#if __VERSION__ >= 130
#define COMPAT_VARYING out
#define COMPAT_ATTRIBUTE in
#define COMPAT_TEXTURE texture
#else
#define COMPAT_VARYING varying 
#define COMPAT_ATTRIBUTE attribute 
#define COMPAT_TEXTURE texture2D
#endif

#ifdef GL_ES
#define COMPAT_PRECISION mediump
#else
#define COMPAT_PRECISION
#endif

COMPAT_ATTRIBUTE vec4 VertexCoord;
COMPAT_ATTRIBUTE vec4 COLOR;
COMPAT_ATTRIBUTE vec4 TexCoord;
COMPAT_VARYING vec4 COL0;
COMPAT_VARYING vec4 TEX0;

uniform mat4 MVPMatrix;
uniform COMPAT_PRECISION int FrameDirection;
uniform COMPAT_PRECISION int FrameCount;
uniform COMPAT_PRECISION vec2 OutputSize;
uniform COMPAT_PRECISION vec2 TextureSize;
uniform COMPAT_PRECISION vec2 InputSize;

void main()
{
    gl_Position = MVPMatrix * VertexCoord;
    COL0 = COLOR;
    TEX0.xy = TexCoord.xy;
}

#elif defined(FRAGMENT)

#if __VERSION__ >= 130
#define COMPAT_VARYING in
#define COMPAT_TEXTURE texture
out vec4 FragColor;
#else
#define COMPAT_VARYING varying
#define FragColor gl_FragColor
#define COMPAT_TEXTURE texture2D
#endif

#ifdef GL_ES
#ifdef GL_FRAGMENT_PRECISION_HIGH
precision highp float;
#else
precision mediump float;
#endif
#define COMPAT_PRECISION mediump
#else
#define COMPAT_PRECISION
#endif

uniform COMPAT_PRECISION int FrameDirection;
uniform COMPAT_PRECISION int FrameCount;
uniform COMPAT_PRECISION vec2 OutputSize;
uniform COMPAT_PRECISION vec2 TextureSize;
uniform COMPAT_PRECISION vec2 InputSize;
uniform sampler2D Texture;
COMPAT_VARYING vec4 TEX0;

void main()
{
    vec2 pixel = TEX0.xy * OutputSize * TextureSize / InputSize;
    vec2 pixel_floored = floor(pixel);
    vec2 pixel_ceiled = ceil(pixel);
    vec2 scale = OutputSize / InputSize.xy;
    vec2 invscale = InputSize.xy / OutputSize;
    vec2 texel_floored = floor(invscale * pixel_floored);
    vec2 texel_ceiled = floor(invscale * pixel_ceiled);

    vec2 mod_texel;

    if (texel_floored.x == texel_ceiled.x) {
        // The square-pixel lies "completely in" a single column of square-texel
        mod_texel.x = texel_ceiled.x + 0.5;
    } else {
        // The square-pixel lies across two neighboring columns and must be interpolated
        mod_texel.x = texel_ceiled.x + 0.5 - (scale.x * texel_ceiled.x - pixel_floored.x);
    }

    if (texel_floored.y == texel_ceiled.y) {
        // The square-pixel lies "completely in" a single row of square-texel
        mod_texel.y = texel_ceiled.y + 0.5;   
    } else {
        // The square-pixel lies across two neighboring rows and must be interpolated
        mod_texel.y = texel_ceiled.y + 0.5 - (scale.y * texel_ceiled.y - pixel_floored.y);
    }

    FragColor = vec4(COMPAT_TEXTURE(Texture, mod_texel / TextureSize).rgb, 1.0);
} 
#endif
