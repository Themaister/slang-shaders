#version 450

layout(std140, set = 0, binding = 0) uniform UBO
{
   mat4 MVP;
   vec4 OutputSize;
   vec4 OriginalSize;
   vec4 SourceSize;
} global;

// AntiAliased Nearest Neighbor
// by jimbo1qaz and wareya
// Licensed MIT

// set to true to interpolate in sRGB instead of a pseudo-perceptual colorspace
#define NOGAMMA false
// set to true to compensate for 8px overscan masking
// Note: overscan compensation slightly alters (extremifies) the pixel aspect ratio of the game if said pixel aspect ratio is not exactly 1:1
#define MASKING false
// Do bilinear filtering instead of anti-aliased nearest neighbor filtering (used for debugging color)
#define BILINEAR false

// http://i.imgur.com/kzwZkVf.png

#define NOT(fl) (1-fl)
#define YES(fl) fl

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


// http://entropymine.com/imageworsener/srgbformula/
float srgb2linear(float srgb) {
    if(srgb > 0.0404482362771082)
        return pow(((srgb+0.055)/1.055), 2.4);
    else
        return srgb/12.92;
}

float linear2srgb(float linear) {
    if(linear > 0.00313066844250063)
        return pow(linear,1/2.4)*1.055-0.055;
    else
        return linear*12.92;
}

// https://www.w3.org/Graphics/Color/srgb22
#define RS 0.2126
#define GS 0.7152
#define BS 0.0722


vec3 rgb2vry(vec3 rgb) {
    if(NOGAMMA) return rgb;
    // https://en.wikipedia.org/wiki/Opponent_process
    float r = srgb2linear(rgb.r);
    float g = srgb2linear(rgb.g);
    float b = srgb2linear(rgb.b);
    // https://en.wikipedia.org/wiki/Lightness#Relationship_between_lightness.2C_value.2C_and_relative_luminance
    // "scientists eventually converged on a roughly cube-root curve"
    // CIE does the same thing.
    float V = pow(r*RS + g*GS + b*BS, 1.0/3);
    float R = r-g;
    float Y = (r+g)/2-b;
    return vec3(V,R,Y);
}
vec3 vry2rgb(vec3 vry) {
    if(NOGAMMA) return vry;
    // Magic.
    float r, g, b;
        float t = pow(vry.x, 3);
    r = linear2srgb(t + vry.y*(GS + BS/2) + vry.z*BS);
    g = linear2srgb(t - vry.y*(RS + BS/2) + vry.z*BS);
    b = linear2srgb(t + vry.y*(GS/2-RS/2) - vry.z*(RS+GS));
    return vec3(r,g,b);
}

vec3 vry_interp(vec3 first, vec3 second, float frac) {
    if(NOGAMMA) return first*NOT(frac) + second*YES(frac);
    // Because the chroma values were generated on linear light, but the luma must be interpolated in perceptual gamma (3)
    //   it can cause out-of-gamut oversaturated values, since the chroma field is not a fixed size as luma values change.
    // To compensate, we can "pull" the chroma interpolation path in the opposite way the luma path is curved.
    float new_luma = first.x*NOT(frac) + second.x*YES(frac);
    float linear_span = pow(second.x, 3) - pow(first.x, 3);
    if(linear_span == 0) linear_span = 1;
    float luma_fraction = (pow(new_luma, 3) - pow(first.x, 3)) / linear_span;
    return vec3(new_luma,
                first.y*NOT(luma_fraction) + second.y*YES(luma_fraction),
                first.z*NOT(luma_fraction) + second.z*YES(luma_fraction));
}

vec3 percent(float ssize, float tsize, float coord) {
    if(BILINEAR) tsize = ssize;
    float minfull = (coord*tsize - 0.5)/tsize*ssize;
    float maxfull = (coord*tsize + 0.5)/tsize*ssize;

    float realfull = floor(maxfull);

    if (minfull > realfull) {
        return vec3(1, (realfull+0.5)/ssize, (realfull+0.5)/ssize);
    }

    return vec3(
            (maxfull - realfull) / (maxfull - minfull),
            (realfull-0.5) / ssize,
            (realfull+0.5) / ssize
        );
}

void main() {
    vec2 viewportSize = global.OutputSize.xy;
    vec2 gameCoord = vTexCoord;
    if(MASKING) {
        float hscale = viewportSize.x/global.SourceSize.x;
        float vscale = viewportSize.y/global.SourceSize.y;
        viewportSize.x += hscale*16;
        viewportSize.y += vscale*16;
        gameCoord.x = (8+gameCoord.x*(global.SourceSize.x))/(global.SourceSize.x+16);
        gameCoord.y = (8+gameCoord.y*(global.SourceSize.y))/(global.SourceSize.y+16);
    }
    vec3 xstuff = percent(global.SourceSize.x, viewportSize.x, gameCoord.x);
    vec3 ystuff = percent(global.SourceSize.y, viewportSize.y, gameCoord.y);

    float xkeep = xstuff[0];
    float ykeep = ystuff[0];

    // get points to interpoflate across in pseudo-perceptual colorspace
    vec3 a = rgb2vry(texture(Source,vec2(xstuff[1],ystuff[1])).rgb);
    vec3 b = rgb2vry(texture(Source,vec2(xstuff[2],ystuff[1])).rgb);
    vec3 c = rgb2vry(texture(Source,vec2(xstuff[1],ystuff[2])).rgb);
    vec3 d = rgb2vry(texture(Source,vec2(xstuff[2],ystuff[2])).rgb);

    // interpolate
    vec3 x1 = vry_interp(a, b, xkeep);
    vec3 x2 = vry_interp(c, d, xkeep);
    vec3 result = vry_interp(x1, x2, ykeep);

    // convert back to sRGB and return
    FragColor = vec4(vry2rgb(result), 1);
}