uniform mat4 u_mvpMatrix;
uniform vec3 texSize;

in vec4 a_position;
in vec3 a_texCoord;

out vec4 scaled;
out vec2 pos;
out vec2 videoCoord;

void main()
{
	gl_Position = u_mvpMatrix * a_position;
	vec2 tmp = a_texCoord.xy * texSize.xy;
	scaled = tmp.xxxy + vec4(0.0, 1.0/3.0, 2.0/3.0, 0.5);
	pos        = a_texCoord.xy;
#if SUPERIMPOSE
	videoCoord = a_texCoord.xz;
#endif
}
