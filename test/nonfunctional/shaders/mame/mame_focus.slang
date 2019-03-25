#version 450

// license:BSD-3-Clause
// copyright-holders:Ryan Holtz,ImJezze
//-----------------------------------------------------------------------------
// Defocus Effect
//-----------------------------------------------------------------------------

layout(push_constant) uniform Push
{
	vec4 SourceSize;
	vec4 OriginalSize;
	vec4 OutputSize;
	uint FrameCount;
	float defocus_x;
	float defocus_y;
} params;

#pragma parameter defocus_x "Defocus X Axis" 0.0 0.0 10.0 0.1
#pragma parameter defocus_y "Defocus Y Axis" 0.0 0.0 10.0 0.1

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

#define DiffuseSampler Source

vec2 Defocus = vec2(params.defocus_x, params.defocus_y);

// previously this pass was applied two times with offsets of 0.25, 0.5, 0.75, 1.0
// now this pass is applied only once with offsets of 0.25, 0.55, 1.0, 1.6 to achieve the same appearance as before till a maximum defocus of 2.0
const vec2 CoordOffset8[8] =
vec2[8](
	// 0.075x² + 0.225x + 0.25
	vec2(-1.60f,  0.25f),
	vec2(-1.00f, -0.55f),
	vec2(-0.55f,  1.00f),
	vec2(-0.25f, -1.60f),
	vec2( 0.25f,  1.60f),
	vec2( 0.55f, -1.00f),
	vec2( 1.00f,  0.55f),
	vec2( 1.60f, -0.25f)
);

void main()
{
	// imaginary texel dimensions independed from source and target dimension
	vec2 TexelDims = vec2(1.0f / 1024.0f);

	vec2 DefocusTexelDims = Defocus * TexelDims;

	vec3 texel = texture(DiffuseSampler, vTexCoord).rgb;
	float samples = 1.0f;

	for (int i = 0; i < 8; i++)
	{
		texel += texture(DiffuseSampler, vTexCoord + CoordOffset8[i] * DefocusTexelDims).rgb;
		samples += 1.0f;
	}

    FragColor = vec4(texel / samples, 1.0);
}
