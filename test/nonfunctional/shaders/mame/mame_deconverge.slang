#version 450

// license:BSD-3-Clause
// copyright-holders:Ryan Holtz,ImJezze
//-----------------------------------------------------------------------------
// Deconvergence Effect
//-----------------------------------------------------------------------------

layout(push_constant) uniform Push
{
	vec4 SourceSize;
	vec4 OriginalSize;
	vec4 OutputSize;
	uint FrameCount;
	float converge_x_r;
	float converge_x_g;
	float converge_x_b;
	float converge_y_r;
	float converge_y_g;
	float converge_y_b;
	float radial_conv_x_r;
	float radial_conv_x_g;
	float radial_conv_x_b;
	float radial_conv_y_r;
	float radial_conv_y_g;
	float radial_conv_y_b;
} params;

#pragma parameter converge_x_r "Convergence X Red" 0.0 -100.0 100.0 0.5
#pragma parameter converge_x_g "Convergence X Green" 0.0 -100.0 100.0 0.5
#pragma parameter converge_x_b "Convergence X Blue" 0.0 -100.0 100.0 0.5
#pragma parameter converge_y_r "Convergence Y Red" 0.0 -100.0 100.0 0.5
#pragma parameter converge_y_g "Convergence Y Green" 0.0 -100.0 100.0 0.5
#pragma parameter converge_y_b "Convergence Y Blue" 0.0 -100.0 100.0 0.5
#pragma parameter radial_conv_x_r "Radial Conv X Red" 0.0 -100.0 100.0 0.5
#pragma parameter radial_conv_x_g "Radial Conv X Green" 0.0 -100.0 100.0 0.5
#pragma parameter radial_conv_x_b "Radial Conv X Blue" 0.0 -100.0 100.0 0.5
#pragma parameter radial_conv_y_r "Radial Conv Y Red" 0.0 -100.0 100.0 0.5
#pragma parameter radial_conv_y_g "Radial Conv Y Green" 0.0 -100.0 100.0 0.5
#pragma parameter radial_conv_y_b "Radial Conv Y Blue" 0.0 -100.0 100.0 0.5

layout(std140, set = 0, binding = 0) uniform UBO
{
	mat4 MVP;
} global;

vec3 ConvergeX = vec3(params.converge_x_r, params.converge_x_g, params.converge_x_b);
vec3 ConvergeY = vec3(params.converge_y_r, params.converge_y_g, params.converge_y_b);
vec3 RadialConvergeX = vec3(params.radial_conv_x_r, params.radial_conv_x_g, params.radial_conv_x_b);
vec3 RadialConvergeY = vec3(params.radial_conv_y_r, params.radial_conv_y_g, params.radial_conv_y_b);

#pragma stage vertex
layout(location = 0) in vec4 Position;
layout(location = 1) in vec2 TexCoord;
layout(location = 0) out vec3 TexCoordX;
layout(location = 1) out vec3 TexCoordY;

void main()
{
   gl_Position = global.MVP * Position;

	// imaginary texel dimensions independed from screen dimension, but ratio
	vec2 TexelDims = vec2(1.0f / 1024.);

	TexCoordX = TexCoord.xxx;
	TexCoordY = TexCoord.yyy;

	// center coordinates
	TexCoordX -= 0.5f;
	TexCoordY -= 0.5f;

	// radial converge offset to "translate" the most outer pixel as thay would be translated by the linar converge with the same amount
	vec2 radialConvergeOffset = vec2(2.0);

	// radial converge
	TexCoordX *= 1.0f + RadialConvergeX * TexelDims.xxx * radialConvergeOffset.xxx;
	TexCoordY *= 1.0f + RadialConvergeY * TexelDims.yyy * radialConvergeOffset.yyy;

	// un-center coordinates
	TexCoordX += 0.5f;
	TexCoordY += 0.5f;

	// linear converge
	TexCoordX += ConvergeX * TexelDims.xxx;
	TexCoordY += ConvergeY * TexelDims.yyy;
}

#pragma stage fragment
layout(location = 0) in vec3 TexCoordX;
layout(location = 1) in vec3 TexCoordY;
layout(location = 0) out vec4 FragColor;
layout(set = 0, binding = 2) uniform sampler2D Source;

#define DiffuseSampler Source

void main()
{
	float r = texture(DiffuseSampler, vec2(TexCoordX.x, TexCoordY.x)).r;
	float g = texture(DiffuseSampler, vec2(TexCoordX.y, TexCoordY.y)).g;
	float b = texture(DiffuseSampler, vec2(TexCoordX.z, TexCoordY.z)).b;

	FragColor = vec4(r, g, b, 1.0);
}
