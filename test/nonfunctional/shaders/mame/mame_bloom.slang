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
} params;

#include "mame_parameters.inc"

float Level0Weight = global.level0weight;
float Level1Weight = global.level1weight;
float Level2Weight = global.level2weight;
float Level3Weight = global.level3weight;
float Level4Weight = global.level4weight;
float Level5Weight = global.level5weight;
float Level6Weight = global.level6weight;
float Level7Weight = global.level7weight;
float Level8Weight = global.level8weight;

int BloomBlendMode = int(global.bloomblendmode); // 0 brighten, 1 darken
float BloomScale = global.bloomscale;
vec3 BloomOverdrive = vec3(global.bloomoverdrive_r, global.bloomoverdrive_g, global.bloomoverdrive_b);

//-----------------------------------------------------------------------------
// Constants
//-----------------------------------------------------------------------------

const float E = 2.7182817f;
const float Gelfond = 23.140692f; // e^pi (Gelfond constant)
const float GelfondSchneider = 2.6651442f; // 2^sqrt(2) (Gelfond-Schneider constant)

//-----------------------------------------------------------------------------
// Functions
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
   gl_Position = global.MVP * Position;
   vTexCoord = TexCoord;
   BloomCoord = vTexCoord;
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
   if(!BloomToggle)
   {
      FragColor = texture(Source, vTexCoord);
      return;
   }
   else
   {
      vec3 texel = textureLod(DiffuseSampler, vTexCoord, 0.0).rgb;

      vec3 texelA = textureLod(BloomSamplerA, BloomCoord.xy, 1.0).rgb;
      vec3 texelB = textureLod(BloomSamplerB, BloomCoord.xy, 2.0).rgb;
      vec3 texelC = textureLod(BloomSamplerC, BloomCoord.xy, 3.0).rgb;
      vec3 texelD = textureLod(BloomSamplerD, BloomCoord.xy, 4.0).rgb;
      vec3 texelE = textureLod(BloomSamplerE, BloomCoord.xy, 5.0).rgb;
      vec3 texelF = textureLod(BloomSamplerF, BloomCoord.xy, 6.0).rgb;
      vec3 texelG = textureLod(BloomSamplerG, BloomCoord.xy, 7.0).rgb;
      vec3 texelH = textureLod(BloomSamplerH, BloomCoord.xy, 8.0).rgb;

      vec3 texelI = vec3(0.0f, 0.0f, 0.0f);
      vec3 texelJ = vec3(0.0f, 0.0f, 0.0f);
      vec3 texelK = vec3(0.0f, 0.0f, 0.0f);
      vec3 texelL = vec3(0.0f, 0.0f, 0.0f);
      vec3 texelM = vec3(0.0f, 0.0f, 0.0f);
      vec3 texelN = vec3(0.0f, 0.0f, 0.0f);
      vec3 texelO = vec3(0.0f, 0.0f, 0.0f);


      // vector screen uses twice -1 as many bloom levels
      if (VectorScreen)
      {
         texelI = textureLod(BloomSamplerI, BloomCoord.xy, 1.0).rgb;
         texelJ = textureLod(BloomSamplerJ, BloomCoord.xy, 1.0).rgb;
         texelK = textureLod(BloomSamplerK, BloomCoord.xy, 1.0).rgb;
         texelL = textureLod(BloomSamplerL, BloomCoord.xy, 1.0).rgb;
         texelM = textureLod(BloomSamplerM, BloomCoord.xy, 1.0).rgb;
         texelN = textureLod(BloomSamplerN, BloomCoord.xy, 1.0).rgb;
         texelO = textureLod(BloomSamplerO, BloomCoord.xy, 1.0).rgb;
      }

      vec3 blend;

      // brighten
      if (BloomBlendMode < 0.5)
      {
         vec3 bloom = vec3(0.0f, 0.0f, 0.0f);

         texel *= Level0Weight;

         if (VectorScreen)
         {
            bloom += texelA * Level1Weight;
            bloom += texelB * Level2Weight;
            bloom += texelC * Level3Weight;
            bloom += texelD * Level4Weight;
            bloom += texelE * Level5Weight;
            bloom += texelF * Level6Weight;
            bloom += texelG * Level7Weight;
            bloom += texelH * Level8Weight;
         }
         // vector screen uses twice -1 as many bloom levels
         else
         {
            bloom += texelA * (Level1Weight);
            bloom += texelB * (Level1Weight + Level2Weight) * 0.5f;
            bloom += texelC * (Level2Weight);
            bloom += texelD * (Level2Weight + Level3Weight) * 0.5f;
            bloom += texelE * (Level3Weight);
            bloom += texelF * (Level3Weight + Level4Weight) * 0.5f;
            bloom += texelG * (Level4Weight);
            bloom += texelH * (Level4Weight + Level5Weight) * 0.5f;
            bloom += texelI * (Level5Weight);
            bloom += texelJ * (Level5Weight + Level6Weight) * 0.5f;
            bloom += texelK * (Level6Weight);
            bloom += texelL * (Level6Weight + Level7Weight) * 0.5f;
            bloom += texelM * (Level7Weight);
            bloom += texelN * (Level7Weight + Level8Weight) * 0.5f;
            bloom += texelO * (Level8Weight);
         }

         bloom *= BloomScale;

         vec3 bloomOverdrive;
         bloomOverdrive.r = max(0.0f, texel.r + bloom.r - 1.0f) * BloomOverdrive.r;
         bloomOverdrive.g = max(0.0f, texel.g + bloom.g - 1.0f) * BloomOverdrive.g;
         bloomOverdrive.b = max(0.0f, texel.b + bloom.b - 1.0f) * BloomOverdrive.b;

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

         blend = texel * Level0Weight;
         blend = mix(blend, texelA, Level1Weight * BloomScale);
         blend = mix(blend, texelB, Level2Weight * BloomScale);
         blend = mix(blend, texelC, Level3Weight * BloomScale);
         blend = mix(blend, texelD, Level4Weight * BloomScale);
         blend = mix(blend, texelE, Level5Weight * BloomScale);
         blend = mix(blend, texelF, Level6Weight * BloomScale);
         blend = mix(blend, texelG, Level7Weight * BloomScale);
         blend = mix(blend, texelH, Level8Weight * BloomScale);
      }

       FragColor = vec4(blend, 1.0);
   }
}
