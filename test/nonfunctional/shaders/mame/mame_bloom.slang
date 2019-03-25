#version 450

// license:BSD-3-Clause
// copyright-holders:Ryan Holtz,ImJezze
//-----------------------------------------------------------------------------
// Bloom Effect
//-----------------------------------------------------------------------------

layout(push_constant) uniform Push
{
	vec4 SourceSize;
	vec4 OutputSize;
	float BloomBlendMode;
	float VectorScreen;
	float BloomScale;
	float BloomOverdrive_r;
	float BloomOverdrive_g;
	float BloomOverdrive_b;
	float Level0Weight;
	float Level1Weight;
	float Level2Weight;
	float Level3Weight;
	float Level4Weight;
	float Level5Weight;
	float Level6Weight;
	float Level7Weight;
	float Level8Weight;
} params;

#pragma parameter BloomBlendMode "Bloom Blend Mode" 0.0 0.0 1.0 1.0
#pragma parameter VectorScreen "Vector Screen Mode" 0.0 0.0 1.0 1.0
#pragma parameter BloomScale "Bloom Scale" 1.0 0.0 4.0 0.1
#pragma parameter BloomOverdrive_r "Bloom Overdrive R" 1.0 0.0 1.0 0.01
#pragma parameter BloomOverdrive_g "Bloom Overdrive G" 1.0 0.0 1.0 0.01
#pragma parameter BloomOverdrive_b "Bloom Overdrive B" 1.0 0.0 1.0 0.01

#pragma parameter Level0Weight "Bloom Level 0 Weight" 1.0 0.0 1.0 0.01
#pragma parameter Level1Weight "Bloom Level 1 Weight" 0.64 0.0 1.0 0.01
#pragma parameter Level2Weight "Bloom Level 2 Weight" 0.32 0.0 1.0 0.01
#pragma parameter Level3Weight "Bloom Level 3 Weight" 0.16 0.0 1.0 0.01
#pragma parameter Level4Weight "Bloom Level 4 Weight" 0.08 0.0 1.0 0.01
#pragma parameter Level5Weight "Bloom Level 5 Weight" 0.06 0.0 1.0 0.01
#pragma parameter Level6Weight "Bloom Level 6 Weight" 0.04 0.0 1.0 0.01
#pragma parameter Level7Weight "Bloom Level 7 Weight" 0.02 0.0 1.0 0.01
#pragma parameter Level8Weight "Bloom Level 8 Weight" 0.01 0.0 1.0 0.01

layout(std140, set = 0, binding = 0) uniform UBO
{
	mat4 MVP;
} global;

//-----------------------------------------------------------------------------
// Constants
//-----------------------------------------------------------------------------

const float E = 2.7182817f;
const float Gelfond = 23.140692f; // e^pi (Gelfond constant)
const float GelfondSchneider = 2.6651442f; // 2^sqrt(2) (Gelfond-Schneider constant)

//-----------------------------------------------------------------------------
// Funcions
//-----------------------------------------------------------------------------

// www.stackoverflow.com/questions/5149544/can-i-generate-a-random-number-inside-a-pixel-shader/
float random(vec2 seed)
{
	// irrationals for pseudo randomness
	vec2 i = vec2(Gelfond, GelfondSchneider);

	return fract(cos(dot(seed, i)) * 123456.0f);
}

//-----------------------------------------------------------------------------
// Bloom Vertex Shader
//-----------------------------------------------------------------------------

#pragma stage vertex
layout(location = 0) in vec4 Position;
layout(location = 1) in vec2 TexCoord;
layout(location = 0) out vec2 vTexCoord;
layout(location = 1) out vec2 BloomCoord;

void main()
{
   vec4 bloomPos = vec4(Position.xyz, 1.0);
//   bloomPos.xy *= params.OutputSize.zw;
//   bloomPos.y = 1.0 - bloomPos.y; // flip y
//   bloomPos.xy -= 0.5f; // center
//   bloomPos.xy *= 2.0f; // zoom
   gl_Position = global.MVP * bloomPos; // using bloomPos just makes a black screen /shrug
   vTexCoord = TexCoord;
//   vTexCoord += 0.5f * params.OutputSize.zw; // half texel offset correction (DX9)
   BloomCoord = vTexCoord;
   BloomCoord += 0.5f * params.SourceSize.zw;
}

#pragma stage fragment
layout(location = 0) in vec2 vTexCoord;
layout(location = 1) in vec2 BloomCoord;
layout(location = 0) out vec4 FragColor;
layout(set = 0, binding = 2) uniform sampler2D Source;

#define DiffuseSampler Source

#define BloomSamplerA Source
#define BloomSamplerB Source
#define BloomSamplerC Source
#define BloomSamplerD Source
#define BloomSamplerE Source
#define BloomSamplerF Source
#define BloomSamplerG Source
#define BloomSamplerH Source

// vector screen uses twice -1 as many bloom levels
#define BloomSamplerI Source
#define BloomSamplerJ Source
#define BloomSamplerK Source
#define BloomSamplerL Source
#define BloomSamplerM Source
#define BloomSamplerN Source
#define BloomSamplerO Source

vec3 GetNoiseFactor(vec3 n, float random)
{
	// smaller n become more noisy
	vec3 NoiseFactor;
	NoiseFactor.x = 1.0f + random * max(0.0f, 0.25f * pow(E, -8. * n.x));
	NoiseFactor.y = 1.0f + random * max(0.0f, 0.25f * pow(E, -8. * n.y));
	NoiseFactor.z = 1.0f + random * max(0.0f, 0.25f * pow(E, -8. * n.z));
	return NoiseFactor;
}

