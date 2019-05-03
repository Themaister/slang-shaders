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
	float TATE, IOS, OS, BLOOM, brightboost, gsl, scanline1, scanline2, beam_min, beam_max, beam_size,
      h_sharp, s_sharp, h_smart, csize, bsize, warpX, warpY, glow, shadowMask, masksize, vertmask,
      slotmask, slotwidth, double_slot, mcut, maskDark, maskLight, CGWG, GTW, gamma_out;
} params;

#pragma parameter TATE "TATE Mode" 0.0 0.0 1.0 1.0
#define TATE         params.TATE     // Screen orientation
#pragma parameter IOS "Smart Integer Scaling: 1.0:Y, 2.0:'X'+Y" 0.0 0.0 2.0 1.0
#define IOS          params.IOS     // Smart Integer Scaling
#pragma parameter OS "R. Bloom Overscan Mode" 1.0 0.0 2.0 1.0
#define OS           params.OS     // Do overscan
#pragma parameter BLOOM "Raster bloom %" 0.0 0.0 20.0 1.0
#define BLOOM        params.BLOOM     // Bloom overscan percentage
#pragma parameter brightboost "Bright boost" 1.35 0.50 2.00 0.01
#define brightboost  params.brightboost     // adjust brightness
#pragma parameter gsl "Scanline Type" 0.0 0.0 2.0 1.0
#define gsl          params.gsl      // Alternate scanlines
#pragma parameter scanline1 "Scanline beam shape low" 8.0 1.0 15.0 1.0
#define scanline1    params.scanline1      // scanline param, vertical sharpness
#pragma parameter scanline2 "Scanline beam shape high" 8.0 5.0 23.0 1.0 
#define scanline2    params.scanline2      // scanline param, vertical sharpness
#pragma parameter beam_min "Scanline dark" 1.35 0.5 2.0 0.05
#define beam_min     params.beam_min     // dark area beam min - narrow
#pragma parameter beam_max "Scanline bright" 1.05 0.5 2.0 0.05
#define beam_max     params.beam_max     // bright area beam max - wide
#pragma parameter beam_size "Increased bright scanline beam" 0.65 0.0 1.0 0.05
#define beam_size    params.beam_size     // increased max. beam size
#pragma parameter h_sharp "Horizontal sharpness" 5.25 1.5 20.0 0.25
#define h_sharp      params.h_sharp     // pixel sharpness
#pragma parameter s_sharp "Substractive sharpness" 0.05 0.0 0.20 0.01
#define s_sharp      params.s_sharp     // substractive sharpness
#pragma parameter h_smart "Smart Horizontal Smoothing" 0.0 0.0 1.0 0.1
#define h_smart      params.h_smart     // smart horizontal smoothing
#pragma parameter csize "Corner size" 0.0 0.0 0.07 0.01
#define csize        params.csize     // corner size
#pragma parameter bsize "Border smoothness" 600.0 100.0 600.0 25.0
#define bsize        params.bsize     // border smoothness
#pragma parameter warpX "CurvatureX (default 0.03)" 0.0 0.0 0.125 0.01
#define warpX        params.warpX     // Curvature X
#pragma parameter warpY "CurvatureY (default 0.04)" 0.0 0.0 0.125 0.01
#define warpY        params.warpY     // Curvature Y
#pragma parameter glow "Glow Strength" 0.02 0.0 0.5 0.01
#define glow         params.glow     // Glow Strength
#pragma parameter shadowMask "CRT Mask: 0:CGWG, 1-4:Lottes, 5-6:'Trinitron'" 0.0 -1.0 7.0 1.0
#define shadowMask   params.shadowMask     // Mask Style
#pragma parameter masksize "CRT Mask Size (2.0 is nice in 4k)" 1.0 1.0 2.0 1.0
#define masksize     params.masksize     // Mask Size
#pragma parameter vertmask "PVM Like Colors" 0.0 0.0 0.25 0.01
#define vertmask     params.vertmask     // Vertical mask
#pragma parameter slotmask "Slot Mask Strength" 0.0 0.0 1.0 0.05
#define slotmask     params.slotmask     // Slot Mask ON/OFF
#pragma parameter slotwidth "Slot Mask Width" 2.0 2.0 6.0 0.5
#define slotwidth    params.slotwidth     // Slot Mask Width
#pragma parameter double_slot "Slot Mask Height: 2x1 or 4x1" 1.0 1.0 2.0 1.0
#define double_slot  params.double_slot     // Slot Mask Height
#pragma parameter mcut "Mask 5&6 cutoff" 0.2 0.0 0.5 0.05
#define mcut         params.mcut     // Mask 5&6 cutoff
#pragma parameter maskDark "Lottes maskDark" 0.5 0.0 2.0 0.05
#define maskDark     params.maskDark     // Dark "Phosphor"
#pragma parameter maskLight "Lottes maskLight" 1.5 0.0 2.0 0.05
#define maskLight    params.maskLight     // Light "Phosphor"
#pragma parameter CGWG "CGWG Mask Str." 0.3 0.0 1.0 0.05
#define CGWG         params.CGWG     // CGWG Mask Strength
#pragma parameter GTW "Gamma Tweak" 1.05 0.5 1.5 0.01
#define GTW          params.GTW     // Gamma tweak
#pragma parameter gamma_out "Gamma out" 2.4 1.0 3.5 0.05
#define gamma_out    params.gamma_out     // output gamma

