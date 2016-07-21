#version 450

layout(std140, set = 0, binding = 0) uniform UBO
{
    mat4 MVP;
    vec4 OutputSize;
    vec4 OriginalSize;
    vec4 SourceSize;
    vec4 PassOutputSize4;

} global;

#pragma stage vertex
layout(location = 0) in  vec4  Position;
layout(location = 1) in  vec2  TexCoord;
layout(location = 0) out vec2  vTexCoord;

void main()
{
    gl_Position = global.MVP * Position;
    vTexCoord   = TexCoord;
}

#pragma stage fragment
layout(location = 0) in  vec2  vTexCoord;
layout(location = 0) out vec4  FragColor;
layout(set = 0, binding = 1) uniform sampler2D Source;
layout(set = 0, binding = 2) uniform sampler2D PassOutput4;

// For debugging
#define BLOOM_ONLY 0

#define BLOOM_STRENGTH  0.45
#define OUTPUT_GAMMA    2.2

#define CRT_PASS PassOutput4

void main() 
{
    vec2 tex = floor(global.PassOutputSize4.xy * vTexCoord);
    tex      = (tex + 0.5) * global.PassOutputSize4.zw;

#if BLOOM_ONLY
    vec3 source = BLOOM_STRENGTH * texture(Source, tex).rgb;
#else

    /* TODO/FIXME - In slang, how do I get the equivalent of PASSPREV4.tex_coord? */
    vec3 source = 1.15 * texture(CRT_PASS, tex).rgb;
    vec3 bloom  = texture(Source, tex).rgb;
    source     += BLOOM_STRENGTH * bloom;
#endif
    FragColor = vec4(pow(clamp(source, 0.0, 1.0), vec3(1.0 / OUTPUT_GAMMA)), 1.0);
}
