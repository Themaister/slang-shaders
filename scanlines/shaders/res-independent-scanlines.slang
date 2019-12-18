#version 450

/*
   based on scanline shader by:
   Author: Themaister
   License: Public domain
*/

layout(push_constant) uniform Push
{
	vec4 SourceSize;
	vec4 OriginalSize;
	vec4 OutputSize;
	uint FrameCount;
   vec4 FinalViewportSize;
	float SCANLINE_SINE_COMP_B;
   float scanline_size;
} params;

#pragma parameter SCANLINE_SINE_COMP_B "Scanline Sine Comp B" 0.25 0.0 1.0 0.05
#pragma parameter scanline_size "Scanline Scale" 4.0 2.0 10.0 0.5

#define SCANLINE_SINE_COMP_B params.SCANLINE_SINE_COMP_B
#define scanline_size params.scanline_size

layout(std140, set = 0, binding = 0) uniform UBO
{
	mat4 MVP;
} global;

#define pi 3.141592654

#pragma stage vertex
layout(location = 0) in vec4 Position;
layout(location = 1) in vec2 TexCoord;
layout(location = 0) out vec2 vTexCoord;
layout(location = 1) out vec2 omega;

void main()
{
   gl_Position = global.MVP * Position;
   vTexCoord = TexCoord;
   
   omega = vec2(pi * params.OutputSize.x, 2.0 * pi * params.SourceSize.y);
}

#pragma stage fragment
layout(location = 0) in vec2 vTexCoord;
layout(location = 1) in vec2 omega;
layout(location = 0) out vec4 FragColor;
layout(set = 0, binding = 2) uniform sampler2D Source;

void main()
{
   vec2 sine_comp = vec2(0.0, SCANLINE_SINE_COMP_B);
   vec3 res = texture(Source, vTexCoord).xyz;
   vec2 fragcoord = fract(floor(vTexCoord.xy * params.OutputSize.xy * 1.0001) / scanline_size);
   vec3 scanline = (fragcoord.y > 0.3333)? res : vec3(SCANLINE_SINE_COMP_B * res);//res * ((1. - 0.75 * SCANLINE_SINE_COMP_B) + dot(sine_comp * sin((fragcoord / scanline_size) * omega), vec2(1.0, 1.0)));
   FragColor = vec4(scanline.x, scanline.y, scanline.z, 1.0);
}
