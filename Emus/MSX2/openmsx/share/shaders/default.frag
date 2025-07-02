uniform sampler2D tex;
uniform sampler2D videoTex;

in vec2 texCoord;
in vec2 videoCoord;

out vec4 fragColor;

void main()
{
#if SUPERIMPOSE
	vec4 col = texture(tex, texCoord);
	vec4 vid = texture(videoTex, videoCoord);
	fragColor = mix(vid, col, col.a);
#else
	fragColor = texture(tex, texCoord);
#endif
}
