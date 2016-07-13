#include "ntsc-pass2-vertex.inc"
#include "ntsc-decode-filter-2phase.inc"
#include "ntsc-rgbyuv.inc"

#define fetch_offset(offset, one_x) \
   texture(Source, vTexCoord + vec2((offset) * (one_x), 0.0)).xyz

#pragma stage fragment
layout(location = 0) in vec2 vTexCoord;
layout(location = 0) out vec4 FragColor;
layout(set = 0, binding = 2) uniform sampler2D Source;

void main()
{
#include "ntsc-pass2-decode.inc"
vec3 rgb = yiq2rgb(signal);
return vec4(rgb, 1.0);
}
