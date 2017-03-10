#version 450

layout(push_constant) uniform Push
{
	vec4 SourceSize;
	uint FrameCount;
	float target_gamma;
	float monitor_gamma;
	float overscan_percent_x;
	float overscan_percent_y;
	float saturation;
	float contrast;
	float luminance;
	float black_level;
	float bright_boost;
	float R;
	float G;
	float B;
	float ZOOM;
	float XPOS;
	float YPOS;
	float TOPMASK;
	float BOTMASK;
	float LMASK;
	float RMASK;
	float GRAIN_STR;
	float SHARPEN;
} registers;

layout(std140, set = 0, binding = 0) uniform UBO
{
   mat4 MVP;
   float FLIP_HORZ;
   float FLIP_VERT;
} global;

#pragma parameter target_gamma "Target Gamma" 2.2 0.1 5.0 0.1
#pragma parameter monitor_gamma "Monitor Gamma" 2.2 0.1 5.0 0.1
#pragma parameter overscan_percent_x "Horizontal Overscan %" 0.0 -25.0 25.0 1.0
#pragma parameter overscan_percent_y "Vertical Overscan %" 0.0 -25.0 25.0 1.0
#pragma parameter saturation "Saturation" 1.0 0.0 5.0 0.1
#pragma parameter contrast "Contrast" 1.0 0.0 10.0 0.05
#pragma parameter luminance "Luminance" 1.0 0.0 2.0 0.1
#pragma parameter black_level "Black Level" 0.00 -0.30 0.30 0.01
#pragma parameter bright_boost "Brightness Boost" 0.0 -1.0 1.0 0.05
#pragma parameter R "Red Channel" 1.0 0.0 2.0 0.05
#pragma parameter G "Green Channel" 1.0 0.0 2.0 0.05
#pragma parameter B "Blue Channel" 1.0 0.0 2.0 0.05
#pragma parameter ZOOM "Zoom Factor" 1.0 0.0 4.0 0.01
#pragma parameter XPOS "X Modifier" 0.0 -2.0 2.0 0.005
#pragma parameter YPOS "Y Modifier" 0.0 -2.0 2.0 0.005
#pragma parameter TOPMASK "Overscan Mask Top" 0.0 0.0 1.0 0.0025
#pragma parameter BOTMASK "Overscan Mask Bottom" 0.0 0.0 1.0 0.0025
#pragma parameter LMASK "Overscan Mask Left" 0.0 0.0 1.0 0.0025
#pragma parameter RMASK "Overscan Mask Right" 0.0 0.0 1.0 0.0025
#pragma parameter GRAIN_STR "Film Grain" 0.0 0.0 72.0 6.0
#pragma parameter SHARPEN "Sharpen" 0.0 0.0 1.0 0.05
#pragma parameter FLIP_HORZ "Flip Horiz Axis" 0.0 0.0 1.0 1.0
#pragma parameter FLIP_VERT "Flip Vert Axis" 0.0 0.0 1.0 1.0

//   Image Adjustment
//   Author: hunterk
//   License: Public domain

#include "colorspace-tools.h"

//https://www.shadertoy.com/view/4sXSWs strength= 16.0
vec3 filmGrain(vec2 uv, float strength ){       
    float x = (uv.x + 4.0 ) * (uv.y + 4.0 ) * ((mod(vec2(registers.FrameCount, registers.FrameCount).x, 800.0) + 10.0) * 10.0);
	return  vec3(mod((mod(x, 13.0) + 1.0) * (mod(x, 123.0) + 1.0), 0.01)-0.005) * strength;
}

// based on "Improved texture interpolation" by Iñigo Quílez
// Original description: http://www.iquilezles.org/www/articles/texture/texture.htm
vec3 sharp(sampler2D tex, vec2 texCoord){
	vec2 p = texCoord.xy;
	p = p * registers.SourceSize.xy + vec2(0.5, 0.5);
	vec2 i = floor(p);
	vec2 f = p - i;
	f = f * f * f * (f * (f * 6.0 - vec2(15.0, 15.0)) + vec2(10.0, 10.0));
	p = i + f;
	p = (p - vec2(0.5, 0.5)) * registers.SourceSize.zw;
	return texture(tex, p).rgb;
}

#pragma stage vertex
layout(location = 0) in vec4 Position;
layout(location = 1) in vec2 TexCoord;
layout(location = 0) out vec2 vTexCoord;

void main()
{
   vec4 flip_pos = Position;
   if (global.FLIP_HORZ > 0.5) flip_pos.x = 1.0 - flip_pos.x;
   if (global.FLIP_VERT > 0.5) flip_pos.y = 1.0 - flip_pos.y;   
   gl_Position = global.MVP * flip_pos;
   vec2 shift = vec2(0.5);
   vec2 overscan_coord = ((TexCoord - shift) / registers.ZOOM) * (1.0 - vec2(registers.overscan_percent_x / 100.0, registers.overscan_percent_y / 100.0)) + shift;
   vTexCoord = overscan_coord + vec2(registers.XPOS, registers.YPOS);
}

#pragma stage fragment
layout(location = 0) in vec2 vTexCoord;
layout(location = 0) out vec4 FragColor;
layout(set = 0, binding = 2) uniform sampler2D Source;

void main()
{
   vec3 film_grain = filmGrain(vTexCoord, registers.GRAIN_STR);
   vec3 res = texture(Source, vTexCoord).rgb; // sample the texture
   res = mix(res, sharp(Source, vTexCoord), registers.SHARPEN) + film_grain; // add film grain and sharpness
   vec3 gamma = vec3(registers.monitor_gamma / registers.target_gamma); // set up ratio of display's gamma vs desired gamma

//saturation and luminance
   vec3 satColor = clamp(HSVtoRGB(RGBtoHSV(res) * vec3(1.0, registers.saturation, registers.luminance)), 0.0, 1.0);

//contrast and brightness
   vec3 conColor = clamp((satColor - 0.5) * registers.contrast + 0.5 + registers.bright_boost, 0.0, 1.0);
   
   conColor -= vec3(registers.black_level); // apply black level
   conColor *= (vec3(1.0) / vec3(1.0-registers.black_level));
   conColor = pow(conColor, 1.0 / vec3(gamma)); // Apply gamma correction
   conColor *= vec3(registers.R, registers.G, registers.B);
   
//overscan mask
if (vTexCoord.y > registers.TOPMASK && vTexCoord.y < (1.0 - registers.BOTMASK))
   conColor = conColor;
else
   conColor = vec3(0.0);

if (vTexCoord.x > registers.LMASK && vTexCoord.x < (1.0 - registers.RMASK))
   conColor = conColor;
else
   conColor = vec3(0.0);
   
   FragColor = vec4(conColor, 1.0);
}