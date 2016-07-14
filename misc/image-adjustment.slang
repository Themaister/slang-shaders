#version 450

layout(std140, set = 0, binding = 0) uniform UBO
{
   mat4 MVP;
   vec4 OutputSize;
   vec4 OriginalSize;
   vec4 SourceSize;
} global;

#define overscan_percent_x 0.0         // crop width of image by X%; default is 0.0
#define overscan_percent_y 0.0         // crop height of image by X%; default is 0.0
#define saturation 1.0                 // color saturation; default 1.0
#define monitor_gamma 2.2              // gamma setting of your current display; LCD monitors typically have a gamma of 2.2
#define target_gamma 2.4               // the gamma you want the image to have; CRT TVs typically have a gamma of 2.4
#define contrast 1.0                   // image contrast; default 1.0
#define luminance 1.0                  // image luminance; default 1.0
#define bright_boost 0.0               // adds to the total brightness. Negative values decrease it; Use values between 1.0 (totally white) and -1.0 (totally black); default is 0.0
#define R 0.5//1.0
#define G 1.0
#define B 1.0
#define ZOOM 1.0
#define XPOS 0.0
#define YPOS 0.0
#define V_OSMASK 0.0
#define H_OSMASK 0.0

//   Image Adjustment
//   Author: hunterk
//   License: Public domain

#pragma stage vertex
layout(location = 0) in vec4 Position;
layout(location = 1) in vec2 TexCoord;
layout(location = 0) out vec2 vTexCoord;

void main()
{
   gl_Position = global.MVP * Position;
   vec2 shift = 0.5 * global.SourceSize.zw / global.SourceSize.xy;
   vec2 overscan_coord = ((TexCoord - shift) / ZOOM) * (1.0 - vec2(overscan_percent_x / 100.0, overscan_percent_y / 100.0)) + shift;
   vTexCoord = overscan_coord + vec2(XPOS, YPOS);
}

#pragma stage fragment
layout(location = 0) in vec2 vTexCoord;
layout(location = 0) out vec4 FragColor;
layout(set = 0, binding = 2) uniform sampler2D Source;

vec3 grayscale(vec3 col)
{
   // ATSC grayscale standard
   return vec3(dot(col, vec3(0.2126, 0.7152, 0.0722)));
}

void main()
{
vec2 fragcoord = vTexCoord.xy * (global.SourceSize.xy / global.SourceSize.zw);
   vec3 res = texture(Source, vTexCoord).rgb; // sample the texture
   vec3 gamma = vec3(monitor_gamma / target_gamma); // setup ratio of display's gamma vs desired gamma
   vec3 AvgLumin = vec3(0.5, 0.5, 0.5);
   vec3 intensity = grayscale(res); // find luminance
   vec3 satColor = mix(intensity, res, saturation); // apply saturation
   vec3 conColor = mix(AvgLumin, satColor, contrast);   // apply contrast
   conColor = pow(conColor, 1.0 / vec3(gamma)); // Apply gamma correction
   conColor = clamp(conColor * luminance, 0.0, 1.0); // apply luminance
   conColor += vec3(bright_boost); // apply brightboost
   conColor *= vec3(R, G, B);
if (fragcoord.y > V_OSMASK && fragcoord.y < (1.0 - V_OSMASK))
conColor = conColor;
else
conColor = vec3(0.0);

if (fragcoord.x > H_OSMASK && fragcoord.x < (1.0 - H_OSMASK))
conColor = conColor;
else
conColor = vec3(0.0);
   FragColor = vec4(fragcoord.x);//vec4(conColor, 1.0);
}