#define COMPAT_TEXTURE(c,d) texture(c,d)
#define TEX0 vTexCoord
#define InputSize SourceSize
#define TextureSize SourceSize

layout(std140, set = 0, binding = 0) uniform UBO
{
	mat4 MVP;
   vec4 SourceSize;
	vec4 OriginalSize;
	vec4 OutputSize;
	uint FrameCount;
} global;

#define SourceSize global.SourceSize
#define OutputSize global.OutputSize
#define gl_FragCoord (vTexCoord * OutputSize.xy)

#pragma stage vertex
layout(location = 0) in vec4 Position;
layout(location = 1) in vec2 TexCoord;
layout(location = 0) out vec2 vTexCoord;

void main()
{
   gl_Position = global.MVP * Position;
   vTexCoord = TexCoord * 1.00001;
}

#pragma stage fragment
layout(location = 0) in vec2 vTexCoord;
layout(location = 0) out vec4 FragColor;
layout(set = 0, binding = 2) uniform sampler2D Source;
layout(set = 0, binding = 3) uniform sampler2D LinearizePass;
layout(set = 0, binding = 4) uniform sampler2D AvgLumPass;

#define Texture Source
#define PassPrev3Texture LinearizePass
#define PassPrev4Texture AvgLumPass

#define eps 1e-10

float st(float x, float scanline)
{
	return exp2(-scanline*x*x);
} 
   
vec3 sw0(vec3 x, vec3 color, float scanline)
{
	vec3 tmp = mix(vec3(beam_min),vec3(beam_max), color);
	vec3 ex = x*tmp;
	return exp2(-scanline*ex*ex);
} 

vec3 sw1(vec3 x, vec3 color, float scanline)
{	
	float mx = max(max(color.r, color.g),color.b);
	x = mix (x, beam_min*x, max(x-0.4*mx,0.0));
	vec3 tmp = mix(vec3(1.2*beam_min),vec3(beam_max), color);
	vec3 ex = x*tmp;
	float br = clamp(0.8*beam_min - 1.0, 0.2, 0.45);
	return exp2(-scanline*ex*ex)/(1.0-br+br*color);
}    

vec3 sw2(vec3 x, vec3 color, float scanline)
{
	vec3 tmp = mix(vec3(2.75*beam_min),vec3(beam_max), color);
	tmp = mix(vec3(beam_max), tmp, pow(x, vec3(max(max(color.r, color.g),color.b)+0.3)));
	vec3 ex = x*tmp;
	return exp2(-scanline*ex*ex)/(0.6 + 0.4*color);
}

