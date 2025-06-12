uniform sampler2D edgeTex;
uniform sampler2D colorTex;
uniform sampler2D offsetTex;
uniform sampler2D weightTex;
uniform sampler2D videoTex;

in vec2 mid;
in vec2 leftTop;
in vec2 edgePos;
in vec2 weightPos;
in vec2 texStep2; // could be uniform
in vec2 videoCoord;

out vec4 fragColor;

void main()
{
	float edgeBits = texture(edgeTex, edgePos).z;
	//fragColor = vec4(edgeBits, fract(edgeBits * 16.0), fract(edgeBits * 256.0), 1.0);

	// transform (N x N x 4096) to (64N x 64N) texture coords
	float t = 64.0 * edgeBits;
	vec2 xy = vec2(fract(t), floor(t)/64.0);
	xy += fract(weightPos) / 64.0;
	vec4 offsets = texture(offsetTex, xy);
	vec3 weights = texture(weightTex, xy).xyz;

	vec4 c5 = texture(colorTex, mid);
	vec4 cx = texture(colorTex, leftTop + texStep2 * offsets.xy);
	vec4 cy = texture(colorTex, leftTop + texStep2 * offsets.zw);

	vec4 col = cx * weights.x + cy * weights.y + c5 * weights.z;

#if SUPERIMPOSE
	vec4 vid = texture(videoTex, videoCoord);
	fragColor = mix(vid, col, col.a);
#else
	fragColor = col;
#endif
}
