uniform mat4 u_mvpMatrix;

in vec4 a_position;
in vec4 a_color;

out vec4 v_color;

void main()
{
	gl_Position = u_mvpMatrix * a_position;
	v_color  = a_color;
}
