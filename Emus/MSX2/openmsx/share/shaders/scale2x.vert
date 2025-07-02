uniform mat4 u_mvpMatrix;
uniform vec3 texSize;

in vec4 a_position;
in vec3 a_texCoord;

out vec2 texStep; // could be uniform
out vec2 coord2pi;
out vec2 texCoord;
out vec2 videoCoord;

float pi = 4.0 * atan(1.0);
float pi2 = 2.0 * pi;

void main()
{
	gl_Position = u_mvpMatrix * a_position;
	texCoord = a_texCoord.xy;
	coord2pi = a_texCoord.xy * texSize.xy * pi2;
	texStep = 1.0 / texSize.xy;

#if SUPERIMPOSE
	videoCoord = a_texCoord.xz;
#endif
}
