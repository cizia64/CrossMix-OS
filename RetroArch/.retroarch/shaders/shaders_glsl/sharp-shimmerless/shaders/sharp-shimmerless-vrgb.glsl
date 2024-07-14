/*
 * sharp-shimmerless-vrgb
 * Author: zadpos
 * License: Public domain
 * 
 * Sharp-Shimmerless shader for v-RGB subpixels
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
    vec2 pixel_xy = TEX0.xy * OutputSize * TextureSize / InputSize;
    vec4 pixel_floored = floor(pixel_xy).xyyy;
    pixel_floored.y -= 0.33;
    pixel_floored.w += 0.33;
    vec4 pixel_ceiled = ceil(pixel_xy).xyyy;
    pixel_ceiled.y -= 0.33;
    pixel_ceiled.w += 0.33;

    vec4 scale = OutputSize.xyyy / InputSize.xyyy;
    vec4 invscale = InputSize.xyyy / OutputSize.xyyy;

    vec4 texel_floored = floor(invscale * pixel_floored);
    vec4 texel_ceiled = floor(invscale * pixel_ceiled);

    vec4 mod_texel;

    if (texel_floored.x == texel_ceiled.x) {
        mod_texel.x = texel_ceiled.x + 0.5;
    } else {
        mod_texel.x = texel_ceiled.x + 0.5 - (scale.x * texel_ceiled.x - pixel_floored.x);
    }

    if (texel_floored.y == texel_ceiled.y) {
        mod_texel.y = texel_ceiled.y + 0.5;   
    } else {
        mod_texel.y = texel_ceiled.y + 0.5 - (scale.y * texel_ceiled.y - pixel_floored.y);
    }

    if (texel_floored.z == texel_ceiled.z) {
        mod_texel.z = texel_ceiled.z + 0.5;   
    } else {
        mod_texel.z = texel_ceiled.z + 0.5 - (scale.z * texel_ceiled.z - pixel_floored.z);
    }

    if (texel_floored.w == texel_ceiled.w) {
        mod_texel.w = texel_ceiled.w + 0.5;   
    } else {
        mod_texel.w = texel_ceiled.w + 0.5 - (scale.w * texel_ceiled.w - pixel_floored.w);
    }

    FragColor.r = COMPAT_TEXTURE(Texture, mod_texel.xy / TextureSize).r;
    FragColor.g = COMPAT_TEXTURE(Texture, mod_texel.xz / TextureSize).g;
    FragColor.b = COMPAT_TEXTURE(Texture, mod_texel.xw / TextureSize).b;
    FragColor.a = 1.0;
} 
#endif
