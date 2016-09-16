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

   Hyllian's xBR MultiLevel4 Shader - Pass1
   
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
#define TEX(dx,dy) texture(Source, vTexCoord + vec2((dx), (dy)) * t1).rgb

const float cf2	=	2.0;
const float cf3	=	4.0;
const float cf4	=	4.0;
const vec4 eq_thresholdold	=	vec4(15.0, 15.0, 15.0, 15.0);
const vec4 eq_threshold	=	vec4( 2.0,  2.0,  2.0,  2.0);
const vec4 eq_threshold3	=	vec4(25.0, 25.0, 25.0, 25.0);
const vec3 Yuv_weight	=	vec3(4.0, 1.0, 2.0);
const mat3x3	yuv	=	mat3x3(0.299, 0.587, 0.114,
								-0.169, -0.331, 0.499,
								0.499, -0.418, -0.0813);
const mat3x3	yuvT	=	mat3x3(0.299, -0.169,  0.499,
								0.587, -0.331, -0.418,
								0.114,  0.499, -0.0813); 
const mat3x3	yuv_weighted	=	mat3x3(Yuv_weight.x * yuv[0], Yuv_weight.y * yuv[1], Yuv_weight.z * yuv[2]);
const vec4 maximo	=	vec4(255.0f, 255.0f, 255.0f, 255.0f);

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

bvec4 eq(vec4 A, vec4 B)
{
	return lessThan(df(A, B) , eq_threshold);
}

bvec4 eq3(vec4 A, vec4 B)
{
	return lessThan(df(A, B) , eq_threshold3);
}

vec4 weighted_distance(vec4 a, vec4 b, vec4 c, vec4 d, vec4 e, vec4 f, vec4 g, vec4 h)
{
	return (df(a,b) + df(a,c) + df(d,e) + df(d,f) + 4.0 * df(g,h));
}

#pragma stage vertex
layout(location = 0) in vec4 Position;
layout(location = 1) in vec2 TexCoord;
layout(location = 0) out vec2 vTexCoord;
layout(location = 1) out vec2 t1;

void main()
{
	gl_Position	=	global.MVP * Position;
	vTexCoord	=	TexCoord;

	//      A3 B3 C3
	//      A1 B1 C1
	//A2 A0  A  B  C C4 C6
	//D2 D0  D  E  F F4 F6
	//G2 G0  G  H  I I4 I6
	//      G5 H5 I5
	//      G7 H7 I7
	
	t1	=	vec2(params.SourceSize.z, params.SourceSize.w);  // F  H
}

#pragma stage fragment
layout(location = 0) in vec2 vTexCoord;
layout(location = 1) in vec2 t1;
layout(location = 0) out vec4 FragColor;
layout(set = 0, binding = 2) uniform sampler2D Source;

