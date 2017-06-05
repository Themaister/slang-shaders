#version 450

layout(push_constant) uniform Push
{
	vec4 SourceSize;
	vec4 OriginalSize;
	vec4 OutputSize;
	uint FrameCount;
	float LUT_Size;
} params;

#pragma parameter LUT_Size "LUT Size" 16.0 16.0 64.0 1.0

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
layout(set = 0, binding = 3) uniform sampler2D SamplerLUT;

void main()
{
	vec4 imgColor = pow(texture(Source, vTexCoord.xy), vec4(2.2));
    float red = ( imgColor.r * (params.LUT_Size - 1.0) + 0.5 ) / (params.LUT_Size * params.LUT_Size);
    float green = ( imgColor.g * (params.LUT_Size - 1.0) + 0.5 ) / params.LUT_Size;
    float blue = floor( imgColor.b  * (params.LUT_Size - 1.0) ) / params.LUT_Size;
    vec4 color = texture( SamplerLUT, vec2( blue + red, green ));
   FragColor = pow(color, vec4(1.0 / 2.2));
}
