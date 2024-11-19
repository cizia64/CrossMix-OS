uniform sampler2D edgeTex;
uniform sampler2D colorTex;
uniform sampler2D offsetTex;
uniform sampler2D videoTex;

in vec2 leftTop;
in vec2 edgePos;
in vec4 misc;
in vec2 videoCoord;

out vec4 fragColor;

void main()
{
	float edgeBits = texture(edgeTex, edgePos).x;
	//fragColor = vec4(edgeBits, fract(edgeBits * 16.0), fract(edgeBits * 256.0), 1.0);

	// transform (N x N x 4096) to (64N x 64N) texture coords
	float t = 64.0 * edgeBits;
	vec2 xy = vec2(fract(t), floor(t)/64.0);
	vec2 subPixelPos = misc.xy;
	xy += fract(subPixelPos) / 64.0;
	vec2 offset = texture(offsetTex, xy).xw;

	// fract not really needed, but it eliminates one MOV instruction
	vec2 texStep2 = fract(misc.zw);
	vec4 col = texture(colorTex, leftTop + offset * texStep2);

#if SUPERIMPOSE
	vec4 vid = texture(videoTex, videoCoord);
	fragColor = mix(vid, col, col.a);
#else
	fragColor = col;
#endif
}
