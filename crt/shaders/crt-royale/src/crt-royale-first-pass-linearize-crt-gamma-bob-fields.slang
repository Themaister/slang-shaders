#version 450

layout(push_constant) uniform Push
{
	vec4 SourceSize;
	uint FrameCount;
} registers;

layout(std140, set = 0, binding = 0) uniform UBO
{
	mat4 MVP;
	float crt_gamma;
    float lcd_gamma;
    float levels_contrast;
    float halation_weight;
    float diffusion_weight;
    float bloom_underestimate_levels;
    float bloom_excess;
    float beam_min_sigma;
    float beam_max_sigma;
    float beam_spot_power;
    float beam_min_shape;
    float beam_max_shape;
    float beam_shape_power;
    float beam_horiz_filter;
    float beam_horiz_sigma;
    float beam_horiz_linear_rgb_weight;
    float convergence_offset_x_r;
    float convergence_offset_x_g;
    float convergence_offset_x_b;
    float convergence_offset_y_r;
    float convergence_offset_y_g;
    float convergence_offset_y_b;
    float mask_type;
    float mask_sample_mode_desired;
    float mask_specify_num_triads;
    float mask_triad_size_desired;
    float mask_num_triads_desired;
    float aa_subpixel_r_offset_x_runtime;
    float aa_subpixel_r_offset_y_runtime;
    float aa_cubic_c;
    float aa_gauss_sigma;
    float geom_mode_runtime;
    float geom_radius;
    float geom_view_dist;
    float geom_tilt_angle_x;
    float geom_tilt_angle_y;
    float geom_aspect_ratio_x;
    float geom_aspect_ratio_y;
    float geom_overscan_x;
    float geom_overscan_y;
    float border_size;
    float border_darkness;
    float border_compress;
    float interlace_bff;
    float interlace_1080i;
} params;

/////////////////////////////  GPL LICENSE NOTICE  /////////////////////////////

//  crt-royale: A full-featured CRT shader, with cheese.
//  Copyright (C) 2014 TroggleMonkey <trogglemonkey@gmx.com>
//
//  This program is free software; you can redistribute it and/or modify it
//  under the terms of the GNU General Public License as published by the Free
//  Software Foundation; either version 2 of the License, or any later version.
//
//  This program is distributed in the hope that it will be useful, but WITHOUT
//  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
//  FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for
//  more details.
//
//  You should have received a copy of the GNU General Public License along with
//  this program; if not, write to the Free Software Foundation, Inc., 59 Temple
//  Place, Suite 330, Boston, MA 02111-1307 USA


/////////////////////////////  SETTINGS MANAGEMENT  ////////////////////////////

//  PASS SETTINGS:
//  gamma-management.h needs to know what kind of pipeline we're using and
//  what pass this is in that pipeline.  This will become obsolete if/when we
//  can #define things like this in the preset file.
#define FIRST_PASS
#define SIMULATE_CRT_ON_LCD

#include "params.inc"

//////////////////////////////////  INCLUDES  //////////////////////////////////

#include "../user-settings.h"
#include "bind-shader-params.h"
//#include "../../../../include/gamma-management.h"
//#include "scanline-functions.h"

// from scanline-functions.h //
bool is_interlaced(float num_lines)
{
    //  Detect interlacing based on the number of lines in the source.
    if(interlace_detect)
    {
        //  NTSC: 525 lines, 262.5/field; 486 active (2 half-lines), 243/field
        //  NTSC Emulators: Typically 224 or 240 lines
        //  PAL: 625 lines, 312.5/field; 576 active (typical), 288/field
        //  PAL Emulators: ?
        //  ATSC: 720p, 1080i, 1080p
        //  Where do we place our cutoffs?  Assumptions:
        //  1.) We only need to care about active lines.
        //  2.) Anything > 288 and <= 576 lines is probably interlaced.
        //  3.) Anything > 576 lines is probably not interlaced...
        //  4.) ...except 1080 lines, which is a crapshoot (user decision).
        //  5.) Just in case the main program uses calculated video sizes,
        //      we should nudge the float thresholds a bit.
        bool sd_interlace;
		if (num_lines > 288.5 && num_lines < 576.5)
			{sd_interlace = true;}
		else
			{sd_interlace = false;}
        bool hd_interlace;
        if (num_lines > 1079.5 && num_lines < 1080.5)
			{hd_interlace = true;}
		else
			{hd_interlace = false;}
		return (sd_interlace || hd_interlace);
    }
    else
    {
        return false;
    }
}
// end scanline-functions.h //

// from gamma-management.h //
///////////////////////////////  BASE CONSTANTS  ///////////////////////////////

