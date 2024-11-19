// TV-like effect where bright pixels are larger than dark pixels.

uniform sampler2D tex;
uniform sampler2D videoTex;
uniform float minScanline;
uniform float sizeVariance;

in vec4 intCoord;
in vec4 cornerCoord0;
in vec4 cornerCoord1;

out vec4 fragColor;

vec4 calcCorner(const vec2 texCoord0,
                const vec2 texCoord1,
                const float dist)
{
	vec4 col0 = texture(tex, texCoord0);
#if SUPERIMPOSE
	vec4 vid = texture(videoTex, texCoord1);
	vec4 col = mix(vid, col0, col0.a);
#else
	vec4 col = col0;
#endif
	return col * smoothstep(
		minScanline + sizeVariance * (vec4(1.0) - col),
		vec4(1.0),
		vec4(dist));
}

void main()
{
	vec4 distComp = fract(intCoord);
	fragColor = mix(
		calcCorner(cornerCoord0.xy, cornerCoord1.xy, distComp.w) +
		calcCorner(cornerCoord0.xw, cornerCoord1.xw, distComp.y),
		calcCorner(cornerCoord0.zy, cornerCoord1.zy, distComp.w) +
		calcCorner(cornerCoord0.zw, cornerCoord1.zw, distComp.y),
		smoothstep(0.0, 1.0, distComp.x));
}
