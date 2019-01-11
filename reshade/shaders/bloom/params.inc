layout(std140, set = 0, binding = 0) uniform UBO
{
   mat4 MVP;
   float iBloomMixmode;
   float fBloomThreshold;
   float fBloomAmount;
   float fBloomSaturation;
   float fBloomTint_r;
   float fBloomTint_g;
   float fBloomTint_b;
   float bLensdirtEnable;
   float iLensdirtMixmode;
   float fLensdirtIntensity;
   float fLensdirtSaturation;
   float fLensdirtTint_r;
   float fLensdirtTint_g;
   float fLensdirtTint_b;
   float bAnamFlareEnable;
   float fAnamFlareThreshold;
   float fAnamFlareWideness;
   float fAnamFlareAmount;
   float fAnamFlareCurve;
   float fAnamFlareColor_r;
   float fAnamFlareColor_g;
   float fAnamFlareColor_b;
   float bLenzEnable;
   float fLenzIntensity;
   float fLenzThreshold;
   float bChapFlareEnable;
   float fChapFlareThreshold;
   float iChapFlareCount;
   float fChapFlareDispersal;
   float fChapFlareSize;
   float fChapFlareCA_r;
   float fChapFlareCA_g;
   float fChapFlareCA_b;
   float fChapFlareIntensity;
   float bGodrayEnable;
   float fGodrayDecay;
   float fGodrayExposure;
   float fGodrayWeight;
   float fGodrayDensity;
   float fGodrayThreshold;
   float iGodraySamples;
   float fFlareLuminance;
   float fFlareBlur;
   float fFlareIntensity;
   float fFlareTint_r;
   float fFlareTint_g;
   float fFlareTint_b;
} global;