//  Set standard gamma constants, but allow users to override them:
#ifndef OVERRIDE_STANDARD_GAMMA
    //  Standard encoding gammas:
    const float ntsc_gamma = 2.2;    //  Best to use NTSC for PAL too?
    const float pal_gamma = 2.8;     //  Never actually 2.8 in practice
    //  Typical device decoding gammas (only use for emulating devices):
    //  CRT/LCD reference gammas are higher than NTSC and Rec.709 video standard
    //  gammas: The standards purposely undercorrected for an analog CRT's
    //  assumed 2.5 reference display gamma to maintain contrast in assumed
    //  [dark] viewing conditions: http://www.poynton.com/PDFs/GammaFAQ.pdf
    //  These unstated assumptions about display gamma and perceptual rendering
    //  intent caused a lot of confusion, and more modern CRT's seemed to target
    //  NTSC 2.2 gamma with circuitry.  LCD displays seem to have followed suit
    //  (they struggle near black with 2.5 gamma anyway), especially PC/laptop
    //  displays designed to view sRGB in bright environments.  (Standards are
    //  also in flux again with BT.1886, but it's underspecified for displays.)
    const float crt_reference_gamma_high = 2.5;  //  In (2.35, 2.55)
    const float crt_reference_gamma_low = 2.35;  //  In (2.35, 2.55)
    const float lcd_reference_gamma = 2.5;       //  To match CRT
    const float crt_office_gamma = 2.2;  //  Circuitry-adjusted for NTSC
    const float lcd_office_gamma = 2.2;  //  Approximates sRGB
#endif  //  OVERRIDE_STANDARD_GAMMA

//  Assuming alpha == 1.0 might make it easier for users to avoid some bugs,
//  but only if they're aware of it.
#ifndef OVERRIDE_ALPHA_ASSUMPTIONS
    const bool assume_opaque_alpha = false;
#endif


///////////////////////  DERIVED CONSTANTS AS FUNCTIONS  ///////////////////////

//  gamma-management.h should be compatible with overriding gamma values with
//  runtime user parameters, but we can only define other global constants in
//  terms of static constants, not uniform user parameters.  To get around this
//  limitation, we need to define derived constants using functions.

//  Set device gamma constants, but allow users to override them:
#ifdef OVERRIDE_DEVICE_GAMMA
    //  The user promises to globally define the appropriate constants:
    float get_crt_gamma()    {   return crt_gamma;   }
    float get_gba_gamma()    {   return gba_gamma;   }
    float get_lcd_gamma()    {   return lcd_gamma;   }
#else
    float get_crt_gamma()    {   return crt_reference_gamma_high;    }
    float get_gba_gamma()    {   return 3.5; }   //  Game Boy Advance; in (3.0, 4.0)
    float get_lcd_gamma()    {   return lcd_office_gamma;            }
#endif  //  OVERRIDE_DEVICE_GAMMA

//  Set decoding/encoding gammas for the first/lass passes, but allow overrides:
#ifdef OVERRIDE_FINAL_GAMMA
    //  The user promises to globally define the appropriate constants:
    float get_intermediate_gamma()   {   return intermediate_gamma;  }
    float get_input_gamma()          {   return input_gamma;         }
    float get_output_gamma()         {   return output_gamma;        }
#else
    //  If we gamma-correct every pass, always use ntsc_gamma between passes to
    //  ensure middle passes don't need to care if anything is being simulated:
    float get_intermediate_gamma()   {   return ntsc_gamma;          }
    #ifdef SIMULATE_CRT_ON_LCD
        float get_input_gamma()      {   return get_crt_gamma();     }
        float get_output_gamma()     {   return get_lcd_gamma();     }
    #else
    #ifdef SIMULATE_GBA_ON_LCD
        float get_input_gamma()      {   return get_gba_gamma();     }
        float get_output_gamma()     {   return get_lcd_gamma();     }
    #else
    #ifdef SIMULATE_LCD_ON_CRT
        float get_input_gamma()      {   return get_lcd_gamma();     }
        float get_output_gamma()     {   return get_crt_gamma();     }
    #else
    #ifdef SIMULATE_GBA_ON_CRT
        float get_input_gamma()      {   return get_gba_gamma();     }
        float get_output_gamma()     {   return get_crt_gamma();     }
    #else   //  Don't simulate anything:
        float get_input_gamma()      {   return ntsc_gamma;          }
        float get_output_gamma()     {   return ntsc_gamma;          }
    #endif  //  SIMULATE_GBA_ON_CRT
    #endif  //  SIMULATE_LCD_ON_CRT
    #endif  //  SIMULATE_GBA_ON_LCD
    #endif  //  SIMULATE_CRT_ON_LCD
#endif  //  OVERRIDE_FINAL_GAMMA

