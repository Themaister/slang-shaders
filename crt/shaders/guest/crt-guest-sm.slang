#version 450

/*
   CRT - Guest - SM (Scanline Mask) Shader
   
   Copyright (C) 2019 guest(r) - guest.r@gmail.com

   Big thanks to Nesguy from the Libretro forums for the masks and other ideas.
   
   This program is free software; you can redistribute it and/or
   modify it under the terms of the GNU General Public License
   as published by the Free Software Foundation; either version 2
   of the License, or (at your option) any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program; if not, write to the Free Software
   Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
   
*/

/*   README - MASKS GUIDE

To obtain the best results with masks 0, 1, 3, 4: 
must leave “mask size” at 1 and the display must be set to its native resolution to result in evenly spaced “active” LCD subpixels.

Mask 0: Uses a magenta and green pattern for even spacing of the LCD subpixels.

Mask 1: Intended for displays that have RBG subpixels (as opposed to the more common RGB). 
Uses a yellow/blue pattern for even spacing of the LCD subpixels.

Mask 2: Common red/green/blue pattern.

Mask 3: This is useful for 4K displays, where masks 0 and 1 can look too fine. 
Uses a red/yellow/cyan/blue pattern to result in even spacing of the LCD subpixels.

Mask 4: Intended for displays that have the less common RBG subpixel pattern. 
This is useful for 4K displays, where masks 0 and 1 can look too fine. 
Uses a red/magenta/cyan/green pattern for even spacing of the LCD subpixels.

*/

layout(push_constant) uniform Push
{
	vec4 SourceSize;
	vec4 OriginalSize;
	vec4 OutputSize;
	uint FrameCount;
	float smart, brightboost1, brightboost2, stype, scanline1, scanline2, beam_min, beam_max, s_beam, saturation1, h_sharp, mask, maskmode, maskdark, maskbright, masksize, gamma_out;
} params;

// smart Y integer scaline
#pragma parameter smart "Smart Y Integer Scaling" 0.0 0.0 1.0 1.0
// adjust brightness dark colors
#pragma parameter brightboost1 "Bright boost dark colors" 1.50 0.5 3.0 0.05
// adjust brightness bright colors
#pragma parameter brightboost2 "Bright boost bright colors" 1.10 0.5 2.0 0.05
// scanline type
#pragma parameter stype "Scanline Type" 0.0 0.0 2.0 1.0
// scanline param, vertical sharpness
#pragma parameter scanline1 "Scanline Shape Center" 8.0 2.0 14.0 0.5
// scanline param, vertical sharpness
#pragma parameter scanline2 "Scanline Shape Edges" 8.0 4.0 16.0 0.5
// dark area beam min - narrow
#pragma parameter beam_min "Scanline dark" 1.40 0.5 2.0 0.05
// bright area beam max -wide
#pragma parameter beam_max "Scanline bright" 1.10 0.5 2.0 0.05
// Overgrown Bright Beam
#pragma parameter s_beam "Overgrown Bright Beam" 0.75 0.0 1.0 0.05
// Scanline Saturation
#pragma parameter saturation1 "Scanline Saturation" 2.75 0.0 6.0 0.25
// pixel sharpness
#pragma parameter h_sharp "Horizontal sharpness" 2.0 1.0 5.0 0.05
// crt mask
#pragma parameter mask "CRT Mask (3&4 are 4k masks)" 0.0 0.0 4.0 1.0
// CRT Mask Mode: Classic, Fine, Coarse
#pragma parameter maskmode "CRT Mask Mode: Classic, Fine, Coarse" 0.0 0.0 2.0 1.0
// CRT Mask Strength Dark Pixels
#pragma parameter maskdark "CRT Mask Strength Dark Pixels" 1.0 0.0 1.5 0.05
// CRT Mask Strength Bright Pixels
#pragma parameter maskbright "CRT Mask Strength Bright Pixels" 0.20 -0.5 1.0 0.05
// crt mask size
#pragma parameter masksize "CRT Mask Size" 1.0 1.0 2.0 1.0
// gamma out
#pragma parameter gamma_out "Gamma Out" 2.40 1.0 3.0 0.05

