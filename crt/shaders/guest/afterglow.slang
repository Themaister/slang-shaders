#version 450

/*
   Phosphor Afterglow Shader
   
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
   
*/

layout(push_constant) uniform Push
{
	vec4 SourceSize;
	vec4 OriginalSize;
	vec4 OutputSize;
	uint FrameCount;
	float SW;
	float AR;
	float PR;
	float AG;
	float PG;
	float AB;
	float PB;
	float sat;
	float GTH;
} params;

#pragma parameter SW "Afterglow switch ON/OFF" 1.0 0.0 1.0 1.0
#pragma parameter AR "Afterglow Red (more is more)" 0.07 0.0 1.0 0.01
#pragma parameter PR "Persistence Red (more is less)" 0.05 0.0 1.0 0.01
#pragma parameter AG "Afterglow Green" 0.07 0.0 1.0 0.01
#pragma parameter PG "Persistence Green"  0.05 0.0 1.0 0.01
#pragma parameter AB "Afterglow Blue" 0.07 0.0 1.0 0.01
#pragma parameter PB "Persistence Blue"  0.05 0.0 1.0 0.01
#pragma parameter sat "Afterglow saturation" 0.10 0.0 1.0 0.01
#pragma parameter GTH "Afterglow threshold" 5.0 0.0 255.0 1.0

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
layout(set = 0, binding = 3) uniform sampler2D OriginalHistory1;
layout(set = 0, binding = 4) uniform sampler2D OriginalHistory2;
layout(set = 0, binding = 5) uniform sampler2D OriginalHistory3;
layout(set = 0, binding = 6) uniform sampler2D OriginalHistory4;
layout(set = 0, binding = 7) uniform sampler2D OriginalHistory5;
layout(set = 0, binding = 8) uniform sampler2D OriginalHistory6;

#define eps 1e-4

vec3 afterglow(float number)
{
	return vec3(params.AR, params.AG, params.AB)*exp2(-vec3(params.PR, params.PG, params.PB)*vec3(number*number));
}

void main()
{
	vec3 color = texture(Source, vTexCoord.xy).rgb;
	vec3 color1 = texture(OriginalHistory1, vTexCoord.xy).rgb * afterglow(1.0);
	vec3 color2 = texture(OriginalHistory2, vTexCoord.xy).rgb * afterglow(2.0);
	vec3 color3 = texture(OriginalHistory3, vTexCoord.xy).rgb * afterglow(3.0);
	vec3 color4 = texture(OriginalHistory4, vTexCoord.xy).rgb * afterglow(4.0);
	vec3 color5 = texture(OriginalHistory5, vTexCoord.xy).rgb * afterglow(5.0);
	vec3 color6 = texture(OriginalHistory6, vTexCoord.xy).rgb * afterglow(6.0);

	vec3 glow = color1 + color2 + color3 + color4 + color5 + color6;
	
	float l = length(glow);
	glow = normalize(pow(glow + vec3(eps), vec3(params.sat)))*l;		
	
	float w = 1.0;
	if ((color.r + color.g + color.b) > params.GTH/255.0) w = 0.0;
	
	FragColor = vec4(color + params.SW*w*glow,1.0);
}