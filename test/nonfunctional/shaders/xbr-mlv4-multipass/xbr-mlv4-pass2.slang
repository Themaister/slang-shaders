#version 450

layout(push_constant) uniform Push
{
	vec4 SourceSize;
	vec4 OriginalSize;
	vec4 OutputSize;
	uint FrameCount;
} params;

layout(std140, set = 0, binding = 0) uniform UBO
{
	mat4 MVP;
} global;

/*

   Hyllian's xBR MultiLevel4 Shader - Pass2
   
   Copyright (C) 2011-2015 Hyllian - sergiogdb@gmail.com

   Permission is hereby granted, free of charge, to any person obtaining a copy
   of this software and associated documentation files (the "Software"), to deal
   in the Software without restriction, including without limitation the rights
   to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
   copies of the Software, and to permit persons to whom the Software is
   furnished to do so, subject to the following conditions:

   The above copyright notice and this permission notice shall be included in
   all copies or substantial portions of the Software.

   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
   IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
   FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
   AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
   LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
   OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
   THE SOFTWARE.

*/

#define round(X) floor((X)+0.5)

const float cf2             = 2.0;
const float cf3             = 4.0;
const float cf4             = 4.0;
const vec4 eq_threshold   = vec4(15.0, 15.0, 15.0, 15.0);
const vec4 eq_threshold2  = vec4( 5.0,  5.0,  5.0,  5.0);
const vec4 eq_threshold3  = vec4(25.0, 25.0, 25.0, 25.0);
const float y_weight        = 48.0;
const float u_weight        = 7.0;
const float v_weight        = 6.0;
const mat3x3 yuv          = mat3x3(0.299, 0.587, 0.114, -0.169, -0.331, 0.499, 0.499, -0.418, -0.0813);
const mat3x3 yuv_weighted = mat3x3(y_weight*yuv[0], u_weight*yuv[1], v_weight*yuv[2]);
const vec4 maximo         = vec4(255.0f, 255.0f, 255.0f, 255.0f);


vec4 df(vec4 A, vec4 B)
{
	return vec4(abs(A-B));
}

bvec4 rd(vec4 A, vec4 B, vec4 C, vec4 D)
{
    return (greaterThan(df(C,D)/(df(A,B)+0.000000001) , vec4(2.0)));
}

bvec4 id(vec4 A, vec4 B, vec4 C, vec4 D)
{
    return greaterThan(df(C,D) , df(A,B));
}

vec4 remapTo01(vec4 v, vec4 high)
{
	return (v/high);
}

vec4 remapFrom01(vec4 v, vec4 high)
{
	return round(high*v);
}

bvec4 eq(vec4 A, vec4 B)
{
	return lessThan(df(A, B) , eq_threshold);
}

bvec4 eq2(vec4 A, vec4 B)
{
	return lessThan(df(A, B) , eq_threshold2);
}

bvec4 eq3(vec4 A, vec4 B)
{
	return lessThan(df(A, B) , eq_threshold3);
}

vec4 weighted_distance(vec4 a, vec4 b, vec4 c, vec4 d, vec4 e, vec4 f, vec4 g, vec4 h)
{
	return (df(a,b) + df(a,c) + df(d,e) + df(d,f) + 4.0*df(g,h));
}

#pragma stage vertex
layout(location = 0) in vec4 Position;
layout(location = 1) in vec2 TexCoord;
layout(location = 0) out vec2 vTexCoord;
layout(location = 1) out vec4 t1;
layout(location = 2) out vec4 t2;
layout(location = 3) out vec4 t3;
layout(location = 4) out vec4 t4;
layout(location = 5) out vec4 t5;
layout(location = 6) out vec4 t6;
layout(location = 7) out vec4 t7;

void main()
{
   gl_Position = global.MVP * Position;
   vTexCoord = TexCoord;
   
   	float dx = params.SourceSize.z;
	float dy = params.SourceSize.w;
   
	//    A1 B1 C1
	// A0  A  B  C C4
	// D0  D  E  F F4
	// G0  G  H  I I4
	//    G5 H5 I5
	
	t1 = vTexCoord.xxxy + vec4( -dx, 0, dx,-2.0*dy); // A1 B1 C1
	t2 = vTexCoord.xxxy + vec4( -dx, 0, dx,    -dy); //  A  B  C
	t3 = vTexCoord.xxxy + vec4( -dx, 0, dx,      0); //  D  E  F
	t4 = vTexCoord.xxxy + vec4( -dx, 0, dx,     dy); //  G  H  I
	t5 = vTexCoord.xxxy + vec4( -dx, 0, dx, 2.0*dy); // G5 H5 I5
	t6 = vTexCoord.xyyy + vec4(-2.0*dx,-dy, 0,  dy); // A0 D0 G0
	t7 = vTexCoord.xyyy + vec4( 2.0*dx,-dy, 0,  dy); // C4 F4 I4
}

#pragma stage fragment
layout(location = 0) in vec2 vTexCoord;
layout(location = 1) in vec4 t1;
layout(location = 2) in vec4 t2;
layout(location = 3) in vec4 t3;
layout(location = 4) in vec4 t4;
layout(location = 5) in vec4 t5;
layout(location = 6) in vec4 t6;
layout(location = 7) in vec4 t7;
layout(location = 0) out vec4 FragColor;
layout(set = 0, binding = 2) uniform sampler2D Source;
layout(set = 0, binding = 3) uniform sampler2D Original;

