// Scale2x scaler.

uniform sampler2D tex;
uniform sampler2D videoTex;

in vec2 texStep; // could be uniform
in vec2 coord2pi;
in vec2 texCoord;
in vec2 videoCoord;

out vec4 fragColor;

vec4 scaleNx()
{
	vec4 delta;
	delta.xw = sin(coord2pi) * texStep;
	delta.yz = vec2(0.0);

	vec4 posLeftTop  = texCoord.stst - delta;
	vec4 posRightBot = texCoord.stst + delta;

	vec4 left  = texture(tex, posLeftTop.xy);
	vec4 top   = texture(tex, posLeftTop.zw);
	vec4 right = texture(tex, posRightBot.xy);
	vec4 bot   = texture(tex, posRightBot.zw);

	if (dot(left.rgb - right.rgb, top.rgb - bot.rgb) == 0.0 || left.rgb != top.rgb) {
		return texture(tex, texCoord.st);
	} else {
		return top;
	}
}

void main()
{
#if SUPERIMPOSE
	vec4 col = scaleNx();
	vec4 vid = texture(videoTex, videoCoord);
	fragColor = mix(vid, col, col.a);
#else
	fragColor = scaleNx();
#endif
}
