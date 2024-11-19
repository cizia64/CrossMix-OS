uniform sampler2D tex;
uniform sampler2D videoTex;
uniform vec4 cnst;
uniform vec3 texStepX; // = vec3(vec2(1.0 / texSize.x), 0.0);

in vec2 scaled;
in vec3 misc;
in vec2 videoCoord;

out vec4 fragColor;

void main()
{
	float scan_a = cnst.x;
	float scan_b = cnst.y;
	float scan_c = cnst.z;
	float alpha  = cnst.w;

	vec3 t = (vec3(floor(scaled.x)) + alpha * vec3(fract(scaled.x))) * texStepX + misc;
	vec4 col1 = texture(tex, t.xz);
	vec4 col2 = texture(tex, t.yz);

	float scan = scan_c + scan_b * abs(fract(scaled.y) - scan_a);
#if SUPERIMPOSE
	vec4 col = (col1 + col2) / 2.0;
	vec4 vid = texture(videoTex, videoCoord);
	fragColor = mix(vid, col, col.a) * scan;
#else
	// optimization: in case of not-superimpose, we moved the division by 2
	// '(col1 + col2) / 2' to the 'scan_b' and 'scan_c' variables.
	fragColor = (col1 + col2) * scan;
#endif
}
