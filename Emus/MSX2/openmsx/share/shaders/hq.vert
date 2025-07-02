uniform mat4 u_mvpMatrix;
uniform vec3 texSize;

in vec4 a_position;
in vec3 a_texCoord;

out vec2 mid;
out vec2 leftTop;
out vec2 edgePos;
out vec2 weightPos;
out vec2 texStep2; // could be uniform
out vec2 videoCoord;

void main()
{
	gl_Position = u_mvpMatrix * a_position;

	vec2 texStep = 1.0 / texSize.xy;
	mid     = a_texCoord.xy;
	leftTop = a_texCoord.xy - texStep;

	edgePos = a_texCoord.xy * vec2(1.0, 2.0);
	weightPos = edgePos * texSize.xy * vec2(1.0, 0.5);

	texStep2 = 2.0 * texStep;

#if SUPERIMPOSE
	videoCoord = a_texCoord.xz;
#endif
}
