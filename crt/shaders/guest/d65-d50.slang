#version 450

layout(push_constant) uniform Push
{
	vec4 SourceSize;
	vec4 OriginalSize;
	vec4 OutputSize;
	uint FrameCount;
	float WP;
} params;

#pragma parameter WP "D65 to D50 strength %" 0.0 -100.0 100.0 5.0 

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

const mat3 D65 = mat3 (
           0.5767309,  0.2973769,  0.0270343,
           0.1855540,  0.6273491,  0.0706872,
           0.1881852,  0.0752741,  0.9911085);

const mat3 D50 = mat3 (
           1.7552599, -0.5441336,  0.0063467,
          -0.4836786,  1.5068789, -0.0175761,
          -0.2530000,  0.0215528,  1.2256959);

void main()
{
	vec3 color = texture(Source, vTexCoord.xy).rgb;
	
	vec3 c65 = D65*color;
	vec3 c50 = D50*c65;
	
	float m = params.WP/100.0;
	
	color = (1.0-m)*color + m*c50;
	
	FragColor = vec4(color,1.0);
}