void main()
{
	vec3 texel = texture(DiffuseSampler, vTexCoord).rgb;

	vec3 texelA = texture(BloomSamplerA, BloomCoord.xy).rgb;
	vec3 texelB = texture(BloomSamplerB, BloomCoord.xy).rgb;
	vec3 texelC = texture(BloomSamplerC, BloomCoord.xy).rgb;
	vec3 texelD = texture(BloomSamplerD, BloomCoord.xy).rgb;
	vec3 texelE = texture(BloomSamplerE, BloomCoord.xy).rgb;
	vec3 texelF = texture(BloomSamplerF, BloomCoord.xy).rgb;
	vec3 texelG = texture(BloomSamplerG, BloomCoord.xy).rgb;
	vec3 texelH = texture(BloomSamplerH, BloomCoord.xy).rgb;

	vec3 texelI = vec3(0.0f, 0.0f, 0.0f);
	vec3 texelJ = vec3(0.0f, 0.0f, 0.0f);
	vec3 texelK = vec3(0.0f, 0.0f, 0.0f);
	vec3 texelL = vec3(0.0f, 0.0f, 0.0f);
	vec3 texelM = vec3(0.0f, 0.0f, 0.0f);
	vec3 texelN = vec3(0.0f, 0.0f, 0.0f);
	vec3 texelO = vec3(0.0f, 0.0f, 0.0f);


	// vector screen uses twice -1 as many bloom levels
	if (params.VectorScreen > 0.5)
	{
		texelI = texture(BloomSamplerI, BloomCoord.xy).rgb;
		texelJ = texture(BloomSamplerJ, BloomCoord.xy).rgb;
		texelK = texture(BloomSamplerK, BloomCoord.xy).rgb;
		texelL = texture(BloomSamplerL, BloomCoord.xy).rgb;
		texelM = texture(BloomSamplerM, BloomCoord.xy).rgb;
		texelN = texture(BloomSamplerN, BloomCoord.xy).rgb;
		texelO = texture(BloomSamplerO, BloomCoord.xy).rgb;
	}

	vec3 blend;

	// brighten
	if (params.BloomBlendMode < 0.5)
	{
		vec3 bloom = vec3(0.0f, 0.0f, 0.0f);

		texel *= params.Level0Weight;

		if (params.VectorScreen < 0.5)
		{
			bloom += texelA * params.Level1Weight;
			bloom += texelB * params.Level2Weight;
			bloom += texelC * params.Level3Weight;
			bloom += texelD * params.Level4Weight;
			bloom += texelE * params.Level5Weight;
			bloom += texelF * params.Level6Weight;
			bloom += texelG * params.Level7Weight;
			bloom += texelH * params.Level8Weight;
		}
		// vector screen uses twice -1 as many bloom levels
		else
		{
			bloom += texelA * (params.Level1Weight);
			bloom += texelB * (params.Level1Weight + params.Level2Weight) * 0.5f;
			bloom += texelC * (params.Level2Weight);
			bloom += texelD * (params.Level2Weight + params.Level3Weight) * 0.5f;
			bloom += texelE * (params.Level3Weight);
			bloom += texelF * (params.Level3Weight + params.Level4Weight) * 0.5f;
			bloom += texelG * (params.Level4Weight);
			bloom += texelH * (params.Level4Weight + params.Level5Weight) * 0.5f;
			bloom += texelI * (params.Level5Weight);
			bloom += texelJ * (params.Level5Weight + params.Level6Weight) * 0.5f;
			bloom += texelK * (params.Level6Weight);
			bloom += texelL * (params.Level6Weight + params.Level7Weight) * 0.5f;
			bloom += texelM * (params.Level7Weight);
			bloom += texelN * (params.Level7Weight + params.Level8Weight) * 0.5f;
			bloom += texelO * (params.Level8Weight);
		}

		bloom *= params.BloomScale;

		vec3 bloomOverdrive;
		bloomOverdrive.r = max(0.0f, texel.r + bloom.r - 1.0f) * params.BloomOverdrive_r;
		bloomOverdrive.g = max(0.0f, texel.g + bloom.g - 1.0f) * params.BloomOverdrive_g;
		bloomOverdrive.b = max(0.0f, texel.b + bloom.b - 1.0f) * params.BloomOverdrive_b;

		bloom.r += bloomOverdrive.g * 0.5f;
		bloom.r += bloomOverdrive.b * 0.5f;
		bloom.g += bloomOverdrive.r * 0.5f;
		bloom.g += bloomOverdrive.b * 0.5f;
		bloom.b += bloomOverdrive.r * 0.5f;
		bloom.b += bloomOverdrive.g * 0.5f;

		vec2 NoiseCoord = vTexCoord;
		vec3 NoiseFactor = GetNoiseFactor(bloom, random(NoiseCoord));

		blend = texel + bloom * NoiseFactor;
	}

	// darken
	else
	{
		texelA = min(texel, texelA);
		texelB = min(texel, texelB);
		texelC = min(texel, texelC);
		texelD = min(texel, texelD);
		texelE = min(texel, texelE);
		texelF = min(texel, texelF);
		texelG = min(texel, texelG);
		texelH = min(texel, texelH);

		blend = texel * params.Level0Weight;
		blend = mix(blend, texelA, params.Level1Weight * params.BloomScale);
		blend = mix(blend, texelB, params.Level2Weight * params.BloomScale);
		blend = mix(blend, texelC, params.Level3Weight * params.BloomScale);
		blend = mix(blend, texelD, params.Level4Weight * params.BloomScale);
		blend = mix(blend, texelE, params.Level5Weight * params.BloomScale);
		blend = mix(blend, texelF, params.Level6Weight * params.BloomScale);
		blend = mix(blend, texelG, params.Level7Weight * params.BloomScale);
		blend = mix(blend, texelH, params.Level8Weight * params.BloomScale);
	}

    FragColor = vec4(blend, 1.0);
}
