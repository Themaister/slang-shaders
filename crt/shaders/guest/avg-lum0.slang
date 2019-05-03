#version 450

// Avg. Luminance Smoothing 

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

void main()
{
   gl_Position = global.MVP * Position;
   vTexCoord = TexCoord;
}

#pragma stage fragment
layout(location = 0) in vec2 vTexCoord;
layout(location = 0) out vec4 FragColor;
layout(set = 0, binding = 2) uniform sampler2D OriginalHistory1;
layout(set = 0, binding = 3) uniform sampler2D OriginalHistory2;
layout(set = 0, binding = 4) uniform sampler2D OriginalHistory3;
layout(set = 0, binding = 5) uniform sampler2D OriginalHistory4;
layout(set = 0, binding = 6) uniform sampler2D OriginalHistory5;
layout(set = 0, binding = 7) uniform sampler2D OriginalHistory6;
layout(set = 0, binding = 8) uniform sampler2D OriginalHistory7;

#define PrevTexture OriginalHistory1
#define Prev1Texture OriginalHistory2
#define Prev2Texture OriginalHistory3
#define Prev3Texture OriginalHistory4
#define Prev4Texture OriginalHistory5
#define Prev5Texture OriginalHistory6
#define Prev6Texture OriginalHistory7

#define TEX0 vTexCoord
#define COMPAT_TEXTURE(c,d) texture(c,d)


void main()
{
	vec3 color  = COMPAT_TEXTURE(PrevTexture,  TEX0.xy).rgb;
	color+= COMPAT_TEXTURE(Prev6Texture, TEX0.xy).rgb;
	color+= COMPAT_TEXTURE(Prev5Texture, TEX0.xy).rgb;
	color+= COMPAT_TEXTURE(Prev4Texture, TEX0.xy).rgb;
	color+= COMPAT_TEXTURE(Prev3Texture, TEX0.xy).rgb;
	color+= COMPAT_TEXTURE(Prev2Texture, TEX0.xy).rgb;
	color+= COMPAT_TEXTURE(Prev1Texture, TEX0.xy).rgb;
	
	FragColor = vec4(color/7.0,1.0);
}