#ifndef GAMMA_ENCODE_EVERY_FBO
    #ifdef FIRST_PASS
        const bool linearize_input = true;
        float get_pass_input_gamma()     {   return get_input_gamma();   }
    #else
        const bool linearize_input = false;
        float get_pass_input_gamma()     {   return 1.0;                 }
    #endif
    #ifdef LAST_PASS
        const bool gamma_encode_output = true;
        float get_pass_output_gamma()    {   return get_output_gamma();  }
    #else
        const bool gamma_encode_output = false;
        float get_pass_output_gamma()    {   return 1.0;                 }
    #endif
#else
    const bool linearize_input = true;
    const bool gamma_encode_output = true;
    #ifdef FIRST_PASS
        float get_pass_input_gamma()     {   return get_input_gamma();   }
    #else
        float get_pass_input_gamma()     {   return get_intermediate_gamma();    }
    #endif
    #ifdef LAST_PASS
        float get_pass_output_gamma()    {   return get_output_gamma();  }
    #else
        float get_pass_output_gamma()    {   return get_intermediate_gamma();    }
    #endif
#endif

vec4 decode_input(const vec4 color)
{
    if(linearize_input)
    {
        if(assume_opaque_alpha)
        {
            return vec4(pow(color.rgb, vec3(get_pass_input_gamma())), 1.0);
        }
        else
        {
            return vec4(pow(color.rgb, vec3(get_pass_input_gamma())), color.a);
        }
    }
    else
    {
        return color;
    }
}

vec4 encode_output(const vec4 color)
{
    if(gamma_encode_output)
    {
        if(assume_opaque_alpha)
        {
            return vec4(pow(color.rgb, vec3(1.0/get_pass_output_gamma())), 1.0);
        }
        else
        {
            return vec4(pow(color.rgb, vec3(1.0/get_pass_output_gamma())), color.a);
        }
    }
    else
    {
        return color;
    }
}

#define tex2D_linearize(C, D) decode_input(vec4(texture(C, D)))
//vec4 tex2D_linearize(const sampler2D tex, const vec2 tex_coords)
//{   return decode_input(vec4(texture(tex, tex_coords)));   }

//#define tex2D_linearize(C, D, E) decode_input(vec4(texture(C, D, E)))
//vec4 tex2D_linearize(const sampler2D tex, const vec2 tex_coords, const int texel_off)
//{   return decode_input(vec4(texture(tex, tex_coords, texel_off)));    }

// end gamma-management.h //

#pragma stage vertex
layout(location = 0) in vec4 Position;
layout(location = 1) in vec2 TexCoord;
layout(location = 0) out vec2 tex_uv;
layout(location = 1) out vec2 uv_step;

void main()
{
	gl_Position = params.MVP * Position;
	tex_uv = TexCoord;
   
	//  Save the uv distance between texels:
	uv_step = vec2(1.0) * registers.SourceSize.zw;
}

#pragma stage fragment
layout(location = 0) in vec2 tex_uv;
layout(location = 1) in vec2 uv_step;
layout(location = 0) out vec4 FragColor;
layout(set = 0, binding = 2) uniform sampler2D Source;

void main()
{
	//  Detect interlacing: 1.0 = true, 0.0 = false.
	const vec2 video_size = registers.SourceSize.xy;
	bool interlaced = is_interlaced(video_size.y);
	
//  Linearize the input based on CRT gamma and bob interlaced fields.
//  Bobbing ensures we can immediately blur without getting artifacts.
//  Note: TFF/BFF won't matter for sources that double-weave or similar.
if(interlace_detect)
    {
        //  Sample the current line and an average of the previous/next line;
        //  tex2D_linearize will decode CRT gamma.  Don't bother branching:
//        const vec2 tex_uv = tex_uv;
        const vec2 v_step = vec2(0.0, uv_step.y);
        const vec3 curr_line = tex2D_linearize(
            Source, tex_uv).rgb;
        const vec3 last_line = tex2D_linearize(
            Source, tex_uv - v_step).rgb;
        const vec3 next_line = tex2D_linearize(
            Source, tex_uv + v_step).rgb;
        const vec3 interpolated_line = 0.5 * (last_line + next_line);
        //  If we're interlacing, determine which field curr_line is in:
		float interlace_check = 0.0;
		if (interlaced == true) interlace_check = 1.0;
        const float modulus = interlace_check + 1.0;
        const float field_offset =
            mod(registers.FrameCount + float(params.interlace_bff), modulus);
        const float curr_line_texel = tex_uv.y * registers.SourceSize.y;
        //  Use under_half to fix a rounding bug around exact texel locations.
        const float line_num_last = floor(curr_line_texel - under_half);
        const float wrong_field = mod(line_num_last + field_offset, modulus);
        //  Select the correct color, and output the result:
        const vec3 color = mix(curr_line, interpolated_line, wrong_field);
        FragColor = encode_output(vec4(color, 1.0));
    }
    else
    {
        FragColor = encode_output(tex2D_linearize(Source, tex_uv));
    }
}