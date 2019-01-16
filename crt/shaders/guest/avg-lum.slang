#version 450

/*
   Average Luminance Shader
   
   Copyright (C) 2018 guest(r) - guest.r@gmail.com

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
   
   Thanks to HunterK for the mipmap hint. :D
*/

layout(push_constant) uniform Push
{
	vec4 SourceSize;
	vec4 OriginalSize;
	vec4 OutputSize;
	uint FrameCount;
	float grade;
   float mixfactor;
} params;

#pragma parameter mixfactor "Motionblur Fadeout" 0.75 0.0 1.0 0.01

#pragma parameter grade "Blooming grade" 0.70 0.10 1.0 0.05 

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
layout(set = 0, binding = 3) uniform sampler2D PassFeedback3;

void main()
{
	float mip_level = max(log2(params.SourceSize.x), log2(params.SourceSize.y));
   vec4 current = pow(textureLod(Source,        vTexCoord, 8), vec4(2.2));
   vec4 fdback  = pow(textureLod(PassFeedback3, vTexCoord, 8), vec4(2.2));
   vec4 mixed = (1.0 - params.mixfactor) * current + params.mixfactor * fdback;
   mixed = pow(mixed, vec4(1.0 / 2.2));
	float black_compensation = (params.SourceSize.x*params.SourceSize.y)/(params.SourceSize.x*params.SourceSize.y);
	float lum = length(mixed.rgb * black_compensation);
	lum = lum * inversesqrt(3.0);
	FragColor = vec4(pow(lum, params.grade));
}