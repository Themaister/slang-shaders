#version 450

layout(push_constant) uniform Push
{
	vec4 SourceSize;
	vec4 OriginalSize;
	vec4 OutputSize;
	uint FrameCount;
	float MAP;
} params;

#pragma parameter MAP "Tone Map Method" 0.0 0.0 6.0 1.0
#define MAP params.MAP

layout(std140, set = 0, binding = 0) uniform UBO
{
	mat4 MVP;
} global;

/*
This shader experiments the effect of different tone mapping operators.
This is still a work in progress.
More info:
http://slideshare.net/ozlael/hable-john-uncharted2-hdr-lighting
http://filmicgames.com/archives/75
http://filmicgames.com/archives/183
http://filmicgames.com/archives/190
http://imdoingitwrong.wordpress.com/2010/08/19/why-reinhard-desaturates-my-blacks-3/
http://mynameismjp.wordpress.com/2010/04/30/a-closer-look-at-tone-mapping/
http://renderwonk.com/publications/s2010-color-course/
--
Zavie
*/

float gamma = 2.2;

vec3 linearToneMapping(vec3 color)
{
	float exposure = 1.;
	color = clamp(exposure * color, 0., 1.);
	color = pow(color, vec3(1. / gamma));
	return color;
}

vec3 simpleReinhardToneMapping(vec3 color)
{
	float exposure = 1.5;
	color *= exposure/(1. + color / exposure);
	color = pow(color, vec3(1. / gamma));
	return color;
}

vec3 lumaBasedReinhardToneMapping(vec3 color)
{
	float luma = dot(color, vec3(0.2126, 0.7152, 0.0722));
	float toneMappedLuma = luma / (1. + luma);
	color *= toneMappedLuma / luma;
	color = pow(color, vec3(1. / gamma));
	return color;
}

vec3 whitePreservingLumaBasedReinhardToneMapping(vec3 color)
{
	float white = 2.;
	float luma = dot(color, vec3(0.2126, 0.7152, 0.0722));
	float toneMappedLuma = luma * (1. + luma / (white*white)) / (1. + luma);
	color *= toneMappedLuma / luma;
	color = pow(color, vec3(1. / gamma));
	return color;
}

vec3 RomBinDaHouseToneMapping(vec3 color)
{
    color = exp( -1.0 / ( 2.72*color + 0.15 ) );
	color = pow(color, vec3(1. / gamma));
	return color;
}

vec3 filmicToneMapping(vec3 color)
{
	color = max(vec3(0.), color - vec3(0.004));
	color = (color * (6.2 * color + .5)) / (color * (6.2 * color + 1.7) + 0.06);
	return color;
}

vec3 Uncharted2ToneMapping(vec3 color)
{
	float A = 0.15;
	float B = 0.50;
	float C = 0.10;
	float D = 0.20;
	float E = 0.02;
	float F = 0.30;
	float W = 11.2;
	float exposure = 2.;
	color *= exposure;
	color = ((color * (A * color + C * B) + D * E) / (color * (A * color + B) + D * F)) - E / F;
	float white = ((W * (A * W + C * B) + D * E) / (W * (A * W + B) + D * F)) - E / F;
	color /= white;
	color = pow(color, vec3(1. / gamma));
	return color;
}

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

void main()
{
    vec3 color = COMPAT_TEXTURE(Texture, TEX0.xy).rgb;
if (MAP == 0.0) FragColor = vec4(linearToneMapping(color), 1.0);
if (MAP == 1.0) FragColor = vec4(simpleReinhardToneMapping(color), 1.0);
if (MAP == 2.0) FragColor = vec4(lumaBasedReinhardToneMapping(color), 1.0);
if (MAP == 3.0) FragColor = vec4(whitePreservingLumaBasedReinhardToneMapping(color), 1.0);
if (MAP == 4.0) FragColor = vec4(RomBinDaHouseToneMapping(color), 1.0);
if (MAP == 5.0) FragColor = vec4(filmicToneMapping(color), 1.0);
if (MAP == 6.0) FragColor = vec4(Uncharted2ToneMapping(color), 1.0);
}
