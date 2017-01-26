#version 450

layout(push_constant) uniform Push
{
	vec4 SourceSize;
	vec4 OriginalSize;
	vec4 OutputSize;
	uint FrameCount;
	float PHOSPHOR_SCALE_X;
	float PHOSPHOR_SCALE_Y;
} params;

#pragma parameter PHOSPHOR_SCALE_X "Phosphor Scale X" 2.0 1.0 12.0 1.0
#pragma parameter PHOSPHOR_SCALE_Y "Phosphor Scale Y" 4.0 1.0 12.0 1.0

#define PHOSPHOR_SCALE_X params.PHOSPHOR_SCALE_X
#define PHOSPHOR_SCALE_Y params.PHOSPHOR_SCALE_Y

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
layout(set = 0, binding = 3) uniform sampler2D Phosphors;
layout(set = 0, binding = 4) uniform sampler2D firstPass;

void main()
{
	vec4 screen = vec4(texture(firstPass, vTexCoord).rgb, 1.0);
	vec2 LUTeffectiveCoord = vec2(fract(vTexCoord.x * params.SourceSize.x / PHOSPHOR_SCALE_X), fract(vTexCoord.y * params.SourceSize.y / PHOSPHOR_SCALE_Y));
	vec4 phosphor_grid = vec4(texture(Phosphors, LUTeffectiveCoord).rgb, 1.0);
   FragColor = screen * phosphor_grid;
}