#version 450

// license:BSD-3-Clause
// copyright-holders:Ryan Holtz
//-----------------------------------------------------------------------------
// Color-Convolution Effect
//-----------------------------------------------------------------------------

layout(push_constant) uniform Push
{
	vec4 SourceSize;
	vec4 OriginalSize;
	vec4 OutputSize;
	uint FrameCount;
	float col_red;
	float col_grn;
	float col_blu;
	float col_offset_x;
	float col_offset_y;
	float col_offset_z;
	float col_scale_x;
	float col_scale_y;
	float col_scale_z;
	float col_saturation;
} params;

#pragma parameter col_red "Red Shift" 1.0 0.0 1.0 0.01
#pragma parameter col_grn "Green Shift" 1.0 0.0 1.0 0.01
#pragma parameter col_blu "Blue Shift" 1.0 0.0 1.0 0.01
#pragma parameter col_offset_x "Offset X" 0.0 0.0 1.0 0.01
#pragma parameter col_offset_y "Offset Y" 0.0 0.0 1.0 0.01
#pragma parameter col_offset_z "Offset Z" 0.0 0.0 1.0 0.01
#pragma parameter col_scale_x "Scale X" 1.0 0.0 1.0 0.01
#pragma parameter col_scale_y "Scale Y" 1.0 0.0 1.0 0.01
#pragma parameter col_scale_z "Scale Z" 1.0 0.0 1.0 0.01
#pragma parameter col_saturation "Saturation" 1.0 0.0 0.01

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

vec3 RedRatios = vec3(params.col_red, 0.0f, 0.0f);
vec3 GrnRatios = vec3(0.0f, params.col_grn, 0.0f);
vec3 BluRatios = vec3(0.0f, 0.0f, params.col_blu);
vec3 Offset = vec3(params.col_offset_x, params.col_offset_y, params.col_offset_z);
vec3 Scale = vec3(params.col_scale_x, params.col_scale_y, params.col_scale_z);
float Saturation = params.col_saturation;

void main()
{
	vec4 BaseTexel = texture(DiffuseSampler, vTexCoord);

	vec3 OutRGB = BaseTexel.rgb;

	// RGB Tint & Shift
	float ShiftedRed = dot(OutRGB, RedRatios);
	float ShiftedGrn = dot(OutRGB, GrnRatios);
	float ShiftedBlu = dot(OutRGB, BluRatios);

	// RGB Scale & Offset
	vec3 OutTexel = vec3(ShiftedRed, ShiftedGrn, ShiftedBlu) * Scale + Offset;

	// Saturation
	vec3 Grayscale = vec3(0.299f, 0.587f, 0.114f);
	float OutLuma = dot(OutTexel, Grayscale);
	vec3 OutChroma = OutTexel - OutLuma;
	vec3 Saturated = OutLuma + OutChroma * Saturation;

	FragColor = vec4(Saturated, BaseTexel.a);
}
