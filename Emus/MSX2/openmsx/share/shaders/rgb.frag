uniform sampler2D tex;
uniform sampler2D videoTex;
uniform vec4 cnsts;

in vec4 scaled;
in vec2 pos;
in vec2 videoCoord;

out vec4 fragColor;

// saturate operations are free on nvidia hardware
vec3 saturate(vec3 x)
{
	return clamp(x, 0.0, 1.0);
}

void main()
{
	float scan_a    = cnsts.x;
	float scan_b_c2 = cnsts.y; // scan_b * c2
	float scan_c_c2 = cnsts.z; // scan_c * c2
	float c1_2_2    = cnsts.w; // (c1 - c2) / c2

	float scan_c2 = scan_c_c2 + scan_b_c2 * abs(fract(scaled.w) - scan_a);

	const float BIG = 128.0; // big number, actual value is not important
	vec3 m = saturate((-BIG * fract(scaled.zyx)) + vec3(2.0 * BIG / 3.0));

	vec4 col = texture(tex, pos);
#if SUPERIMPOSE
	vec4 vid = texture(videoTex, videoCoord);
	vec4 p = mix(vid, col, col.a);
#else
	vec4 p = col;
#endif
	vec3 n = p.rgb * scan_c2;
	vec3 s_n = n * c1_2_2 + saturate((n - 1.0) / 2.0);
	fragColor.rgb = n + m * s_n;
	fragColor.a   = p.a;
}
