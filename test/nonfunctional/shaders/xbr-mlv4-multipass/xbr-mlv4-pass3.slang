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

   Hyllian's xBR MultiLevel4 Shader - Pass3
   
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

const	float coef	=	2.0;
const	float cf	=	4.0;
const	float eq_threshold	=	15.0;
const	float y_weight	=	48.0;
const	float u_weight	=	7.0;
const	float v_weight	=	6.0;
const	mat3x3 yuv	=	mat3x3(0.299, 0.587, 0.114, -0.169, -0.331, 0.499, 0.499, -0.418, -0.0813);
const	mat3x3 yuv_weighted	=	mat3x3(y_weight*yuv[0], u_weight*yuv[1], v_weight*yuv[2]);
const	vec4 maximo	=	vec4(255.0f, 255.0f, 255.0f, 255.0f);
const	vec4 low	=	vec4(-64.0f, -64.0f, -64.0f, -64.0f);
const	vec4 high	=	vec4( 64.0f,  64.0f,  64.0f,  64.0f);

const	mat2x4 sym_vectors	=	mat2x4(1,  1,   -1, -1,    1, -1,   -1,  1);

// Bx, Ay, C
const vec3 lines[13] = {
	vec3( 4.0,  4.0, 4.0),  //  0  NL
	vec3( 4.0,  4.0, 3.0),  //  1  LV0
	vec3( 4.0,  4.0, 2.0),  //  2  LV1
	vec3( 8.0,  4.0, 2.0),  //  3  LV2u
	vec3( 4.0,  8.0, 2.0),  //  4  LV2l
	vec3(12.0,  4.0, 2.0),  //  5  LV3u
	vec3( 4.0, 12.0, 2.0),  //  6  LV3l
	vec3(16.0,  4.0, 2.0),  //  7  LV4u
	vec3( 4.0, 16.0, 2.0),  //  8  LV4l
	vec3(12.0,  4.0, 6.0),  //  9  LV3u
	vec3( 4.0, 12.0, 6.0),  // 10  LV3l
	vec3(16.0,  4.0, 6.0),  // 11  LV4u
	vec3( 4.0, 16.0, 6.0),  // 12  LV4l
};

vec4 remapTo01(vec4 v, vec4 low, vec4 high)
{
	return clamp((v - low)/(high-low), 0.0, 1.0);
}

float remapFrom01(float v, float high)
{
	return round(high*v);
}


float df(float A, float B)
{
	return abs(A-B);
}

bool eq(float A, float B)
{
	return (df(A, B) < eq_threshold);
}

float weighted_distance(float a, float b, float c, float d, float e, float f, float g, float h)
{
	return (df(a,b) + df(a,c) + df(d,e) + df(d,f) + 4.0*df(g,h));
}

#pragma stage vertex
layout(location = 0) in vec4 Position;
layout(location = 1) in vec2 TexCoord;
layout(location = 0) out vec2 vTexCoord;
layout(location = 1) out vec4 t1;

void main()
{
	gl_Position	=	global.MVP * Position;
	vTexCoord	=	TexCoord;
	float	dx	=	params.OriginalSize.z;
	float	dy	=	params.OriginalSize.w;
   
	//      A3 B3 C3
	//      A1 B1 C1
	//A2 A0  A  B  C C4 C6
	//D2 D0  D  E  F F4 F6
	//G2 G0  G  H  I I4 I6
	//      G5 H5 I5
	//      G7 H7 I7
	
	t1	=	vec4(dx, 0, 0, dy);  // F  H
}

#pragma stage fragment
layout(location = 0) in vec2 vTexCoord;
layout(location = 1) in vec4 t1;
layout(location = 0) out vec4 FragColor;
layout(set = 0, binding = 2) uniform sampler2D Source;
layout(set = 0, binding = 3) uniform sampler2D Original;

