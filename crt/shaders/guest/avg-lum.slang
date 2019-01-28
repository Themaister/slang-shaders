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
} params;

#pragma parameter grade "Raster Bloom Grade" 0.65 0.10 1.0 0.05 

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

void main()
{
   float xtotal = floor(params.SourceSize.x/32.0);
   float ytotal = floor(params.SourceSize.y/32.0);
   
   float ltotal = 0.0;
   vec2 dx  = vec2(params.SourceSize.z, 0.0)*32.0;
	vec2 dy  = vec2(0.0, params.SourceSize.w)*32.0;

	for (float i = 0.0; i <= xtotal; i++)
	{
		for (float j = 0.0; j <= ytotal; j++)
			{
				ltotal += length(textureLod(Source, i*dx + j*dy, 5.0).rgb);
			}
   }

   ltotal = inversesqrt(3.0)*ltotal / ((xtotal+1.0)*(ytotal+1.0));

   FragColor = vec4(pow(ltotal, params.grade));
}