void main()
{
	bvec4 edr0, edr, edr_left, edr_up, edr3_left, edr3_up, edr4_left, edr4_up; // edr = edge detection rule
	bvec4 interp_restriction_lv1, interp_restriction_lv2_left, interp_restriction_lv2_up;
	bvec4 interp_restriction_lv3_left, interp_restriction_lv3_up;
	bvec4 interp_restriction_lv4_left, interp_restriction_lv4_up;
	
															vec3	A3	=	TEX(-1,-3);	vec3	B3	=	TEX( 0,-3);	vec3	C3	=	TEX( 1,-3);	
															vec3	A1	=	TEX(-1,-2);	vec3	B1	=	TEX( 0,-2);	vec3	C1	=	TEX( 1,-2);
	vec3	A2	=	TEX(-3,-1);	vec3	A0	=	TEX(-2,-1);	vec3	A	=	TEX(-1,-1);	vec3	B	=	TEX( 0,-1);	vec3	C	=	TEX( 1,-1);	vec3	C4	=	TEX( 2,-1);	vec3	C6	=	TEX( 3,-1);
	vec3	D2	=	TEX(-3, 0);	vec3	D0	=	TEX(-2, 0);	vec3	D	=	TEX(-1, 0);	vec3	E	=	TEX( 0, 0);	vec3	F	=	TEX( 1, 0);	vec3	F4	=	TEX( 2, 0);	vec3	F6	=	TEX( 3, 0);
	vec3	G2	=	TEX(-3, 1);	vec3	G0	=	TEX(-2, 1);	vec3	G 	=	TEX(-1, 1);	vec3	H 	=	TEX( 0, 1);	vec3	I 	=	TEX( 1, 1);	vec3	I4	=	TEX( 2, 1);	vec3	I6	=	TEX( 3, 1);
															vec3	G5	=	TEX(-1, 2);	vec3	H5	=	TEX( 0, 2);	vec3	I5	=	TEX( 1, 2);
															vec3	G7	=	TEX(-1, 3);	vec3	H7	=	TEX( 0, 3);	vec3	I7	=	TEX( 1, 3);
	
	mat4x3	bdhf0	=	yuvT * mat4x3(B, D, H, F);
	bdhf0	=	mat4x3(abs(bdhf0[0]), abs(bdhf0[1]), abs(bdhf0[2]), abs(bdhf0[3]));
	vec4 b	=	Yuv_weight * bdhf0;

	mat4x3	bdhf1	=	yuvT * mat4x3(C, A, G, I);
	bdhf1	=	mat4x3(abs(bdhf1[0]), abs(bdhf1[1]), abs(bdhf1[2]), abs(bdhf1[3]));
	vec4 c	=	Yuv_weight * bdhf1;

	mat4x3	bdhf2	=	yuvT * mat4x3(E, E, E, E);
	bdhf2	=	mat4x3(abs(bdhf2[0]), abs(bdhf2[1]), abs(bdhf2[2]), abs(bdhf2[3]));
	vec4 e	=	Yuv_weight * bdhf2;
	
	vec4 d	=	b.yzwx;
	vec4 f	=	b.wxyz;
	vec4 g	=	c.zwxy;
	vec4 h	=	b.zwxy;
	vec4 i	=	c.wxyz;
	
	mat4x3	bdhf3	=	yuvT * mat4x3(I4, C1, A0, G5);
	bdhf3	=	mat4x3(abs(bdhf3[0]), abs(bdhf3[1]), abs(bdhf3[2]), abs(bdhf3[3]));
	vec4 i4	=	Yuv_weight * bdhf3;

	mat4x3	bdhf4	=	yuvT * mat4x3(I5, C4, A1, G0);
	bdhf4	=	mat4x3(abs(bdhf4[0]), abs(bdhf4[1]), abs(bdhf4[2]), abs(bdhf4[3]));
	vec4 i5	=	Yuv_weight * bdhf4;

	mat4x3	bdhf5	=	yuvT * mat4x3(H5, F4, B1, D0);
	bdhf5	=	mat4x3(abs(bdhf5[0]), abs(bdhf5[1]), abs(bdhf5[2]), abs(bdhf5[3]));
	vec4 h5	=	Yuv_weight * bdhf5;
	
	vec4	f4	=	h5.yzwx;
	vec4	c1	=	i4.yzwx;
	vec4	g0	=	i5.wxyz;
	vec4	b1	=	h5.zwxy;
	vec4	d0	=	h5.wxyz;
	
	mat4x3	bdhf6	=	yuvT * mat4x3(I6, C3, A2, G7);
	bdhf6	=	mat4x3(abs(bdhf6[0]), abs(bdhf6[1]), abs(bdhf6[2]), abs(bdhf6[3]));
	vec4 i6	=	Yuv_weight * bdhf6;

	mat4x3	bdhf7	=	yuvT * mat4x3(I7, C6, A3, G2);
	bdhf7	=	mat4x3(abs(bdhf7[0]), abs(bdhf7[1]), abs(bdhf7[2]), abs(bdhf7[3]));
	vec4 i7	=	Yuv_weight * bdhf7;

	mat4x3	bdhf8	=	yuvT * mat4x3(H7, F6, B3, D2);
	bdhf8	=	mat4x3(abs(bdhf8[0]), abs(bdhf8[1]), abs(bdhf8[2]), abs(bdhf8[3]));
	vec4 h7	=	Yuv_weight * bdhf8;
	
	vec4 f6	=	h7.yzwx;
	vec4 c3	=	i6.yzwx;
	vec4 g2	=	i7.wxyz;
	vec4 b3	=	h7.zwxy;
	vec4 d2	=	h7.wxyz;
	
	interp_restriction_lv1     	=	(notEqual(e,f )	==	bvec4(true)	&&	notEqual(e,h)	==	bvec4(true))	?	bvec4(true)	:	bvec4(false);
	interp_restriction_lv2_left	=	(notEqual(e,g )	==	bvec4(true)	&&	notEqual(d,g)	==	bvec4(true)	&&	(eq(e, d)	==	bvec4(true)	||	eq(h, g)	==	bvec4(true)))	?	bvec4(true)	:	bvec4(false);
	interp_restriction_lv2_up  	=	(notEqual(e,c )	==	bvec4(true)	&&	notEqual(b,c)	==	bvec4(true)	&&	(eq(e, b)	==	bvec4(true)	||	eq(f, c)	==	bvec4(true)))	?	bvec4(true)	:	bvec4(false);
	interp_restriction_lv3_left	=	(notEqual(e,g0)	==	bvec4(true)	&&	notEqual(d0,g0)	==	bvec4(true)	&&	(eq(d,d0)	==	bvec4(true)	||	eq(g,g0)	==	bvec4(true)))	?	bvec4(true)	:	bvec4(false);
	interp_restriction_lv3_up  	=	(notEqual(e,c1)	==	bvec4(true)	&&	notEqual(b1,c1)	==	bvec4(true)	&&	(eq(b,b1)	==	bvec4(true)	||	eq(c,c1)	==	bvec4(true)))	?	bvec4(true)	:	bvec4(false);
	interp_restriction_lv4_left	=	(notEqual(e,g2)	==	bvec4(true)	&&	notEqual(d2,g2)	==	bvec4(true)	&&	(eq(d0,d2)	==	bvec4(true)	||	eq(g0,g2)	==	bvec4(true)))	?	bvec4(true)	:	bvec4(false);
	interp_restriction_lv4_up  	=	(notEqual(e,c3)	==	bvec4(true)	&&	notEqual(b3,c3)	==	bvec4(true)	&&	(eq(b1,b3)	==	bvec4(true)	||	eq(c1,c3)	==	bvec4(true)))	?	bvec4(true)	:	bvec4(false);

	vec4	wd1	=	weighted_distance( e, c, g, i, h5, f4, h, f);
	vec4	wd2	=	weighted_distance( h, d, i5, f, i4, b, e, i);

	edr0	=	(lessThanEqual(wd1	,	wd2)	==	bvec4(true)	&&	interp_restriction_lv1	==	bvec4(true))	?	bvec4(true)	:	bvec4(false);
	edr	=	(lessThan(wd1 ,  wd2)	==	bvec4(true)	&&	interp_restriction_lv1	==	bvec4(true)	&&	( eq(f,b)	==	bvec4(false)	&&	id(f,c,f,b)	==	bvec4(false)	||	eq(h,d)	==	bvec4(false)	&&	id(h,g,h,d)	==	bvec4(false)	||	eq(e,g)	==	bvec4(true)	||	eq(e,c)	==	bvec4(true)))	?	bvec4(true)	:	bvec4(false);
	edr_left	=	(lessThanEqual((cf2*df(f,g))	,	df(h,c))	==	bvec4(true)	&&	interp_restriction_lv2_left	==	bvec4(true)	&&	edr	==	bvec4(true))	?	bvec4(true)	:	bvec4(false);
	edr_up	=	(greaterThanEqual(df(f,g)	,	(cf2*df(h,c)))	==	bvec4(true)	&&	interp_restriction_lv2_up	==	bvec4(true)	&&	edr	==	bvec4(true))	?	bvec4(true)	:	bvec4(false);
	edr3_left	=	(lessThanEqual((cf3*df(f,g0))	,	df(h,c1))	==	bvec4(true)	&&	interp_restriction_lv3_left	==	bvec4(true)	&&	edr_left	==	bvec4(true))	?	bvec4(true)	:	bvec4(false);
	edr3_up	=	(greaterThanEqual(df(f,g0)	,	(cf3*df(h,c1)))	==	bvec4(true)	&&	interp_restriction_lv3_up	==	bvec4(true)	&&	edr_up	==	bvec4(true))	?	bvec4(true)	:	bvec4(false);
	edr4_left	=	(lessThanEqual((cf4*df(f,g2))	,	df(h,c3))	==	bvec4(true)	&&	interp_restriction_lv4_left	==	bvec4(true)	&&	edr3_left	==	bvec4(true))	?	bvec4(true)	:	bvec4(false);
	edr4_up	=	(greaterThanEqual(df(f,g2)	,	(cf4*df(h,c3)))	==	bvec4(true)	&&	interp_restriction_lv4_up	==	bvec4(true)	&&	edr3_up	==	bvec4(true))	?	bvec4(true)	:	bvec4(false);

	vec4	info;
	info	=	(edr0	==	bvec4(true))	?	vec4(1.0)	:	vec4(0.0);
	info	=	(edr	==	bvec4(true))	?	vec4(2.0)	:	info;
	info	=	(edr_up	==	bvec4(true)	&&	edr_left	==	bvec4(false))	?	vec4(3.0)	:	info;
	info	=	(edr_left	==	bvec4(true)	&&	edr_up	==	bvec4(false))	?	vec4(4.0)	:	info;
	info	=	(edr3_up	==	bvec4(true)	&&	edr3_left	==	bvec4(false))	?	vec4(5.0)	:	info;
	info	=	(edr3_left	==	bvec4(true)	&&	edr3_up	==	bvec4(false))	?	vec4(6.0)	:	info;
	info	=	(edr4_up	==	bvec4(true)	&&	edr4_left	==	bvec4(false))	?	vec4(7.0)	:	info;
	info	=	(edr4_left	==	bvec4(true)	&&	edr4_up	==	bvec4(false))	?	vec4(8.0)	:	info;
//	info	=	(edr4_left	==	bvec4(true)	&&	edr4_up	==	bvec4(false))	?	vec4(8.0)	:	((edr4_up	==	bvec4(true)	&&	edr4_left	==	bvec4(false))	?	vec4(7.0)	:	((edr3_left	==	bvec4(true)	&&	edr3_up	==	bvec4(false))	?	vec4(6.0)	:	((edr3_up	==	bvec4(true)	&&	edr3_left	==	bvec4(false))	?	vec4(5.0)	:	((edr_left	==	bvec4(true)	&&	edr_up	==	bvec4(false))	?	vec4(4.0)	:	((edr_up	==	bvec4(true)	&&	edr_left	==	bvec4(false))	?	vec4(3.0)	:	(edr	==	bvec4(true)	?	vec4(2.0)	:	(edr0	==	bvec4(true)	?	vec4(1.0)	:	vec4(0.0))))))));

	FragColor	=	vec4(remapTo01(info, maximo));
}