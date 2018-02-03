#version 450

/*
   GBC Color Correction Shader
   A shader that replicates the LCD dynamics from a Game Boy Color
   Color values are derived from Gambatte's color correction implementation.

   Based on Color Mangler
   Author: hunterk
   License: Public domain
*/

layout(std140, set = 0, binding = 0) uniform UBO
{
   mat4 MVP;
   vec4 OutputSize;
   vec4 OriginalSize;
   vec4 SourceSize;
} global;

#define blr 0.0
#define blg 0.0
#define blb 0.0
#define r 0.78824
#define g 0.72941
#define b 0.66667
#define rg 0.00
#define rb 0.18039
#define gr 0.12157
#define gb 0.12157
#define br 0.05882
#define bg 0.24314

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
   vec4 screen = texture(Source, vTexCoord);
   
   //                r   g    b   black
   mat4 color = mat4(r,  rg,  rb, 0.0,       //red channel
                     gr,  g,   gb, 0.0,      //green channel
                     br,  bg,  b,  0.0,      //blue channel
                     blr, blg, blb,    0.0); //alpha channel; these numbers do nothing for our purposes.
                 
   screen = color * screen;
   FragColor = screen;
}