// Shadow mask (1-4 from PD CRT Lottes shader).
vec3 Mask(vec2 pos, vec3 c)
{
	pos = floor(pos/masksize);
	vec3 mask = vec3(maskDark, maskDark, maskDark);
	
	// No mask
	if (shadowMask == -1.0)
	{
		mask = vec3(1.0);
	}       
	
	// Phosphor.
	else if (shadowMask == 0.0)
	{
		pos.x = fract(pos.x*0.5);
		float mc = 1.0 - CGWG;
		if (pos.x < 0.5) { mask.r = 1.1; mask.g = mc; mask.b = 1.1; }
		else { mask.r = mc; mask.g = 1.1; mask.b = mc; }
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
	
	// Alternate mask 5
	else if (shadowMask == 5.0)
	{
		float mx = max(max(c.r,c.g),c.b);
		vec3 maskTmp = vec3( min( 1.25*max(mx-mcut,0.0)/(1.0-mcut) ,maskDark + 0.2*(1.0-maskDark)*mx));
		float adj = 0.80*maskLight - 0.5*(0.80*maskLight - 1.0)*mx + 0.75*(1.0-mx);	
		mask = maskTmp;
		pos.x = fract(pos.x/2.0);
		if  (pos.x < 0.5)
		{	mask.r  = adj;
			mask.b  = adj;
		}
		else     mask.g = adj;
	}    

	// Alternate mask 6
	else if (shadowMask == 6.0)
	{
		float mx = max(max(c.r,c.g),c.b);
		vec3 maskTmp = vec3( min( 1.33*max(mx-mcut,0.0)/(1.0-mcut) ,maskDark + 0.225*(1.0-maskDark)*mx));
		float adj = 0.80*maskLight - 0.5*(0.80*maskLight - 1.0)*mx + 0.75*(1.0-mx);
		mask = maskTmp;
		pos.x = fract(pos.x/3.0);
		if      (pos.x < 0.333) mask.r = adj;
		else if (pos.x < 0.666) mask.g = adj;
		else                    mask.b = adj; 
	}
	
	// Alternate mask 7
	else if (shadowMask == 7.0)
	{
		float mx = max(max(c.r,c.g),c.b);
		float maskTmp = min(1.6*max(mx-mcut,0.0)/(1.0-mcut) ,1.0 + 0.6*(1.0-mx));
		mask = vec3(maskTmp);
		pos.x = fract(pos.x/2.0);
		if  (pos.x < 0.5) mask = vec3(1.0 + 0.6*(1.0-mx));
	}    
	
	return mask;
} 

float SlotMask(vec2 pos, vec3 c)
{
	if (slotmask == 0.0) return 1.0;
	
	float mx = pow(max(max(c.r,c.g),c.b),1.33);
	float mlen = slotwidth*2.0;
	float px = fract(pos.x/mlen);
	float py = floor(fract(pos.y/(2.0*double_slot))*2.0*double_slot);
	float slot_dark = mix(1.0-slotmask, 1.0-0.80*slotmask, mx);
	float slot = 1.0 + 0.7*slotmask*(1.0-mx);
	if (py == 0.0 && px <  0.5) slot = slot_dark; else
	if (py == double_slot && px >= 0.5) slot = slot_dark;		
	
	return slot;
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


// Borrowed from cgwg's crt-geom, under GPL

float corner(vec2 coord)
{
	coord *= SourceSize.xy / InputSize.xy;
	coord = (coord - vec2(0.5)) * 1.0 + vec2(0.5);
	coord = min(coord, vec2(1.0)-coord) * vec2(1.0, OutputSize.y/OutputSize.x);
	vec2 cdist = vec2(max(csize, max((1.0-smoothstep(100.0,600.0,bsize))*0.01,0.002)));
	coord = (cdist - min(coord,cdist));
	float dist = sqrt(dot(coord,coord));
	return clamp((cdist.x-dist)*bsize,0.0, 1.0);
}

vec3 gamma_correct(vec3 color, vec3 tmp)
{
	return color*mix(GTW, 1.0, max(max(tmp.r,tmp.g),tmp.b));
}

void main()
{
	float lum = COMPAT_TEXTURE(PassPrev4Texture, vec2(0.33,0.33)).a;

	// Calculating texel coordinates
   
	vec2 texcoord = TEX0.xy;
	if (IOS > 0.0){
		vec2 ofactor = OutputSize.xy/InputSize.xy;
		vec2 intfactor = round(ofactor);
		vec2 diff = ofactor/intfactor;
		float scan = mix(diff.y, diff.x, TATE);
		texcoord = Overscan(texcoord*(SourceSize.xy/InputSize.xy), scan, scan)*(InputSize.xy/SourceSize.xy);
		if (IOS == 1.0) texcoord = mix(vec2(TEX0.x, texcoord.y), vec2(texcoord.x, TEX0.y), TATE);
	}
   
	float factor  = 1.00 + (1.0-0.5*OS)*BLOOM/100.0 - lum*BLOOM/100.0;
	texcoord  = Overscan(texcoord*(SourceSize.xy/InputSize.xy), factor, factor)*(InputSize.xy/SourceSize.xy);
	vec2 pos  = Warp(texcoord*(TextureSize.xy/InputSize.xy))*(InputSize.xy/TextureSize.xy);
	vec2 pos0 = Warp(TEX0.xy*(TextureSize.xy/InputSize.xy))*(InputSize.xy/TextureSize.xy);
   
	vec2 ps = SourceSize.zw;
	vec2 OGL2Pos = pos * SourceSize.xy - ((TATE < 0.5) ?
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


	float hsharp_tl, hsharp_tr, hsharp_bl, hsharp_br, hsharp_tc, hsharp_bc;
	
	if (h_smart == 0.0)
	{
		hsharp_tl = h_sharp; hsharp_tr = h_sharp; hsharp_bl = h_sharp; hsharp_br = h_sharp; hsharp_tc = h_sharp; hsharp_bc = h_sharp;
	}
	else
	{	
		// reading differences for smoothing
		vec3 diffs_top = COMPAT_TEXTURE(PassPrev4Texture, pC4       ).xyz;
		vec3 diffs_bot = COMPAT_TEXTURE(PassPrev4Texture, pC4 + offy).xyz;
		
		if(TATE > 0.5) 
		{ 	
			diffs_top.x = floor(10.0*diffs_top.z)*0.11111; diffs_top.y = fract(10.0*diffs_top.z)*1.11111; 
			diffs_bot.x = floor(10.0*diffs_bot.z)*0.11111; diffs_bot.y = fract(10.0*diffs_bot.z)*1.11111; 		
		}
		
		float ls = mix (4.5, 2.25, h_smart);
		hsharp_tl = mix(h_sharp, ls, diffs_top.x);
		hsharp_tr = mix(h_sharp, ls, diffs_top.y);
		hsharp_bl = mix(h_sharp, ls, diffs_bot.x);
		hsharp_br = mix(h_sharp, ls, diffs_bot.y);	
		hsharp_tc = hsharp_tl;
		hsharp_bc = hsharp_bl;
		if (fpx == 0.5) { hsharp_tc = 0.5*(hsharp_tl + hsharp_tr); hsharp_bc = 0.5*(hsharp_bl + hsharp_br); }
		if (fpx >  0.5) { hsharp_tc = hsharp_tr; hsharp_bc = hsharp_bl; }
	}
	
	float wl2 = 1.5 + fpx; wl2*=wl2; float twl2 = exp2(-hsharp_tl*wl2); twl2 = max(twl2 - s_sharp, -twl2);        float bwl2 = exp2(-hsharp_bl*wl2); bwl2 = max(bwl2 - s_sharp, -bwl2);
	float wl1 = 0.5 + fpx; wl1*=wl1; float twl1 = exp2(-hsharp_tl*wl1); twl1 = max(twl1 - s_sharp, -0.4*s_sharp); float bwl1 = exp2(-hsharp_bl*wl1); bwl1 = max(bwl1 - s_sharp, -0.4*s_sharp);
	float wct = 0.5 - fpx; wct*=wct; float twct = exp2(-hsharp_tc*wct); twct = max(twct - s_sharp,  s_sharp);     float bwct = exp2(-hsharp_bc*wct); bwct = max(bwct - s_sharp,  s_sharp);
	float wr1 = 1.5 - fpx; wr1*=wr1; float twr1 = exp2(-hsharp_tr*wr1); twr1 = max(twr1 - s_sharp, -0.4*s_sharp); float bwr1 = exp2(-hsharp_br*wr1); bwr1 = max(bwr1 - s_sharp, -0.4*s_sharp);
	float wr2 = 2.5 - fpx; wr2*=wr2; float twr2 = exp2(-hsharp_tr*wr2); twr2 = max(twr2 - s_sharp, -twr2);        float bwr2 = exp2(-hsharp_br*wr2); bwr2 = max(bwr2 - s_sharp, -bwr2);

	float wtt = 1.0/(twl2+twl1+twct+twr1+twr2);
	float wtb = 1.0/(bwl2+bwl1+bwct+bwr1+bwr2);
	
	vec3 l2 = COMPAT_TEXTURE(PassPrev3Texture, pC4 -off2).xyz;
	vec3 l1 = COMPAT_TEXTURE(PassPrev3Texture, pC4 -offx).xyz;
	vec3 ct = COMPAT_TEXTURE(PassPrev3Texture, pC4      ).xyz;
	vec3 r1 = COMPAT_TEXTURE(PassPrev3Texture, pC4 +offx).xyz;
	vec3 r2 = COMPAT_TEXTURE(PassPrev3Texture, pC4 +off2).xyz;
	
	vec3 color1 = (l2*twl2 + l1*twl1 + ct*twct + r1*twr1 + r2*twr2)*wtt;
	if (sharp) color1 = clamp(color1, min(min(l1,r1),ct), max(max(l1,r1),ct)); 
   
	l2 = COMPAT_TEXTURE(PassPrev3Texture, pC4 -off2 +offy).xyz;
	l1 = COMPAT_TEXTURE(PassPrev3Texture, pC4 -offx +offy).xyz;
	ct = COMPAT_TEXTURE(PassPrev3Texture, pC4       +offy).xyz; 
	r1 = COMPAT_TEXTURE(PassPrev3Texture, pC4 +offx +offy).xyz;
	r2 = COMPAT_TEXTURE(PassPrev3Texture, pC4 +off2 +offy).xyz;
	
	vec3 color2 = (l2*bwl2 + l1*bwl1 + ct*bwct + r1*bwr1 + r2*bwr2)*wtb;
	if (sharp) color2 = clamp(color2, min(min(l1,r1),ct), max(max(l1,r1),ct)); 
   
	// calculating scanlines
   
	float f = (TATE < 0.5) ? fp.y : fp.x;
	
	float shape1 = mix(scanline1, scanline2, f);
	float shape2 = mix(scanline1, scanline2, 1.0-f);	
	
	float wt1 = st(f, shape1);
	float wt2 = st(1.0-f, shape2);
	vec3 color0 = color1*wt1 + color2*wt2;
	vec3 ctmp = color0/(wt1+wt2);
	vec3 tmp = pow(ctmp, vec3(1.0/gamma_out));
	
	vec3 w1,w2 = vec3(0.0);
	
	vec3 cref1 = mix(ctmp, color1, beam_size);
	vec3 cref2 = mix(ctmp, color2, beam_size);
	
	vec3 shift = vec3(-vertmask, vertmask, -vertmask);
	
	vec3 f1 = clamp(vec3(f) + shift*0.5*(1.0+f), 0.0, 1.0); 
	vec3 f2 = clamp(vec3(1.0-f) - shift*0.5*(2.0-f), 0.0, 1.0);
	
	if (gsl == 0.0) { w1 = sw0(f1,cref1,shape1); w2 = sw0(f2,cref2,shape2);} else
	if (gsl == 1.0) { w1 = sw1(f1,cref1,shape1); w2 = sw1(f2,cref2,shape2);} else
	if (gsl == 2.0) { w1 = sw2(f1,cref1,shape1); w2 = sw2(f2,cref2,shape2);} 
	
	vec3 color = color1*w1 + color2*w2;
	
	color*=brightboost;
	color = min(color, 1.0); 
   
	// Apply Mask
	
	color *= (TATE < 0.5) ? Mask(gl_FragCoord.xy * 1.000001,tmp) :
		Mask(gl_FragCoord.yx * 1.000001,tmp);
	
	color = min(color,1.0);
	
	color *= (TATE < 0.5) ? SlotMask(gl_FragCoord.xy * 1.000001,tmp) :
		SlotMask(gl_FragCoord.yx * 1.000001,tmp);		
		
	vec3 Bloom = COMPAT_TEXTURE(Texture, pos).xyz;
   
	color+=glow*Bloom;
   
	color = pow(color, vec3(1.0/gamma_out));
	FragColor = vec4(color*corner(pos0), 1.0);
}