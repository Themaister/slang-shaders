#version 450

layout(push_constant) uniform Push
{
	vec4 SourceSize;
	vec4 OriginalSize;
	vec4 OutputSize;
	uint FrameCount;
} params;

layout(std140, set = 0, binding = 0) uniform UBO
{
	mat4 MVP;
} global;

#pragma stage vertex
layout(location = 0) in vec4 Position;
layout(location = 1) in vec2 TexCoord;
layout(location = 0) out vec2 vTexCoord;
layout(location = 1) out vec4 t1;

void main()
{
	gl_Position = global.MVP * Position;
	vTexCoord = TexCoord;
	vec2 ps = params.SourceSize.zw;
	float dx = ps.x;
	float dy = ps.y;
	t1 = vTexCoord.xxxy + vec4( -dx, 0, dx, 0); // L, C, R
}

#pragma stage fragment
layout(location = 0) in vec2 vTexCoord;
layout(location = 1) in vec4 t1;
layout(location = 0) out vec4 FragColor;
layout(set = 0, binding = 2) uniform sampler2D Source;

void main()
{
	// pixel location
	float fp = round(fract(0.5*vTexCoord.x*params.SourceSize.x));

	// reading the texels
	vec3 l = texture(Source, t1.xw).xyz;
	vec3 c = texture(Source, t1.yw).xyz;
	vec3 r = texture(Source, t1.zw).xyz;

	// output
	FragColor = vec4((params.SourceSize.x > 500) ? (fp == 0 ? mix(c,r,0.5) : mix(c,l,0.5)) : c, 1.0);
}