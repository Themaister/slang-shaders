#version 450

// NES PAL composite signal simulation for RetroArch
// shader by r57shell
// thanks to feos & HardWareMan & NewRisingSun

// also TV subpixels and scanlines

// LICENSE: PUBLIC DOMAIN

// NOTE: for nice TV subpixels and scanlines I recommend to
// disable this features here and apply CRT-specialized shader.

// Quality considerations

// there are three main options:
// USE_RAW (R), USE_DELAY_LINE (D), USE_COLORIMETRY (C)
// here is table of quality in decreasing order:
// RDC, RD, RC, DC, D, C

layout(push_constant) uniform Push
{
	vec4 SourceSize;
	vec4 OriginalSize;
	vec4 OutputSize;
	uint FrameCount;
} params;

// compatibility macros
#define float2 vec2
#define float3 vec3
#define float4 vec4
#define frac(c) fract(c)
#define saturate(c) clamp(c, 0.0, 1.0)
#define fmod(x,y) mod(x,y)
#define mul(x,y) (y*x)
#define float2x2 mat2
#define float3x3 mat3
#define float4x4 mat4
#define bool2 bvec2
#define bool3 bvec3
#define bool4 bvec4

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
   vTexCoord = TexCoord * 1.0001;;
}

#pragma stage fragment
layout(location = 0) in vec2 vTexCoord;
layout(location = 0) out vec4 FragColor;
layout(set = 0, binding = 2) uniform sampler2D Source;

// pos (left corner, sample size)
float4 monitor_sample(float2 p, float2 sample_)
{
	// linear interpolation was...
	// now other thing.
	// http://imgur.com/m8Z8trV
	// AT LAST IT WORKS!!!!
	// going to check in retroarch...
	float2 size = params.SourceSize.xy;
	float2 next = float2(.25,1.)/size;
	float2 f = frac(float2(4.,1.)*size*p);
	sample_ *= float2(4.,1.)*size;
	float2 l;
	float2 r;
	if (f.x+sample_.x < 1.)
	{
		l.x = f.x+sample_.x;
		r.x = 0.;
	}
	else
	{
		l.x = 1.-f.x;
		r.x = min(1.,f.x+sample_.x-1.);
	}
	if (f.y+sample_.y < 1.)
	{
		l.y = f.y+sample_.y;
		r.y = 0.;
	}
	else
	{
		l.y = 1.-f.y;
		r.y = min(1.,f.y+sample_.y-1.);
	}
	float3 top = mix(texture(Source, p).rgb, texture(Source, p+float2(next.x,0.)).rgb, r.x/(l.x+r.x));
	float3 bottom = mix(texture(Source, p+float2(0.,next.y)).rgb, texture(Source, p+next).rgb, r.x/(l.x+r.x));
	return float4(mix(top,bottom, r.y/(l.y+r.y)),1.0);
}

void main()
{
	FragColor = monitor_sample(vTexCoord, params.OutputSize.zw);
}