#version 450

/*
   CRT - Guest - Dr. Venom
   
   Copyright (C) 2018-2019 guest(r) - guest.r@gmail.com
   
   Incorporates many good ideas and suggestions from Dr. Venom.

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

layout(push_constant) uniform Push
{
	vec4 SourceSize;
	vec4 OutputSize;
   float TATE;        // Screen orientation
   float IOS;         // Smart Integer Scaling
	float OS;          // Do overscan
	float BLOOM;       // Bloom overscan percentage
	float brightboost; // adjust brightness
	float saturation;  // 1.0 is normal saturation
   float gsl;         // Alternate scanlines
	float scanline;    // scanline param, vertical sharpness
	float beam_min;    // dark area beam min - wide
	float beam_max;    // bright area beam max - narrow
	float h_sharp;     // pixel sharpness
	float s_sharp;     // substractive sharpness
	float csize;       // corner size
	float warpX;       // Curvature X
	float warpY;       // Curvature Y
	float glow;        // Glow Strength
	float shadowMask;  // Mask Style
	float maskDark;    // Dark "Phosphor"
	float maskLight;   // Light "Phosphor"
	float CGWG;        // CGWG Mask Strength
	float GTW;         // Gamma tweak
   float gamma_out;   // output gamma
} params;

#pragma parameter TATE "TATE Mode" 0.0 0.0 1.0 1.0
#define TATE params.TATE
#pragma parameter IOS "Smart Integer Scaling" 0.0 0.0 1.0 1.0
#define IOS params.IOS
#pragma parameter OS "R. Bloom Overscan Mode" 2.0 0.0 2.0 1.0
#define OS params.OS
#pragma parameter BLOOM "Raster bloom %" 0.0 0.0 20.0 1.0
#define BLOOM params.BLOOM
#pragma parameter brightboost "Bright boost" 1.10 0.50 2.00 0.01
#define brightboost params.brightboost
#pragma parameter saturation "Saturation adjustment" 1.0 0.1 2.0 0.05
#define saturation params.saturation
#pragma parameter gsl "Alternate scanlines" 0.0 0.0 1.0 1.0
#define gsl params.gsl
#pragma parameter scanline "Scanline adjust" 8.0 1.0 12.0 1.0
#define scanline params.scanline
#pragma parameter beam_min "Scanline dark" 1.30 0.5 2.0 0.05
#define beam_min params.beam_min
#pragma parameter beam_max "Scanline bright" 1.0 0.5 2.0 0.05
#define beam_max params.beam_max
#pragma parameter h_sharp "Horizontal sharpness" 5.0 1.5 20.0 0.25
#define h_sharp params.h_sharp
#pragma parameter s_sharp "Substractive sharpness" 0.0 0.0 0.20 0.01
#define s_sharp params.s_sharp
#pragma parameter csize "Corner size" 0.0 0.0 0.05 0.01
#define csize params.csize
#pragma parameter warpX "CurvatureX (default 0.03)" 0.0 0.0 0.125 0.01
#define warpX params.warpX
#pragma parameter warpY "CurvatureY (default 0.04)" 0.0 0.0 0.125 0.01
#define warpY params.warpY
#pragma parameter glow "Glow Strength" 0.04 0.0 0.5 0.01
#define glow params.glow
#pragma parameter shadowMask "Mask Style (0 = CGWG)" 0.0 -1.0 5.0 1.0
#define shadowMask params.shadowMask
#pragma parameter maskDark "Lottes maskDark" 0.5 0.0 2.0 0.1
#define maskDark params.maskDark
#pragma parameter maskLight "Lottes maskLight" 1.5 0.0 2.0 0.1
#define maskLight params.maskLight
#pragma parameter CGWG "CGWG Mask Str." 0.4 0.0 1.0 0.05
#define CGWG params.CGWG
#pragma parameter GTW "Gamma Tweak" 1.10 0.5 1.5 0.01
#define GTW params.GTW
#pragma parameter gamma_out "Gamma out" 2.4 1.0 3.0 0.05
#define gamma_out params.gamma_out

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
   vTexCoord = TexCoord * 1.0001;
}

#pragma stage fragment
layout(location = 0) in vec2 vTexCoord;
layout(location = 0) out vec4 FragColor;
layout(set = 0, binding = 2) uniform sampler2D Source;
layout(set = 0, binding = 3) uniform sampler2D lum_pass;
layout(set = 0, binding = 4) uniform sampler2D linearize_pass;

#define eps 1e-10

float b_min = 1.0 + 7.0*(beam_min - 0.5)*0.666666666;
float b_max = 1.0 + 7.0*(beam_max - 0.5)*0.666666666;
float scn_s = 0.3 + 0.7*(scanline - 1.0)*0.090909090;

vec3 sw(float x, vec3 color)
{
	vec3 tmp = mix(vec3(beam_min),vec3(beam_max), color);
	vec3 ex = vec3(x)*tmp;
	return exp2(-scanline*ex*ex);
}

vec3 sw2(float x, vec3 c)
{
	vec3 s = mix(vec3(b_min), vec3(b_max), c);
	return clamp(smoothstep(vec3(0.0), vec3(scn_s), pow(vec3(x),s)), 0.0001, 1.0);
}

// Shadow mask (mostly from PD Lottes shader).
vec3 Mask(vec2 pos)
{
	vec3 mask = vec3(maskDark, maskDark, maskDark);
	float mf = floor(mod(pos.x,2.0));
	float mf2 = floor(mod(pos.x + pos.y,2.0));   
	float mc = 1.0 - CGWG;   
	float mc2 = mc * 0.7;
   
	// No mask
	if (shadowMask == -1.0)
	{
		mask = vec3(1.0);
	}       

	// Light mask.
	else if (shadowMask == 5.0)
	{
		if (mf2 == 0.0) { mask = vec3(1.0); }
		else { mask = vec3(mc2); }
	}    
   
	// Phosphor.
	else if (shadowMask == 0.0)
	{
		if (mf == 0.0) { mask.r = 1.0; mask.g = mc; mask.b = 1.0; }
		else { mask.r = mc; mask.g = 1.0; mask.b = mc; }
	}    
   
	// Very compressed TV style shadow mask.
	else if (shadowMask == 1.0)
	{
		float line = maskLight;
		float odd  = 0.0;

		if (fract(pos.x/6.0) < 0.5)
			odd = 1.0;
		if (fract((pos.y + odd)/2.0) < 0.5)
			line = maskDark;

		pos.x = fract(pos.x/3.0);
    
		if      (pos.x < 0.333) mask.r = maskLight;
		else if (pos.x < 0.666) mask.g = maskLight;
		else                    mask.b = maskLight;
		mask*=line;  
	} 

	// Aperture-grille.
	else if (shadowMask == 2.0)
	{
		pos.x = fract(pos.x/3.0);

		if      (pos.x < 0.333) mask.r = maskLight;
		else if (pos.x < 0.666) mask.g = maskLight;
		else                    mask.b = maskLight;
	} 

	// Stretched VGA style shadow mask (same as prior shaders).
	else if (shadowMask == 3.0)
	{
		pos.x += pos.y*3.0;
		pos.x  = fract(pos.x/6.0);

		if      (pos.x < 0.333) mask.r = maskLight;
		else if (pos.x < 0.666) mask.g = maskLight;
		else                    mask.b = maskLight;
	}

	// VGA style shadow mask.
	else if (shadowMask == 4.0)
	{
		pos.xy = floor(pos.xy*vec2(1.0, 0.5));
		pos.x += pos.y*3.0;
		pos.x  = fract(pos.x/6.0);

		if      (pos.x < 0.333) mask.r = maskLight;
		else if (pos.x < 0.666) mask.g = maskLight;
		else                    mask.b = maskLight;
	}

	return mask;
}

// Distortion of scanlines, and end of screen alpha (PD Lottes Curvature)
vec2 Warp(vec2 pos)
{
	pos  = pos*2.0-1.0;    
	pos *= vec2(1.0 + (pos.y*pos.y)*warpX, 1.0 + (pos.x*pos.x)*warpY);
	return pos*0.5 + 0.5;
} 

vec2 Overscan(vec2 pos, float dx, float dy){
	pos=pos*2.0-1.0;    
	pos*=vec2(dx,dy);
	return pos*0.5+0.5;
} 

float Overscan2(float pos, float dy){
	pos=pos*2.0-1.0;    
	pos*=dy;
	return pos*0.5+0.5;
} 

// Borrowed from cgwg's crt-geom, under GPL

float corner(vec2 coord)
{
	coord = (coord - vec2(0.5)) * 1.0 + vec2(0.5);
	coord = min(coord, vec2(1.0)-coord) * vec2(1.0, params.OutputSize.y*params.OutputSize.z);
	vec2 cdist = vec2(max(csize,0.002));
	coord = (cdist - min(coord,cdist));
	float dist = sqrt(dot(coord,coord));
	return clamp((cdist.x-dist)*700.0,0.0, 1.0);
}  

const float sqrt3     = 1.732050807568877;

vec3 gamma_correct(vec3 color, vec3 tmp)
{
	return color*mix(GTW, 1.0, max(max(tmp.r,tmp.g),tmp.b));
}

void main()
{
	vec3 lum = texture(lum_pass, vec2(0.33,0.33)).xyz;

	// Calculating texel coordinates
   
	vec2 texcoord = vTexCoord.xy;
	if (IOS == 1.0){
		vec2 ofactor = params.OutputSize.xy*params.SourceSize.zw;
		vec2 intfactor = round(ofactor);
		vec2 diff = ofactor/intfactor;
		vec2 smartcoord;
		smartcoord.x = Overscan2(vTexCoord.x, diff.x);
		smartcoord.y = Overscan2(vTexCoord.y, diff.y);
		texcoord = (TATE > 0.5) ? vec2(smartcoord.x, texcoord.y) :
			vec2(texcoord.x, smartcoord.y);
	}
   
	float factor  = 1.00 + (1.0-0.5*OS)*BLOOM/100.0 - lum.x*BLOOM/100.0;
	texcoord  = Overscan(texcoord, factor, factor);
	vec2 pos  = Warp(texcoord);
	vec2 pos0 = Warp(vTexCoord.xy);
   
	vec2 ps = params.SourceSize.zw;
	vec2 OGL2Pos = pos * params.SourceSize.xy - ((TATE < 0.5) ?
		vec2(0.0,0.5) : vec2(0.5, 0.0));
	vec2 fp = fract(OGL2Pos);
	vec2 dx = vec2(ps.x,0.0);
	vec2 dy = vec2(0.0, ps.y);

	vec2 pC4 = floor(OGL2Pos) * ps + 0.5*ps;  
   
	// Reading the texels
	vec2 x2 = 2.0*dx;
	vec2 y2 = 2.0*dy;

	vec2 offx = dx;
	vec2 off2 = x2;
	vec2 offy = dy;
	float fpx = fp.x;
	if(TATE > 0.5)
	{
		offx = dy;
		off2 = y2;
		offy = dx;
		fpx = fp.y;
	}
   
	bool sharp = (s_sharp > 0.0);
   
	float wl2 = 1.5 + fpx; wl2*=wl2; wl2 = exp2(-h_sharp*wl2); wl2 = max(wl2 - s_sharp, -wl2);
	float wl1 = 0.5 + fpx; wl1*=wl1; wl1 = exp2(-h_sharp*wl1); wl1 = max(wl1 - s_sharp, -0.4*s_sharp);
	float wct = 0.5 - fpx; wct*=wct; wct = exp2(-h_sharp*wct); wct = max(wct - s_sharp,  s_sharp);
	float wr1 = 1.5 - fpx; wr1*=wr1; wr1 = exp2(-h_sharp*wr1); wr1 = max(wr1 - s_sharp, -0.4*s_sharp);
	float wr2 = 2.5 - fpx; wr2*=wr2; wr2 = exp2(-h_sharp*wr2); wr2 = max(wr2 - s_sharp, -wr2);

	float wt = 1.0/(wl2+wl1+wct+wr1+wr2);
   
	vec3 l2 = texture(linearize_pass, pC4 -off2).xyz;
	vec3 l1 = texture(linearize_pass, pC4 -offx).xyz;
	vec3 ct = texture(linearize_pass, pC4    ).xyz;
	vec3 r1 = texture(linearize_pass, pC4 +offx).xyz;
	vec3 r2 = texture(linearize_pass, pC4 +off2).xyz;

	vec3 color1 = (l2*wl2 + l1*wl1 + ct*wct + r1*wr1 + r2*wr2)*wt;
	if (sharp) color1 = clamp(color1, min(min(l1,r1),ct), max(max(l1,r1),ct)); 
   
	l2 = texture(linearize_pass, pC4 -off2 +offy).xyz;
	l1 = texture(linearize_pass, pC4 -offx +offy).xyz;
	ct = texture(linearize_pass, pC4       +offy).xyz; 
	r1 = texture(linearize_pass, pC4 +offx +offy).xyz;
	r2 = texture(linearize_pass, pC4 +off2 +offy).xyz;

	vec3 color2 = (l2*wl2 + l1*wl1 + ct*wct + r1*wr1 + r2*wr2)*wt;
	if (sharp) color2 = clamp(color2, min(min(l1,r1),ct), max(max(l1,r1),ct)); 
   
	// calculating scanlines
   
	float f = (TATE < 0.5) ? fp.y : fp.x;
   
	vec3 w1 = sw(f,color1);
	vec3 w2 = sw(1.0-f,color2); 
   
	if (gsl == 1.0) { w1 = sw2(1.0-f,color1); w2 = sw2(f,color2);}
   
	vec3 color = color1*w1 + color2*w2;
	vec3 ctmp  = color/(w1+w2);
   
	color = pow(color, vec3(1.0/gamma_out));
	float l = length(color);
	color = normalize(pow(color + vec3(eps), vec3(saturation,saturation,saturation)))*l;   
	color*=brightboost;  
	color = gamma_correct(color,ctmp);
	color = pow(color, vec3(gamma_out));
	color = min(color, 1.0);   
   
	// Apply Mask

	color *= (TATE < 0.5) ? Mask(gl_FragCoord.xy * 1.000001) :
		Mask(gl_FragCoord.yx * 1.000001);
   
	vec3 Bloom = texture(Source, pos).xyz;
   
	color+=glow*Bloom;
	color = min(color, 1.0);
   
	color = pow(color, vec3(1.0/gamma_out));
   FragColor = vec4(color*corner(pos0), 1.0);
}