#define smart params.smart
#define brightboost1 params.brightboost1
#define brightboost2 params.brightboost2
#define stype params.stype
#define scanline1 params.scanline1
#define scanline2 params.scanline2
#define beam_min params.beam_min
#define beam_max params.beam_max
#define s_beam params.s_beam
#define saturation1 params.saturation1
#define h_sharp params.h_sharp
#define mask params.mask
#define maskmode params.maskmode
#define maskdark params.maskdark
#define maskbright params.maskbright
#define masksize params.masksize
#define gamma_out params.gamma_out

#define TEX0 vTexCoord
#define COMPAT_TEXTURE(c,d) texture(c,d)
#define Texture Source
#define InputSize SourceSize

layout(std140, set = 0, binding = 0) uniform UBO
{
	mat4 MVP;
} global;

#pragma stage vertex
layout(location = 0) in vec4 Position;
layout(location = 1) in vec2 TexCoord;
layout(location = 0) out vec2 vTexCoord;

void main()
{
   gl_Position = global.MVP * Position;
   vTexCoord = TexCoord;
}

#pragma stage fragment
layout(location = 0) in vec2 vTexCoord;
layout(location = 0) out vec4 FragColor;
layout(set = 0, binding = 2) uniform sampler2D Source;

float st(float x)
{
	return exp2(-10.0*x*x);
}  

float st1(float x, float scan)
{
	return exp2(-scan*x*x);
}  

float sw1(float x, vec3 color, float scan)
{	
	float mx = max(max(color.r,color.g),color.b);
	float ex = mix((2.75 - 1.75*stype)*beam_min, beam_max, mx);
	ex = mix(beam_max, ex, pow(x, mx + 0.25))*x;
	return exp2(-scan*ex*ex);
}

float sw2(float x, vec3 color)
{	
	float mx = max(max(color.r,color.g),color.b);
	float ex = mix(2.0*beam_min, beam_max, mx);
	float m = 0.5*ex;
	x = x*ex; float xx = x*x;
	xx = mix(xx, x*xx, m);
	return exp2(-10.0*xx);
}

float Overscan(float pos, float dy){
	pos=pos*2.0-1.0;    
	pos*=dy;
	return pos*0.5+0.5;
}

