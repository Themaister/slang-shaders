#include "ntsc-pass1-vertex.inc"
#define TWO_PHASE
#define COMPOSITE
#include "ntsc-param.inc"
#include "ntsc-rgbyuv.inc"

#pragma stage fragment
layout(location = 0) in vec2 vTexCoord;
layout(location = 0) out vec4 FragColor;
layout(set = 0, binding = 2) uniform sampler2D Source;

void main()
{
#include "ntsc-pass1-encode-demodulate.inc"
}
