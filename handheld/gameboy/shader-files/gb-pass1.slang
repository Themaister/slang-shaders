#version 450

layout(std140, set = 0, binding = 0) uniform UBO
{
   mat4 MVP;
   vec4 OutputSize;
   vec4 OriginalSize;
   vec4 SourceSize;
} global;

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//config                                                                                                                                  //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#define blending_mode 0							//0 - only the space between dots is blending, 1 - all texels are blended
#define adjacent_texel_alpha_blending 0.1755	//the amount of alpha swapped between neighboring texels

///////////////////////////////////////////////////////////////////////////
//                                                                       //
// Gameboy Classic Shader v0.2.2                                         //
//                                                                       //
// Copyright (C) 2013 Harlequin : unknown92835@gmail.com                 //
//                                                                       //
// This program is free software: you can redistribute it and/or modify  //
// it under the terms of the GNU General Public License as published by  //
// the Free Software Foundation, either version 3 of the License, or     //
// (at your option) any later version.                                   //
//                                                                       //
// This program is distributed in the hope that it will be useful,       //
// but WITHOUT ANY WARRANTY; without even the implied warranty of        //
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the         //
// GNU General Public License for more details.                          //
//                                                                       //
// You should have received a copy of the GNU General Public License     //
// along with this program.  If not, see <http://www.gnu.org/licenses/>. //
//                                                                       //
///////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//vertex shader                                                                                                                           //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

#pragma stage vertex
layout(location = 0) in vec4 Position;
layout(location = 1) in vec2 TexCoord;
layout(location = 0) out vec2 vTexCoord;
layout(location = 1) out vec2 texel;
layout(location = 2) out vec2 blur_coords_up;
layout(location = 3) out vec2 blur_coords_down;
layout(location = 4) out vec2 blur_coords_right;
layout(location = 5) out vec2 blur_coords_left;
layout(location = 6) out vec2 blur_coords_lower_bound;
layout(location = 7) out vec2 blur_coords_upper_bound;

void main()
{
   gl_Position = global.MVP * Position;
   vTexCoord = TexCoord;
   texel = 1.0 / global.SourceSize.xy;
   blur_coords_up    = vTexCoord + vec2(0.0, texel.y);
   blur_coords_down  = vTexCoord + vec2(0.0, -texel.y);
   blur_coords_right = vTexCoord + vec2(texel.x, 0.0);
   blur_coords_left  = vTexCoord + vec2(-texel.x, 0.0);
   blur_coords_lower_bound = vec2(0.0);
   blur_coords_upper_bound = texel * (global.OutputSize.xy - vec2(2.0));
   
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//fragment shader                                                                                                                         //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

#pragma stage fragment
layout(location = 0) in vec2 vTexCoord;
layout(location = 1) in vec2 texel;
layout(location = 2) in vec2 blur_coords_up;
layout(location = 3) in vec2 blur_coords_down;
layout(location = 4) in vec2 blur_coords_right;
layout(location = 5) in vec2 blur_coords_left;
layout(location = 6) in vec2 blur_coords_lower_bound;
layout(location = 7) in vec2 blur_coords_upper_bound;
layout(location = 0) out vec4 FragColor;
layout(set = 0, binding = 2) uniform sampler2D Source;

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//fragment definitions                                                                                                                    //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

//#define blending_modifier(color) clamp((color.a == 0) + blending_mode, 0.0, 1.0)

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//fragment functions                                                                                                                      //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

void main()
{
//sample the input textures
  vec4 out_color = texture(Source, vTexCoord).rgba;

//clamp the blur coords to the input texture size so it doesn't attempt to sample off the texture (it'll retrieve float4(0.0) and darken the edges otherwise)
    vec2 blur_coords_up_clamped = clamp(blur_coords_up, blur_coords_lower_bound, blur_coords_upper_bound);
    vec2 blur_coords_down_clamped = clamp(blur_coords_down, blur_coords_lower_bound, blur_coords_upper_bound);
    vec2 blur_coords_right_clamped = clamp(blur_coords_right, blur_coords_lower_bound, blur_coords_upper_bound);
    vec2 blur_coords_left_clamped = clamp(blur_coords_left, blur_coords_lower_bound, blur_coords_upper_bound);

//sample adjacent texels based on the coordinates above
    vec4 adjacent_texel_1 = texture(Source, blur_coords_up_clamped).rgba;
    vec4 adjacent_texel_2 = texture(Source, blur_coords_down_clamped).rgba;
    vec4 adjacent_texel_3 = texture(Source, blur_coords_right_clamped).rgba;
    vec4 adjacent_texel_4 = texture(Source, blur_coords_left_clamped).rgba;
	
//sum the alpha differences between neighboring texels, apply modifiers, then subtract the result from the current fragment alpha value
    out_color.a -= ( (out_color.a - adjacent_texel_1.a) + 
		 (out_color.a - adjacent_texel_2.a) + 
		 (out_color.a - adjacent_texel_3.a) + 
		 (out_color.a - adjacent_texel_4.a) ) * adjacent_texel_alpha_blending;
	out_color.a	*= clamp((0.0) + blending_mode, 0.0, 1.0);

//return
   FragColor = vec4(out_color);
}