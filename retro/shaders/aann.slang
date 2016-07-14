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

vec4 vpow(vec4 n, float e)
{
    return vec4(pow(n.x, e), pow(n.y, e), pow(n.z, e), pow(n.w, e));
}

vec4 getLQV(vec3 mine) {
    return vec4
    ( mine.r
    , mine.g
    , mine.b
    ,(mine.r + mine.g + mine.b)/3.0);
}

vec3 fromLQV(vec4 mine) {
    float f = mine.w/(mine.r + mine.g + mine.b)*3.0;
    return vec3(mine.rgb)*f;
}

vec3 percent(float ssize, float tsize, float coord) {
    float minfull = (coord*tsize - 0.5) /tsize*ssize;
    float maxfull = (coord*tsize + 0.5) /tsize*ssize;

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

void main()
{
    float cheapsrgb = 2.1;
    float gamma = 3.0;
    vec3 xstuff = percent(global.SourceSize.x, global.OutputSize.x, vTexCoord.x);
    vec3 ystuff = percent(global.SourceSize.y, global.OutputSize.y, vTexCoord.y);

    float xkeep = xstuff[0];
    float ykeep = ystuff[0];
    
    // get points to interpolate across, in linear rgb
    vec4 a = getLQV(vpow(texture(Source,vec2(xstuff[1],ystuff[1])), cheapsrgb).rgb);
    vec4 b = getLQV(vpow(texture(Source,vec2(xstuff[2],ystuff[1])), cheapsrgb).rgb);
    vec4 c = getLQV(vpow(texture(Source,vec2(xstuff[1],ystuff[2])), cheapsrgb).rgb);
    vec4 d = getLQV(vpow(texture(Source,vec2(xstuff[2],ystuff[2])), cheapsrgb).rgb);
    
    // use perceptual gamma for luminance component
    a.w = pow(a.w, 1.0/gamma);
    b.w = pow(b.w, 1.0/gamma);
    c.w = pow(c.w, 1.0/gamma);
    d.w = pow(d.w, 1.0/gamma);
    
    // interpolate
    vec4 gammaLQVresult =
        NOT(xkeep)*NOT(ykeep)*a +
        YES(xkeep)*NOT(ykeep)*b +
        NOT(xkeep)*YES(ykeep)*c +
        YES(xkeep)*YES(ykeep)*d;
    
    // change luminance gamma back to linear
    vec4 LQVresult = gammaLQVresult;
    LQVresult.w = pow(gammaLQVresult.w, gamma);
    
    // convert back to srgb; lqv -> lrgb -> srgb
    vec4 c1 = vpow(vec4(fromLQV(LQVresult), 1.0), 1.0/cheapsrgb);

   FragColor = vec4(c1);
}