#pragma parameter iBloomMixmode "Bloom Mix Mode" 0.0 0.0 2.0 1.0
#pragma parameter fBloomThreshold "Bloom Threshold" 0.8 0.1 1.0 0.1
#pragma parameter fBloomAmount "Bloom Amount" 0.8 0.0 20.0 0.1
#pragma parameter fBloomSaturation "Bloom Saturation" 0.8 0.0 2.0 0.1
#pragma parameter fBloomTint_r "Bloom Tint R" 0.7 0.0 1.0 0.05
#pragma parameter fBloomTint_g "Bloom Tint G" 0.8 0.0 1.0 0.05
#pragma parameter fBloomTint_b "Bloom Tint B" 1.0 0.0 1.0 0.05
#pragma parameter bLensdirtEnable "Lens Dirt Enable" 0.0 0.0 1.0 1.0
#pragma parameter iLensdirtMixmode "Lens Dirt Mix Mode" 0.0 0.0 3.0 1.0
#pragma parameter fLensdirtIntensity "Lens Dirt Intensity" 0.4 0.0 2.0 0.1
#pragma parameter fLensdirtSaturation "Lens Dirt Saturation" 2.0 0.0 2.0 0.1
#pragma parameter fLensdirtTint_r "Lens Dirt Tint R" 1.0 0.0 1.0 0.05
#pragma parameter fLensdirtTint_g "Lens Dirt Tint G" 1.0 0.0 1.0 0.05
#pragma parameter fLensdirtTint_b "Lens Dirt Tint B" 1.0 0.0 1.0 0.05
#pragma parameter bAnamFlareEnable "Anam Flare Enable" 0.0 0.0 1.0 1.0
#pragma parameter fAnamFlareThreshold "Anam Flare Threshold" 0.9 0.1 1.0 0.1
#pragma parameter fAnamFlareWideness "Anam Flare Width" 2.4 1.0 2.5 0.1
#pragma parameter fAnamFlareAmount "Anam Flare Amt" 14.5 1.0 20.0 0.5
#pragma parameter fAnamFlareCurve "Anam Flare Curve" 1.2 1.0 2.0 0.1
#pragma parameter fAnamFlareColor_r "Anam Flare Col R" 0.012 0.0 1.0 0.01
#pragma parameter fAnamFlareColor_g "Anam Flare Col G" 0.313 0.0 1.0 0.01
#pragma parameter fAnamFlareColor_b "Anam Flare Col B" 0.588 0.0 1.0 0.01
#pragma parameter bLenzEnable "Lenz Enable" 0.0 0.0 1.0 1.0
#pragma parameter fLenzIntensity "Lenz Intensity" 1.0 0.2 3.0 0.1
#pragma parameter fLenzThreshold "Lenz Threshold" 0.8 0.6 1.0 0.1
#pragma parameter bChapFlareEnable "Chap Flare Enable" 0.0 0.0 1.0 1.0
#pragma parameter fChapFlareThreshold "Chap Flare Threshold" 0.9 0.7 0.99 0.05
#pragma parameter iChapFlareCount "Chap Flare Count" 15.0 1.0 20.0 1.0
#pragma parameter fChapFlareDispersal "Chap Flare Dispersal" 0.25 0.25 1.0 0.05
#pragma parameter fChapFlareSize "Chap Flare Size" 0.45 0.2 0.8 0.05
#pragma parameter fChapFlareCA_r "Chap Flare CA R" 0.0 0.0 1.0 0.01
#pragma parameter fChapFlareCA_g "Chap Flare CA G" 0.01 0.0 1.0 0.01
#pragma parameter fChapFlareCA_b "Chap Flare CA B" 0.02 0.0 1.0 0.01
#pragma parameter fChapFlareIntensity "Chap Flare Intensity" 100.0 5.0 200.0 5.0
#pragma parameter bGodrayEnable "Godray Enable" 0.0 0.0 1.0 1.0
#pragma parameter fGodrayDecay "Godray Decay" 0.99 0.5 0.9999 0.05
#pragma parameter fGodrayExposure "Godray Exposure" 1.0 0.7 1.5 0.05
#pragma parameter fGodrayWeight "Godray Weight" 1.25 0.8 1.7 0.05
#pragma parameter fGodrayDensity "Godray Density" 1.0 0.2 2.0 0.2
#pragma parameter fGodrayThreshold "Godray Threshold" 0.9 0.6 1.0 0.05
#pragma parameter iGodraySamples "Godray Samples" 128.0 16.0 256.0 16.0
#pragma parameter fFlareLuminance "Flare Luminance" 0.095 0.0 1.0 0.005
#pragma parameter fFlareBlur "Flare Blur" 200.0 1.0 10000.0 50.0
#pragma parameter fFlareIntensity "Flare Intensity" 2.07 0.2 5.0 0.1
#pragma parameter fFlareTint_r "Flare Tint R" 0.137 0.0 1.0 0.05
#pragma parameter fFlareTint_g "Flare Tint G" 0.216 0.0 1.0 0.05
#pragma parameter fFlareTint_b "Flare Tint B" 1.0 0.0 1.0 0.05

vec3 fFlareTint = vec3(global.fFlareTint_r, global.fFlareTint_g, global.fFlareTint_b);
vec3 fAnamFlareColor = vec3(global.fAnamFlareColor_r, global.fAnamFlareColor_g, global.fAnamFlareColor_b);
vec3 fLensdirtTint = vec3(global.fLensdirtTint_r, global.fLensdirtTint_g, global.fLensdirtTint_b);
vec3 fBloomTint = vec3(global.fBloomTint_r, global.fBloomTint_g, global.fBloomTint_b);
vec3 fChapFlareCA = vec3(global.fChapFlareCA_r, global.fChapFlareCA_g, global.fChapFlareCA_b);

// If 1, only pixels with depth = 1 get lens flares
// This prevents white objects from getting lens flares sources, which would normally happen in LDR
#ifndef LENZ_DEPTH_CHECK
   #define LENZ_DEPTH_CHECK 0
#endif
#ifndef CHAPMAN_DEPTH_CHECK
   #define CHAPMAN_DEPTH_CHECK 0
#endif
#ifndef GODRAY_DEPTH_CHECK
   #define GODRAY_DEPTH_CHECK 0
#endif
#ifndef FLARE_DEPTH_CHECK
   #define FLARE_DEPTH_CHECK 0
#endif