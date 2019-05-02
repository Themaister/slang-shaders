#version 450

// white point adjustment
// by hunterk
// based on blog post by Tanner Helland
// http://www.tannerhelland.com/4435/convert-temperature-rgb-algorithm-code/

layout(push_constant) uniform Push
{
	vec4 SourceSize;
	vec4 OriginalSize;
	vec4 OutputSize;
	uint FrameCount;
   float temperature;
   float luma_preserve;
   float wp_red;
   float wp_green;
   float wp_blue;
} params;

#pragma parameter temperature "White Point" 6500.0 0.0 12000.0 100.0
#pragma parameter luma_preserve "Preserve Luminance" 1.0 0.0 1.0 1.0
#pragma parameter wp_red "Red Shift" 0.0 -1.0 1.0 0.01
#pragma parameter wp_green "Green Shift" 0.0 -1.0 1.0 0.01
#pragma parameter wp_blue "Blue Shift" 0.0 -1.0 1.0 0.01

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
   vTexCoord = TexCoord;
}

#pragma stage fragment
layout(location = 0) in vec2 vTexCoord;
layout(location = 0) out vec4 FragColor;
layout(set = 0, binding = 2) uniform sampler2D Source;

// white point adjustment
// based on blog post by Tanner Helland
// http://www.tannerhelland.com/4435/convert-temperature-rgb-algorithm-code/
vec3 wp_adjust(vec3 color){
   const float target_white_point = 9300.0;
   const mat3 RGBtoYIQ = mat3(
      0.2989, 0.5870, 0.1140,
      0.5959, -0.2744, -0.3216,
      0.2115, -0.5229, 0.3114);

   const mat3 YIQtoRGB = mat3(
      1.0, 0.956, 0.6210,
      1.0, -0.2720, -0.6474,
      1.0, -1.1060, 1.7046);

   float temp = params.temperature / 100.0;
   
   // all calculations assume a scale of 255. We'll normalize this at the end
   vec3 wp = vec3(255.);
   
   // calculate RED
   wp.r = (temp <= 66.) ? 255. : 329.698727446 * pow((temp - 60.), -0.1332047592);
   
   // calculate GREEN
   wp.g = (temp <= 66.) ? 99.4708025861 * log(temp) - 161.1195681661 : 288.1221695283 * pow((temp - 60.), -0.0755148492);
   
   // calculate BLUE
   wp.b = (temp >= 66.) ? 255. : (temp <= 19.) ? 0. : 138.5177312231 * log(temp - 10.) - 305.0447927307;
   
   // clamp and normalize
   wp.rgb = clamp(wp.rgb, vec3(0.), vec3(255.)) / vec3(255.);
   
   // this is dumb, but various cores don't always show white as white. Use this to make white white...
   wp.rgb += vec3(params.wp_red, params.wp_green, params.wp_blue);
   
   // apply transformation
   vec3 adjusted = (color * wp);
   vec3 base_luma = color * RGBtoYIQ;
   vec3 adjusted_luma = adjusted * RGBtoYIQ;
   adjusted = (params.luma_preserve > 0.5) ? adjusted_luma + (vec3(base_luma.r,0.,0.) - vec3(adjusted_luma.r,0.,0.)) : adjusted_luma;
   
   return adjusted * YIQtoRGB;
}

void main()
{
   FragColor = vec4(wp_adjust(texture(Source, vTexCoord).rgb), 1.0);
}