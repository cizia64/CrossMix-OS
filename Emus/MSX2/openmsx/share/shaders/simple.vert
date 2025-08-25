uniform mat4 u_mvpMatrix;
uniform vec3 texSize;
uniform vec3 texStepX; // = vec3(vec2(1.0 / texSize.x), 0.0);
uniform vec4 cnst;     // = vec4(scan_a, scan_b, scan_c, alpha);

in vec4 a_position;
in vec3 a_texCoord;

out vec2 scaled;
out vec3 misc;
out vec2 videoCoord;

void main()
{
	float alpha  = cnst.w;

	gl_Position = u_mvpMatrix * a_position;
	misc = vec3((vec2(0.5) - vec2(1.0, 0.0) * alpha) * texStepX.x, a_texCoord.y);
	scaled = a_texCoord.xy * texSize.xy + vec2(0.0, 0.5);

#if SUPERIMPOSE
	videoCoord = a_texCoord.xz;
#endif
}
