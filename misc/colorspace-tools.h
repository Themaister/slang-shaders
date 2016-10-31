// Colorspace Tools
// ported from Asmodean's PsxFX Shader Suite v2.00
// NTSC color code from SimoneT
// License: GPL v2+

/*------------------------------------------------------------------------------
                       [GAMMA CORRECTION CODE SECTION]
------------------------------------------------------------------------------*/

vec3 EncodeGamma(vec3 color, float gamma)
{
    color = clamp(color, 0.0, 1.0);
    color.r = (color.r <= 0.0404482362771082) ?
    color.r / 12.92 : pow((color.r + 0.055) / 1.055, gamma);
    color.g = (color.g <= 0.0404482362771082) ?
    color.g / 12.92 : pow((color.g + 0.055) / 1.055, gamma);
    color.b = (color.b <= 0.0404482362771082) ?
    color.b / 12.92 : pow((color.b + 0.055) / 1.055, gamma);

    return color;
}

vec3 DecodeGamma(vec3 color, float gamma)
{
    color = clamp(color, 0.0, 1.0);
    color.r = (color.r <= 0.00313066844250063) ?
    color.r * 12.92 : 1.055 * pow(color.r, 1.0 / gamma) - 0.055;
    color.g = (color.g <= 0.00313066844250063) ?
    color.g * 12.92 : 1.055 * pow(color.g, 1.0 / gamma) - 0.055;
    color.b = (color.b <= 0.00313066844250063) ?
    color.b * 12.92 : 1.055 * pow(color.b, 1.0 / gamma) - 0.055;

    return color;
}

#ifdef GAMMA_CORRECTION
float4 GammaPass(float4 color, vec2 texcoord)
{
    const float GammaConst = 2.233333;
    color.rgb = EncodeGamma(color.rgb, GammaConst);
    color.rgb = DecodeGamma(color.rgb, float(Gamma));

    return color;
}
#endif

//Conversion matrices
vec3 RGBtoXYZ(vec3 RGB)
  {
      const mat3x3 m = mat3x3(
      0.6068909, 0.1735011, 0.2003480,
      0.2989164, 0.5865990, 0.1144845,
      0.0000000, 0.0660957, 1.1162243);
  
    return RGB * m;
  }
  
vec3 XYZtoRGB(vec3 XYZ)
  {
      const mat3x3 m = mat3x3(
      1.9099961, -0.5324542, -0.2882091,
     -0.9846663,  1.9991710, -0.0283082,
      0.0583056, -0.1183781,  0.8975535);
  
    return XYZ * m;
}

vec3 XYZtoSRGB(vec3 XYZ)
{
    const mat3x3 m = mat3x3(
    3.2404542,-1.5371385,-0.4985314,
   -0.9692660, 1.8760108, 0.0415560,
    0.0556434,-0.2040259, 1.0572252);

    return XYZ * m;
  }
  
  vec3 RGBtoYUV(vec3 RGB)
 {
     const mat3x3 m = mat3x3(
     0.2126, 0.7152, 0.0722,
    -0.09991,-0.33609, 0.436,
     0.615, -0.55861, -0.05639);
 
     return RGB * m;
 }
 
 vec3 YUVtoRGB(vec3 YUV)
 {
     const mat3x3 m = mat3x3(
     1.000, 0.000, 1.28033,
     1.000,-0.21482,-0.38059,
     1.000, 2.12798, 0.000);
 
      return YUV * m;
  }

vec3 RGBtoYIQ(vec3 RGB)
  {
     const mat3x3 m = mat3x3(
     0.2989, 0.5870, 0.1140,
     0.5959, -0.2744, -0.3216,
     0.2115, -0.5229, 0.3114);
     return RGB * m;
  }

vec3 YIQtoRGB(vec3 YIQ)
  {
     const mat3x3 m = mat3x3(
     1.0, 0.956, 0.6210,
     1.0, -0.2720, -0.6474,
     1.0, -1.1060, 1.7046);
   return YIQ * m;
  }
  
vec3 XYZtoYxy(vec3 XYZ)
  {
    float w = (XYZ.r + XYZ.g + XYZ.b);
      vec3 Yxy;
    Yxy.r = XYZ.g;
    Yxy.g = XYZ.r / w;
    Yxy.b = XYZ.g / w;
  
      return Yxy;
  }
  
  vec3 YxytoXYZ(vec3 Yxy)
  {
    vec3 XYZ;
    XYZ.g = Yxy.r;
    XYZ.r = Yxy.r * Yxy.g / Yxy.b;
    XYZ.b = Yxy.r * (1.0 - Yxy.g - Yxy.b) / Yxy.b;
  
    return XYZ;
  }

// conversion from NTSC RGB Reference White D65 ( color space used by NA/Japan TV's ) to XYZ
 vec3 NTSC(vec3 c)
 {
     vec3 v = vec3(pow(c.r, 2.2), pow(c.g, 2.2), pow(c.b, 2.2)); //Inverse Companding
     return RGBtoXYZ(v);
 }
 
 // conversion from XYZ to sRGB Reference White D65 ( color space used by windows ) 
 vec3 sRGB(vec3 c)
 {
     vec3 v = XYZtoSRGB(c);
     v = DecodeGamma(v, 2.4); //Companding
 
     return v;
 }
 
 // NTSC RGB to sRGB
 vec3 NTSCtoSRGB( vec3 c )
 { 
     return sRGB(NTSC( c )); 
 }