void main()
{
	vec2 tex = TEX0.xy * 1.000001;

	if (smart == 1.0)
	{
		float factor = params.OutputSize.y/params.InputSize.y;
		float intfactor = round(factor);
		float diff = factor/intfactor;
		tex.y = Overscan(tex.y*(params.SourceSize.y/params.InputSize.y), diff)*(params.InputSize.y/params.SourceSize.y); 
	}
	
	vec2 OGL2Pos = tex * params.SourceSize.xy - vec2(0.5);
	vec2 fp = fract(OGL2Pos);

	vec2 pC4 = (floor(OGL2Pos) + vec2(0.5)) * params.SourceSize.zw;	
	
	// Reading the texels
	vec3 ul = COMPAT_TEXTURE(Texture, pC4                         ).xyz; ul*=ul;
	vec3 ur = COMPAT_TEXTURE(Texture, pC4 + vec2(params.SourceSize.z,0.0)).xyz; ur*=ur;
	vec3 dl = COMPAT_TEXTURE(Texture, pC4 + vec2(0.0,params.SourceSize.w)).xyz; dl*=dl;
	vec3 dr = COMPAT_TEXTURE(Texture, pC4 + params.SourceSize.zw         ).xyz; dr*=dr;
	
	float lx = fp.x;        lx = pow(lx, h_sharp);
	float rx = 1.0 - fp.x;  rx = pow(rx, h_sharp);
	
	float w = 1.0/(lx+rx);
	float f1 = fp.y;
	float f2 = 1.0 - fp.y;
	float f3 = fract(tex.y * params.SourceSize.y); f3 = abs(f3-0.5);
	
	vec3 color;
	float t1 = st(f1);
	float t2 = st(f2);
	float wt = 1.0/(t1+t2);
	
// calculating scanlines

	vec3 cl = (ul*t1 + dl*t2)*wt;
	vec3 cr = (ur*t1 + dr*t2)*wt;	
	
	vec3 ref_ul = mix(cl, ul, s_beam);
	vec3 ref_ur = mix(cr, ur, s_beam);
	vec3 ref_dl = mix(cl, dl, s_beam);
	vec3 ref_dr = mix(cr, dr, s_beam);	
	
	float scan1 = mix(scanline1, scanline2, f1);
	float scan2 = mix(scanline1, scanline2, f2);
	float scan0 = mix(scanline1, scanline2, f3);
	f3 = st1(f3,scan0);
	f3 = f3*f3*(3.0-2.0*f3);
	
	float w1, w2, w3, w4 = 0.0;

	if (stype < 2.0)
	{
		w1 = sw1(f1, ref_ul, scan1);
		w2 = sw1(f2, ref_dl, scan2);
		w3 = sw1(f1, ref_ur, scan1);
		w4 = sw1(f2, ref_dr, scan2);
	}
	else
	{
		w1 = sw2(f1, ref_ul);
		w2 = sw2(f2, ref_dl);
		w3 = sw2(f1, ref_ur);
		w4 = sw2(f2, ref_dr);	
	}

	vec3 colorl = w1*ul + w2*dl;
	vec3 colorr = w3*ur + w4*dr;
	color = w*(colorr*lx + colorl*rx);
	color = min(color,1.0);	
	
	vec3 ctemp = w*(cr*lx + cl*rx);

	cl*=cl*cl; cl*=cl; cr*=cr*cr; cr*=cr;

	vec3 sctemp = w*(cr*lx + cl*rx); sctemp = pow(sctemp, vec3(1.0/6.0));

	float mx1 = max(max(color.r,color.g),color.b);
	float sp = (stype == 1.0) ? (0.5*saturation1) : saturation1;
	vec3 saturated_color = max((1.0+sp)*color - 0.5*sp*(color+mx1), 0.0);
	color = mix(saturated_color, color, f3);
	
	vec3 scan3 = vec3(0.0);
	float spos = floor((gl_FragCoord.x * 1.000001)/masksize); float spos1 = 0.0;

	vec3 tmp1 = 0.5*(sqrt(ctemp) + sctemp);
	
	color*=mix(brightboost1, brightboost2, max(max(ctemp.r,ctemp.g),ctemp.b));
	color = min(color,1.0);	
	
	float mboost = 1.25;
	
	if (mask == 0.0)
	{
		spos1 = fract(spos*0.5);
		if      (spos1 < 0.5)  scan3.rb = color.rb;
		else                   scan3.g  = color.g;	
	}
	else
	if (mask == 1.0)
	{
		spos1 = fract(spos*0.5);
		if      (spos1 < 0.5)  scan3.rg = color.rg;
		else                   scan3.b  = color.b;
	}
	else
	if (mask == 2.0)
	{
		mboost = 1.0;
		spos1 = fract(spos/3.0);
		if      (spos1 < 0.333)  scan3.r = color.r;
		else if (spos1 < 0.666)  scan3.g = color.g;
		else                     scan3.b = color.b;
	}
	else
	if (mask == 3.0)
	{
		spos1 = fract(spos*0.25);
		if      (spos1 < 0.25)  scan3.r = color.r;
		else if (spos1 < 0.50)  scan3.rg = color.rg;
		else if (spos1 < 0.75)  scan3.gb = color.gb;	
		else                    scan3.b  = color.b;	
	}
	else	
	{
		spos1 = fract(spos*0.25);
		if      (spos1 < 0.25)  scan3.r = color.r;
		else if (spos1 < 0.50)  scan3.rb = color.rb;
		else if (spos1 < 0.75)  scan3.gb = color.gb;
		else                    scan3.g =  color.g; 
	}
	
	vec3 lerpmask = tmp1;
	if (maskmode == 1.0) lerpmask = vec3(max(max(tmp1.r,tmp1.g),tmp1.b)); else
	if (maskmode == 2.0) lerpmask = color;
	
	color = max(mix( mix(color, mboost*scan3, maskdark), mix(color, scan3, maskbright), lerpmask), 0.0);
	
	vec3 color1 = pow(color, vec3(1.0/2.1));

	if (stype != 1.0)
	{
		vec3 color2 = pow(color, vec3(1.0/gamma_out));			
		mx1 = max(max(color1.r,color1.g),color1.b) + 1e-12;	
		float mx2 = max(max(color2.r,color2.g),color2.b);
		color1*=mx2/mx1;		
	}
	
    FragColor = vec4(color1, 1.0);
}
