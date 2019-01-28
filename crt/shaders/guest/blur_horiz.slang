#version 450

// Higher value, more centered glow.
// Lower values might need more taps.

layout(push_constant) uniform Push
{
	vec4 SourceSize;
	vec4 OriginalSize;
	vec4 OutputSize;
	uint FrameCount;
	float TAPSH;
	float GLOW_FALLOFF_H;
} params;

#pragma parameter TAPSH "H. Glow Radius" 4.0 1.0 10.0 1.0 
#pragma parameter GLOW_FALLOFF_H "Horizontal Glow Grade" 0.30 0.0 1.0 0.01 

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

#define kernel(x) exp(-params.GLOW_FALLOFF_H * (x) * (x))

void main()
{
	vec3 col = vec3(0.0);
	float dx = params.SourceSize.z;

	float k_total = 0.;
	for (float i = -params.TAPSH; i <= params.TAPSH; i++)
		{
		float k = kernel(i);
		k_total += k;
		col += k * texture(Source, vTexCoord + vec2(float(i) * dx, 0.0)).rgb;
		}
   FragColor = vec4(col / k_total, 1.0);
}