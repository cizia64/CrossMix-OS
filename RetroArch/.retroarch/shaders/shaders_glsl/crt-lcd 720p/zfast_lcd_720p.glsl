/*
    zfast_lcd_720p - A very simple LCD shader (Integer Scaling Only version).

    Copyright (C) 2017 Greg Hogan (SoltanGris42)

    This program is free software; you can redistribute it and/or modify it
    under the terms of the GNU General Public License as published by the Free
    Software Foundation; either version 2 of the License, or (at your option)
    any later version.


Notes:  This shader just does nearest neighbor scaling of the game and then
		darkens the border pixels to imitate an LCD screen. You can change the
		amount of darkening and the thickness of the borders.  You can also 
		do basic gamma adjustment.
		
*/

//For testing compilation 
//#define FRAGMENT
//#define VERTEX
#define GBAGAMMA 

//Some drivers don't return black with texture coordinates out of bounds
//SNES Classic is too slow to black these areas out when using fullscreen
//overlays.  But you can uncomment the below to black them out if necessary
#define BLACK_OUT_BORDER

// Compatibility #ifdefs needed for parameters
#ifdef GL_ES
#define COMPAT_PRECISION mediump
#else
#define COMPAT_PRECISION
#endif

#pragma parameter BORDERTHICK "Border Thickness" 0.2 0 0.5 0.02
#pragma parameter BORDERMULT "Border Multiplier" 0.7 0.0 1.5 0.05
#ifdef PARAMETER_UNIFORM
uniform COMPAT_PRECISION float BORDERTHICK;
uniform COMPAT_PRECISION float BORDERMULT;
#else
#define BORDERTHICK 0.2
#define BORDERMULT 0.7
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

/* COMPATIBILITY
   - GLSL compilers
*/

COMPAT_ATTRIBUTE vec4 VertexCoord;
COMPAT_ATTRIBUTE vec4 COLOR;
COMPAT_ATTRIBUTE vec4 TexCoord;
COMPAT_VARYING vec4 COL0;
COMPAT_VARYING vec4 TEX0;

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

// compatibility #defines
#define Source Texture
#define vTexCoord TEX0.xy
#define texture(c, d) COMPAT_TEXTURE(c, d)
#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define OutSize vec4(OutputSize, 1.0 / OutputSize)

void main()
{
	COMPAT_PRECISION vec2 texcoordInPixels = TEX0.xy * TextureSize.xy;
	COMPAT_PRECISION vec2 centerCoord = floor(texcoordInPixels.xy)+vec2(0.5,0.5);
	texcoordInPixels.xy = fract(texcoordInPixels.xy);

	float edgeDist = min(texcoordInPixels.x,texcoordInPixels.y);

	vec2 tc = vec2( SourceSize.z*centerCoord.x , SourceSize.w*centerCoord.y);

	vec3 colour = texture2D(Texture, tc).rgb;

#if defined(GBAGAMMA)
	colour.rgb*=0.6+0.4*(colour.rgb); //fake gamma because the pi3 is too slow!
#endif

	if(edgeDist<=BORDERTHICK)
		colour.rgb*=BORDERMULT;
		
#if defined(BLACK_OUT_BORDER)
colour.rgb*=float(tc.x > 0.0)*float(tc.y > 0.0); //why doesn't the driver do the right thing?
#endif

	FragColor.rgba = vec4(colour.rgb , 1.0);
}
#endif
