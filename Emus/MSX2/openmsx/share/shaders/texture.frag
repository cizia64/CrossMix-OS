uniform sampler2D u_tex;
uniform vec4 u_color;

in vec2 v_texCoord;

out vec4 fragColor;

void main()
{
	fragColor = texture(u_tex, v_texCoord) * u_color;
}