void main()
{
	vec4 PA  = texture(Source, t2.xw);
	vec4 PB  = texture(Source, t2.yw);
	vec4 PC  = texture(Source, t2.zw);

	vec4 PD  = texture(Source, t3.xw);
	vec4 PE  = texture(Source, t3.yw);
	vec4 PF  = texture(Source, t3.zw);

	vec4 PG  = texture(Source, t4.xw);
	vec4 PH  = texture(Source, t4.yw);
	vec4 PI  = texture(Source, t4.zw);
	
	vec3 A1 = texture(Original, t1.xw).rgb;
	vec3 B1 = texture(Original, t1.yw).rgb;
	vec3 C1 = texture(Original, t1.zw).rgb;

	vec3 A  = texture(Original, t2.xw).rgb;
	vec3 B  = texture(Original, t2.yw).rgb;
	vec3 C  = texture(Original, t2.zw).rgb;

	vec3 D  = texture(Original, t3.xw).rgb;
	vec3 E  = texture(Original, t3.yw).rgb;
	vec3 F  = texture(Original, t3.zw).rgb;

	vec3 G  = texture(Original, t4.xw).rgb;
	vec3 H  = texture(Original, t4.yw).rgb;
	vec3 I  = texture(Original, t4.zw).rgb;

	vec3 G5 = texture(Original, t5.xw).rgb;
	vec3 H5 = texture(Original, t5.yw).rgb;
	vec3 I5 = texture(Original, t5.zw).rgb;

	vec3 A0 = texture(Original, t6.xy).rgb;
	vec3 D0 = texture(Original, t6.xz).rgb;
	vec3 G0 = texture(Original, t6.xw).rgb;

	vec3 C4 = texture(Original, t7.xy).rgb;
	vec3 F4 = texture(Original, t7.xz).rgb;
	vec3 I4 = texture(Original, t7.xw).rgb;
	
	vec4 b = yuv_weighted[0] * mat4x3(B, D, H, F);
	vec4 c = yuv_weighted[0] * mat4x3(C, A, G, I);
	vec4 e = yuv_weighted[0] * mat4x3(E, E, E, E);
	vec4 d = b.yzwx;
	vec4 f = b.wxyz;
	vec4 g = c.zwxy;
	vec4 h = b.zwxy;
	vec4 i = c.wxyz;
	
	vec4 i4 = yuv_weighted[0] * mat4x3(I4, C1, A0, G5);
	vec4 i5 = yuv_weighted[0] * mat4x3(I5, C4, A1, G0);
	vec4 h5 = yuv_weighted[0] * mat4x3(H5, F4, B1, D0);
	vec4 f4 = h5.yzwx;

	vec4 pe = remapFrom01(PE, maximo);
	vec4 pf = remapFrom01(PF, maximo);
	vec4 ph = remapFrom01(PH, maximo);
	vec4 pb = remapFrom01(PB, maximo);
	vec4 pd = remapFrom01(PD, maximo);
	
	vec4 f2 = vec4(pf.z, pb.w, pd.x, ph.y);
	vec4 h2 = vec4(ph.z, pf.w, pb.x, pd.y);
	vec4 f1 = vec4(pf.y, pb.z, pd.w, ph.x);
	vec4 h3 = vec4(ph.w, pf.x, pb.y, pd.z);
	
	bvec4 nbrs =	(greaterThan(pe.yzwx,	vec4(1.0))	==	bvec4(true)	||	greaterThan(pe.wxyz,	vec4(1.0)) == bvec4(true)) ? bvec4(true) : bvec4(false);
	bvec4 jag1 =	(greaterThan(f2,		vec4(1.0))	==	bvec4(true)	||	greaterThan(h2,			vec4(1.0)) == bvec4(true)) ? bvec4(true) : bvec4(false);
	bvec4 jag2 =	(greaterThan(f2,		vec4(2.0))	==	bvec4(true)	||	greaterThan(h2,			vec4(2.0)) == bvec4(true)) ? bvec4(true) : bvec4(false);
	bvec4 jag3 =	(greaterThan(f2,		vec4(4.0))	==	bvec4(true)	||	greaterThan(h2,			vec4(4.0)) == bvec4(true)) ? bvec4(true) : bvec4(false);

	pe = (pe == vec4(7.0) || pe == vec4(8.0)) ? ((jag3 == bvec4(true)) ? pe : (pe - float(2.0))) : pe;
	pe = (pe == vec4(5.0) || pe == vec4(6.0)) ? ((jag2 == bvec4(true)) ? pe : (pe - float(2.0))) : pe;
	
	bvec4 jag91 = ((id(h,i,e,h) == bvec4(true) || id(i4,i,f4,i4) == bvec4(true)) && greaterThan(f2 , vec4(1.0)) == bvec4(true) && greaterThan(f1 , vec4(1.0)) == bvec4(true)) ? bvec4(true) : bvec4(false);
	bvec4 jag92 = ((id(f,i,e,f) == bvec4(true) || id(i5,i,h5,i5) == bvec4(true)) && greaterThan(h2 , vec4(1.0)) == bvec4(true) && greaterThan(h3 , vec4(1.0)) == bvec4(true)) ? bvec4(true) : bvec4(false);
	bvec4 jag93 = ( rd(h,g,e,g) == bvec4(true)) ? bvec4(true) : bvec4(false);
	bvec4 jag94 = ( rd(f,c,e,c) == bvec4(true)) ? bvec4(true) : bvec4(false);
	bvec4 jag9  = ((jag91 == bvec4(true) && jag93 == bvec4(true) || jag92 == bvec4(true) && jag94 == bvec4(true)) == false) ? bvec4(true) : bvec4(false);
		
	pe = ((pe == vec4(0.0)) || (nbrs == bvec4(false) || jag1 == bvec4(true)) && jag9 == bvec4(true)) ? pe : vec4(1.0);

   FragColor = vec4(remapTo01(pe, maximo));
}