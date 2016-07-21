#version 450

layout(std140, set = 0, binding = 0) uniform UBO
{
   mat4 MVP;
   vec4 OutputSize;
   vec4 OriginalSize;
   vec4 SourceSize;
} global;

#define RSUBPIX_R 1.0
#define RSUBPIX_G 0.0
#define RSUBPIX_B 0.0
#define GSUBPIX_R 0.0
#define GSUBPIX_G 1.0
#define GSUBPIX_B 0.0
#define BSUBPIX_R 0.0
#define BSUBPIX_G 0.0
#define BSUBPIX_B 1.0
#define gain 1.0
#define gamma 3.0
#define blacklevel 0.05
#define ambient 0.0
#define BGR 0.0

#define outgamma 2.2

#define fetch_offset(coord,offset) (pow(vec3(gain) * texelFetchOffset(Source, (coord), 0, (offset)).rgb + vec3(blacklevel), vec3(gamma)) + vec3(ambient))

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

// integral of (1 - x^2 - x^4 + x^6)^2
float coeffs_x[] = float[](1.0, -2.0/3.0, -1.0/5.0, 4.0/7.0, -1.0/9.0, -2.0/11.0, 1.0/13.0);
// integral of (1 - 2x^4 + x^6)^2
float coeffs_y[] = float[](1.0,      0.0, -4.0/5.0, 2.0/7.0,  4.0/9.0, -4.0/11.0, 1.0/13.0);

float intsmear_func(float z, float coeffs[7])
{
  float z2 = z*z;
  float zn = z;
  float ret = 0.0;
  for (int i = 0; i < 7; i++) {
    ret += zn*coeffs[i];
    zn *= z2;
  }
  return ret;
}

float intsmear(float x, float dx, float d, float coeffs[7])
{
  float zl = clamp((x-dx*0.5)/d,-1.0,1.0);
  float zh = clamp((x+dx*0.5)/d,-1.0,1.0);
  return d * ( intsmear_func(zh,coeffs) - intsmear_func(zl,coeffs) )/dx;
}

void main()
{
  vec2 texelSize = global.SourceSize.zw;
  vec2 range;
  range = global.SourceSize.xy / (global.OutputSize.xy * global.SourceSize.xy);
  
  vec3 cred   = pow(vec3(RSUBPIX_R, RSUBPIX_G, RSUBPIX_B), vec3(outgamma));
  vec3 cgreen = pow(vec3(GSUBPIX_R, GSUBPIX_G, GSUBPIX_B), vec3(outgamma));
  vec3 cblue  = pow(vec3(BSUBPIX_R, BSUBPIX_G, BSUBPIX_B), vec3(outgamma));

  ivec2 tli = ivec2(floor(vTexCoord/texelSize-vec2(0.4999)));
  
  vec3 lcol, rcol;
  float subpix = (vTexCoord.x/texelSize.x - 0.4999 - float(tli.x))*3.0;
  float rsubpix = range.x/texelSize.x * 3.0;
  
  lcol = vec3(intsmear(subpix+1.0,rsubpix, 1.5, coeffs_x),
              intsmear(subpix    ,rsubpix, 1.5, coeffs_x),
              intsmear(subpix-1.0,rsubpix, 1.5, coeffs_x));
  rcol = vec3(intsmear(subpix-2.0,rsubpix, 1.5, coeffs_x),
              intsmear(subpix-3.0,rsubpix, 1.5, coeffs_x),
              intsmear(subpix-4.0,rsubpix, 1.5, coeffs_x));
			  
  if (BGR > 0.5) {
    lcol.rgb = lcol.bgr;
    rcol.rgb = rcol.bgr;
  }
  
  float tcol, bcol;
  subpix = vTexCoord.y/texelSize.y - 0.4999 - float(tli.y);
  rsubpix = range.y/texelSize.y;
  tcol = intsmear(subpix    ,rsubpix, 0.63, coeffs_y);
  bcol = intsmear(subpix-1.0,rsubpix, 0.63, coeffs_y);
  
  vec3 topLeftColor     = fetch_offset(tli, ivec2(0,0)) * lcol * vec3(tcol);
  vec3 bottomRightColor = fetch_offset(tli, ivec2(1,1)) * rcol * vec3(bcol);
  vec3 bottomLeftColor  = fetch_offset(tli, ivec2(0,1)) * lcol * vec3(bcol);
  vec3 topRightColor    = fetch_offset(tli, ivec2(1,0)) * rcol * vec3(tcol);
  
  vec3 averageColor = topLeftColor + bottomRightColor + bottomLeftColor + topRightColor;

  averageColor = averageColor * mat3(cred, cgreen, cblue);
  
   FragColor = vec4(pow(averageColor,vec3(1.0/outgamma)),0.0);
}