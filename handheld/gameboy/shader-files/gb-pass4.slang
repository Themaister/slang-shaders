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

#define contrast 0.95   	//useful to fine-tune the colors. higher values make the "black" color closer to black - [0, 1] [DEFAULT: 0.95]
#define screen_light 1.00   //controls the ambient light of the screen. lower values darken the screen - [0, 2] [DEFAULT: 1.00]
#define pixel_opacity 1.00	//controls the opacity of the dot-matrix pixels. lower values make pixels more transparent - [0, 1] [DEFAULT: 1.00]
#define bg_smoothing 0.75	//higher values suppress changes in background color directly beneath the foreground to improve image clarity - [0, 1] [DEFAULT: 0.75]
#define shadow_opacity 0.55	//how strongly shadows affect the background, higher values darken the shadows - [0, 1] [DEFAULT: 0.55]
#define shadow_offset_x 1.0	//how far the shadow should be shifted to the right in pixels - [-infinity, infinity] [DEFAULT: 1.0]
#define shadow_offset_y 1.0	//how far the shadow should be shifted to down in pixels - [-infinity, infinity] [DEFAULT: 1.5]
#define screen_offset_x 0	//screen offset - [-infinity, infinity] [DEFAULT: 0]
#define screen_offset_y 0	//screen offset - [-infinity, infinity] [DEFAULT: 0]

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

#pragma stage vertex
layout(location = 0) in vec4 Position;
layout(location = 1) in vec2 TexCoord;
layout(location = 0) out vec2 vTexCoord;
layout(location = 1) out vec2 texel;

void main()
{
   gl_Position = global.MVP * Position;
   vTexCoord = TexCoord;
   texel = 1.0 / global.SourceSize.xy;
}

#pragma stage fragment
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//fragment definitions                                                                                                                    //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

#define bg_color vec4(0.625, 0.664, 0.02, 1.0) //tex2D(COLOR_PALETTE, vec2(0.25, 0.5))				//sample the background color from the palette
#define shadow_alpha (contrast * shadow_opacity)					//blending factor used when overlaying shadows on the background
#define shadow_offset vec2(shadow_offset_x * texel.x, shadow_offset_y * texel.y)	//offset for the shadow
#define screen_offset vec2(screen_offset_x * texel.x, screen_offset_y * texel.y)	//offset for the entire screen

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//fragment shader                                                                                                                         //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

layout(location = 0) in vec2 vTexCoord;
layout(location = 1) in vec2 texel;
layout(location = 0) out vec4 FragColor;
layout(set = 0, binding = 2) uniform sampler2D Source;
layout(set = 0, binding = 3) uniform sampler2D PASS1;

void main()
{
//sample all the relevant textures
vec4 foreground = texture(PASS1, vTexCoord - screen_offset);
vec4 background = vec4(0.5);
vec4 shadows    = texture(Source, vTexCoord - (shadow_offset + screen_offset));
vec4 background_color = bg_color;

//foreground and background are blended with the background color
  foreground *= bg_color;
  float bg_test = 0.0;
  if ( foreground.a > 0.0 )
		{ bg_test = 1.0; }
  background -= (background - 0.5) * bg_smoothing * bg_test;

  background.rgb = clamp(vec3( 				//allows for highlights, background = bg_color when the background color is 0.5 gray
	bg_color.r + mix(-1.0, 1.0, background.r), 
	bg_color.g + mix(-1.0, 1.0, background.g), 
	bg_color.b + mix(-1.0, 1.0, background.b) ), 0.0, 1.0);

//shadows are alpha blended with the background
  vec4 out_color = (shadows * shadows.a * shadow_alpha) + (background * (1.0 - shadows.a * shadow_alpha));	

//foreground is alpha blended with the shadowed background
  out_color = (foreground * foreground.a * contrast) + (out_color * (screen_light - foreground.a * contrast * pixel_opacity));
  
   FragColor = vec4(out_color);
}