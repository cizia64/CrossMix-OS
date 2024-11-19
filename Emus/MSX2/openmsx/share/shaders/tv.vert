uniform mat4 u_mvpMatrix;
uniform vec3 texSize; // xy = texSize1,  xz = texSize2

in vec4 a_position;
in vec3 a_texCoord;

out vec4 intCoord;
out vec4 cornerCoord0;
out vec4 cornerCoord1;

void main()
{
	gl_Position = u_mvpMatrix * a_position;
	intCoord.xy = a_texCoord.xy * texSize.xy;
	intCoord.zw = -intCoord.xy;
	cornerCoord0 = vec4(a_texCoord.xy,
	                    a_texCoord.xy + 1.0 / texSize.xy);
	cornerCoord1 = vec4(a_texCoord.xz,
	                    a_texCoord.xz + 1.0 / texSize.xz);
}
