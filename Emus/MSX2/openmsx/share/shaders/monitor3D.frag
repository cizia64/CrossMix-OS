uniform sampler2D u_tex;

in float v_color;
in vec2 v_texCoord;

out vec4 fragColor;

void main()
{
	fragColor = v_color * texture(u_tex, v_texCoord);
}