void main()
{
	float	px;

	vec2	pos	=	fract(vTexCoord.xy * params.OriginalSize.xy) - vec2(0.4999, 0.4999); // pos = pixel position
	vec2	dir	=	sign(pos); // dir = pixel direction

	vec2	g1	=	dir * ( clamp(-dir.y*dir.x, 0.0, 1.0) * t1.zw + clamp( dir.y*dir.x, 0.0, 1.0) * t1.xy);
	vec2	g2	=	dir * ( clamp( dir.y*dir.x, 0.0, 1.0) * t1.zw + clamp(-dir.y*dir.x, 0.0, 1.0) * t1.xy);

	vec3	E	=	texture(Original, vTexCoord    ).rgb;
	vec3	F	=	texture(Original, vTexCoord + g1).rgb;
	vec3	H	=	texture(Original, vTexCoord + g2).rgb;
	vec3	I	=	texture(Original, vTexCoord + g1 + g2).rgb;
	vec3	F4	=	texture(Original, vTexCoord + 2.0 * g1).rgb;
	vec3	H5	=	texture(Original, vTexCoord + 2.0 * g2).rgb;

	float	e	=	dot(E, yuv_weighted[0]);
	float	f	=	dot(F, yuv_weighted[0]);
	float	h	=	dot(H, yuv_weighted[0]);
	float	i	=	dot(I, yuv_weighted[0]);
	float	f4	=	dot(F4, yuv_weighted[0]);
	float	h5	=	dot(H5, yuv_weighted[0]);
	
	vec4	icomp	= round(clamp(sym_vectors * dir, 0.0, 1.0)); // choose info component

	float	infoE	= remapFrom01(dot(texture(Source, vTexCoord   ), icomp), 255.0f); // retrieve 1st pass info
	float	infoF	= remapFrom01(dot(texture(Source, vTexCoord+g1), icomp), 255.0f); // 1st pass info from neighbor r
	float	infoH	= remapFrom01(dot(texture(Source, vTexCoord+g2), icomp), 255.0f); // 1st pass info from neighbor d

	vec4 lparam;
	vec2 addr;
	
	if	(infoF == 8.0)
	{
		lparam.xyz = lines[12];
		px = ((df(f,f4) <= df(f,i)) == true) ? 1.0 : 0.0;
		addr.x = 2*px + clamp(1.0-px, 0.0, 1.0);
		addr.y = clamp(1.0-px, 0.0, 1.0);
	}
	else if	(infoH == 7.0)
	{
		lparam.xyz = lines[11];
		px = ((df(h,h5) <= df(h,i)) == true) ? 1.0 : 0.0;
		addr.x = clamp(1.0-px, 0.0, 1.0);
		addr.y = 2*px + clamp(1.0-px, 0.0, 1.0);
	}
	else if	(infoF == 6.0)
	{
		lparam.xyz = lines[10];
		px = ((df(f,f4) <= df(f,i)) == true) ? 1.0 : 0.0;
		addr.x = 2*px + clamp(1.0-px, 0.0, 1.0);
		addr.y = clamp(1.0-px, 0.0, 1.0);
	}
	else if	(infoH == 5.0)
	{
		lparam.xyz = lines[9];
		px = ((df(h,h5) <= df(h,i)) == true) ? 1.0 : 0.0;
		addr.x = clamp(1.0-px, 0.0, 1.0);
		addr.y = 2*px + clamp(1.0-px, 0.0, 1.0);
	}
	else
	{
		px = ((df(e,f) <= df(e,h)) == true) ? 1.0 : 0.0;
		addr.x = px;
		addr.y = clamp(1.0-px, 0.0, 1.0);

		lparam.xyz = (infoE == 8.0) ? lines[8] : ((infoE == 7.0) ? lines[7] : ((infoE == 6.0) ? lines[6] : ((infoE == 5.0) ? lines[5] : ((infoE == 4.0) ? lines[4] : ((infoE == 3.0) ? lines[3] : ((infoE == 2.0) ? lines[2] : ((infoE == 1.0) ? lines[1] : lines[0])))))));
	}
	
	bool	inv	=	(dir.x*dir.y) < 0.0 ? true : false;

	// Rotate address from relative to absolute.
	addr	=	addr*dir.yx;
	addr	=	inv ? addr.yx : addr;

	// Rotate straight line equation from relative to absolute.
	lparam.xy	=	lparam.xy*dir.yx;
	lparam.xy	=	inv ? lparam.yx : lparam.xy;

	addr.x	+=	2.0;
	addr.y	+=	2.0;

	lparam.w	=	addr.x*8.0 + addr.y;
	
   FragColor	=	vec4(remapTo01(lparam, low, high));
}

/*
19 1
9  1
4  0
2  0
1  1
0  0

0 0000   ND
1 0001   EDR0
2 0010   EDR
3 0011   EDRU
4 0100   EDRL
5 0101   EDRU3
6 0110   EDRL3

0   1 2 3 4
-2 -1 0 1 2

*/