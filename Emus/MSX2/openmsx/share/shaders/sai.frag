uniform sampler2D tex;
uniform sampler2D videoTex;

in vec4 posABCD;
in vec4 posEL;
in vec4 posGJ;
in vec3 scaled;
in vec2 videoCoord;

out vec4 fragColor;

void swap(inout vec4 a, inout vec4 b)
{
	vec4 t = a; a = b; b = t;
}

vec4 sai()
{
	vec4 A = texture(tex, posABCD.xy);
	vec4 B = texture(tex, posABCD.zy);
	vec4 C = texture(tex, posABCD.xw);
	vec4 D = texture(tex, posABCD.zw);
	vec3 pp = fract(scaled);

	bvec2 b1 = bvec2(A.rgb == D.rgb, B.rgb == C.rgb);
	bvec2 b2 = b1 && not(b1.yx);
	if (b2.x || b2.y) {
		vec4 pos1 = posEL.xyzw;
		vec4 pos2 = posGJ.xyzw;
		vec2 p = pp.xz;
		if (b2.y) {
			swap(A, B);
			swap(C, D);
			pos1 = posEL.zyxw;
			pos2 = posGJ.zyxw;
			p = pp.yz;
		}
		vec4 E = texture(tex, pos1.xy);
		vec4 L = texture(tex, pos1.zw);
		vec4 G = texture(tex, pos2.xy);
		vec4 J = texture(tex, pos2.zw);

		vec2 d = p / 2.0 - 0.25;
		float d2 = p.y - p.x;

		bvec4 b5 = bvec4(A.rgb == J.rgb, A.rgb == E.rgb,
		                 A.rgb == G.rgb, A.rgb == L.rgb);
		bvec4 b7 = b5 && not(b5.yxwz);
		bvec4 l;
		l.xy = lessThan(vec2(d), vec2(0.0));
		l.zw = not(l.xy);
		bvec4 b8 = l.ywzx && b7.xzyw;

		if (b8.x) {
			return mix(A, B, -d.y);
		} else if (b8.y) {
			return mix(A, C,  d.y);
		} else if (b8.z) {
			return mix(A, B,  d.x);
		} else if (b8.w) {
			return mix(A, C, -d.x);
		} else if (d2 < 0.0) {
			return mix(A, B, -d2);
		} else {
			return mix(A, C,  d2);
		}
	} else {
		return mix(mix(A, B, pp.x), mix(C, D, pp.x), pp.z);
	}
}

void main()
{
#if SUPERIMPOSE
	vec4 col = sai();
	vec4 vid = texture(videoTex, videoCoord);
	fragColor = mix(vid, col, col.a);
#else
	fragColor = sai();
#endif
}
