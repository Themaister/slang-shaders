#version 450

layout(std140, set = 0, binding = 0) uniform UBO
{
   mat4 MVP;
   vec4 OutputSize;
   vec4 OriginalSize;
   vec4 SourceSize;
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

#define PI 3.1415926535

float sinc(float x)
{
   return sin(x) / x;
}

float kernel(float x)
{
   x = max(abs(x) * PI, 0.0001);
   return sinc(x) * sinc(0.5 * x);
}

void main()
{
   float u = vTexCoord.x * global.SourceSize.x - 0.5;
   float a = fract(u);
   vec2 tex = vec2((floor(u) + 0.5) * global.SourceSize.z, vTexCoord.y);

#define TEX(x, y) textureLod(Source, tex + vec2(x * global.SourceSize.z, 0.0), 0.0).rgb

   vec3 color =
      kernel(a + 1.0) * TEX(-1, 0) +
      kernel(a      ) * TEX( 0, 0) +
      kernel(a - 1.0) * TEX( 1, 0) +
      kernel(a - 2.0) * TEX( 2, 0);

   FragColor = vec4(color, 1.0);
}
