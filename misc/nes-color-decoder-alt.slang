#version 450

/*
   NES NTSC Color Decoder shader
   Ported from Bisqwit's C++ NES Palette Generator
   https://forums.nesdev.com/viewtopic.php?p=85060#p85060

   Use with Nestopia or FCEUmm libretro cores with the palette set to 'raw'.
*/

layout(std140, set = 0, binding = 0) uniform UBO
{
   mat4 MVP;
   vec4 OutputSize;
   vec4 OriginalSize;
   vec4 SourceSize;
   uint FrameCount;
} global;

layout(push_constant) uniform Push
{
   float nes_saturation;
   float nes_hue_tweak;
   float nes_contrast;
   float nes_brightness;
   float nes_gamma;
} params;

#pragma parameter nes_saturation "Saturation" 1.0 0.0 5.0 0.05
#pragma parameter nes_hue_tweak "Hue" 0.0 -10.0 10.0 0.05
#pragma parameter nes_contrast "Contrast" 1.0 0.0 2.0 0.05
#pragma parameter nes_brightness "Brightness" 1.0 0.0 2.0 0.05
#pragma parameter nes_gamma "Gamma" 1.8 1.0 2.5 0.05

#define saturation params.nes_saturation
#define hue_tweak params.nes_hue_tweak
#define contrast params.nes_contrast
#define brightness params.nes_brightness
#define gamma params.nes_gamma

bool wave (int p, int color)
{
   return ((color + p + 8) % 12 < 6);
}

float gammafix (float f)
{
   return f < 0.0 ? 0.0 : pow(f, 2.2 / gamma);
}

vec3 MakeRGBColor(int emphasis, int level, int color)
{
   float y = 0.0;
   float i = 0.0;
   float q = 0.0;

   float r = 0.0;
   float g = 0.0;
   float b = 0.0;

   // Voltage levels, relative to synch voltage
   float black = 0.518;
   float white = 1.962;
   float attenuation = 0.746;
   const float levels[8] = float[] (   0.350 , 0.518, 0.962, 1.550,
                                       1.094, 1.506, 1.962, 1.962);
   
   float low  = levels[level + 4 * int(color == 0)];
   float high = levels[level + 4 * int(color < 13)];
   
   // Calculate the luma and chroma by emulating the relevant circuits:
   for(int p = 0; p < 12; p++) // 12 clock cycles per pixel.
   {
      // NES NTSC modulator (square wave between two voltage levels):
      float spot = wave(p, color) ? high : low;

      // De-emphasis bits attenuate a part of the signal:
      if ((bool(emphasis & 1) && wave(p, 12)) ||
          (bool(emphasis & 2) && wave(p, 4)) ||
          (bool(emphasis & 4) && wave(p, 8))) 
      {
          spot *= attenuation;
      }

      // Normalize:
      float v = (spot - black) / (white - black);

      // Ideal TV NTSC demodulator:
      // Apply contrast/brightness
      v = (v - 0.5) * contrast + 0.5;
      v *= (brightness / 12.0);

      y += v;
      i += v * cos((3.141592653 / 6.0) * (p + hue_tweak) );
      q += v * sin((3.141592653 / 6.0) * (p + hue_tweak) );

   }

   i *= saturation;
   q *= saturation;

   // Convert YIQ into RGB according to a commonly used conversion matrix.
   r = clamp((1.0 * gammafix(y +  0.956 * i +  0.621 * q)), 0, 1.0);
   g = clamp((1.0 * gammafix(y + -0.272 * i + -0.647 * q)), 0, 1.0);
   b = clamp((1.0 * gammafix(y + -1.105 * i +  1.702 * q)), 0, 1.0);

   return vec3(r,g,b);
}

#pragma stage vertex
layout(location = 0) in vec4 Position;
layout(location = 1) in vec2 TexCoord;
layout(location = 0) out vec2 vTexCoord;
layout(location = 1) out float colorPhase;

void main()
{
   gl_Position = global.MVP * Position;
   vTexCoord   = TexCoord;
}

#pragma stage fragment
layout(location = 0) in vec2 vTexCoord;
layout(location = 1) in float colorPhase;
layout(location = 0) out vec4 FragColor;
layout(set = 0, binding = 2) uniform sampler2D Source;

void main()
{
   vec4 c = texture(Source, vTexCoord.xy);

   // Extract the chroma, level, and emphasis from the normalized RGB triplet
   int color =    int(floor((c.r * 15.0) + 0.5));
   int level =    int(floor((c.g *  3.0) + 0.5));
   int emphasis = int(floor((c.b *  7.0) + 0.5));

   vec3 out_color = MakeRGBColor(emphasis, level, color);
   FragColor = vec4(out_color, 1.0);
}
