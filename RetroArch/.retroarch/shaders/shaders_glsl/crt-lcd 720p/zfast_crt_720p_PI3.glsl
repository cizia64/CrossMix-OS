/*
    zfast_crt_720p - A very simple CRT shader (Integer Scaling Only version).

    Copyright (C) 2017 Greg Hogan (SoltanGris42)

    This program is free software; you can redistribute it and/or modify it
    under the terms of the GNU General Public License as published by the Free
    Software Foundation; either version 2 of the License, or (at your option)
    any later version.


Notes:  This shader does high quality scaling along the x-axis using a sharper
	variation of the algorithm here:
	
	http://www.iquilezles.org/www/articles/texture/texture.htm.
	
	Designed for the 720p output of the snes classic edition, it assumes that
	the game is scaled vertically by an integer factor of 3 and applies a
	simple scanline effect.  For a more full featured and adjustable CRT shader
	at 1080p reolutions or above you should use the ZFAST_CRT shader instead.
*/

//For testing compilation 
//#define FRAGMENT
//#define VERTEX
#define BLACK_OUT_BORDER

// Compatibility #ifdefs needed for parameters
#ifdef GL_ES
#define COMPAT_PRECISION mediump
#else
#define COMPAT_PRECISION
#endif

// Parameter lines go here:
#pragma parameter BLURSCALEX "Blur Amount X-Axis" 0.4 0.0 1.0 0.05
#pragma parameter SCANMULT "Scanline Multiplier(Low)" 2.6 0.0 10.0 0.2
#pragma parameter HIGHSCANAMOUNT "Scanline Amount (High)" 0.20 0.0 1.0 0.05
#pragma parameter MASK_DARK "Mask Effect Amount" 0.15 0.0 1.0 0.05
#pragma parameter MASK_FADE "Mask/Scanline Fade" 0.8 0.0 1.0 0.05
#pragma parameter FAKEGAMMA "Fake CRT Gamma Correction" 0.0 0.0 1.0 0.05

#ifdef PARAMETER_UNIFORM
// All parameter floats need to have COMPAT_PRECISION in front of them
uniform COMPAT_PRECISION float BLURSCALEX;
uniform COMPAT_PRECISION float SCANMULT;
uniform COMPAT_PRECISION float HIGHSCANAMOUNT;
uniform COMPAT_PRECISION float MASK_DARK;
uniform COMPAT_PRECISION float MASK_FADE;
uniform COMPAT_PRECISION float FAKEGAMMA;
#else
#define BLURSCALEX 0.40
#define SCANMULT 2.6
#define HIGHSCANAMOUNT  0.20
#define MASK_DARK 0.20
#define MASK_FADE 0.8
#define FAKEGAMMA 0.0
#endif

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
// out variables go here as COMPAT_VARYING whatever
COMPAT_VARYING vec2 gammaConst;
COMPAT_VARYING float maskFade;
COMPAT_VARYING vec2 invDims;

vec4 _oPosition1; 
uniform mat4 MVPMatrix;
uniform COMPAT_PRECISION int FrameDirection;
uniform COMPAT_PRECISION int FrameCount;
uniform COMPAT_PRECISION vec2 OutputSize;
uniform COMPAT_PRECISION vec2 TextureSize;
uniform COMPAT_PRECISION vec2 InputSize;

// compatibility #defines
#define vTexCoord TEX0.xy
#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define OutSize vec4(OutputSize, 1.0 / OutputSize)

void main()
{
    gl_Position = MVPMatrix * VertexCoord;
	
	//Terrible adjustment to texture coordinates.
	//Trying to integer scale and center image...
	
	COMPAT_PRECISION float intScale = floor(OutSize.y/InputSize.y);
	COMPAT_PRECISION float adjustTexCoord = OutSize.y/InputSize.y/intScale;
	COMPAT_PRECISION vec2 pixelsToMove = vec2(0.5*(OutSize.y-intScale*InputSize.y)*OutSize.x/OutSize.y,0.5*(OutSize.y-intScale*InputSize.y));
    TEX0.xy = (TexCoord.xy)*adjustTexCoord - (pixelsToMove/TextureSize.xy)/intScale;
	maskFade = 0.3333*MASK_FADE;
	gammaConst = vec2(1.0-0.3*FAKEGAMMA,0.3*FAKEGAMMA);
	invDims = 1.0/TextureSize.xy;
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
// in variables go here as COMPAT_VARYING whatever
COMPAT_VARYING vec2 gammaConst;
COMPAT_VARYING float maskFade;
COMPAT_VARYING vec2 invDims;

// compatibility #defines
#define Source Texture
#define vTexCoord TEX0.xy
#define texture(c, d) COMPAT_TEXTURE(c, d)
#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define OutSize vec4(OutputSize, 1.0 / OutputSize)

void main()
{

	//This is just like "Quilez Scaling" but sharper
	COMPAT_PRECISION vec2 p = vTexCoord * TextureSize;
	COMPAT_PRECISION vec2 c = floor(p) + 0.5;
	COMPAT_PRECISION vec2 f = p - c;
	p = (c + 4.0*f*f*f)*invDims;
	p.x = mix( p.x , vTexCoord.x, BLURSCALEX);

	COMPAT_PRECISION vec3 colour = texture(Source, p).rgb;
	COMPAT_PRECISION float scanLine = fract(gl_FragCoord.y * 0.333333);
	scanLine =  (HIGHSCANAMOUNT)*float( scanLine > 0.5); 
	
	COMPAT_PRECISION float whichmask = fract( gl_FragCoord.x*-0.4999);
	COMPAT_PRECISION float mask = 1.0 + float(whichmask < 0.5) * -MASK_DARK;

	colour.rgb *= mix( mask*(1.0-scanLine*SCANMULT), 1.0-scanLine, dot(colour.rgb,vec3(maskFade)));
	
#if defined(BLACK_OUT_BORDER)
colour.rgb*=float(vTexCoord.x > 0.0)*float(vTexCoord.y > 0.0); //why doesn't the driver do the right thing?
#endif

	FragColor.rgb = colour.rgb;

} 
#endif