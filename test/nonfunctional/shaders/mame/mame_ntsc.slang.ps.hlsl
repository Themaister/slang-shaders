cbuffer global : register(b0)
{
    row_major float4x4 global_MVP : packoffset(c0);
};
cbuffer params : register(b1)
{
    float4 params_SourceSize : packoffset(c0);
    float4 params_OriginalSize : packoffset(c1);
    float4 params_OutputSize : packoffset(c2);
    uint params_FrameCount : packoffset(c3);
    float params_avalue : packoffset(c3.y);
    float params_bvalue : packoffset(c3.z);
    float params_ccvalue : packoffset(c3.w);
    float params_ovalue : packoffset(c4);
    float params_pvalue : packoffset(c4.y);
    float params_scantime : packoffset(c4.z);
    float params_notchhalfwidth : packoffset(c4.w);
    float params_yfreqresponse : packoffset(c5);
    float params_ifreqresponse : packoffset(c5.y);
    float params_qfreqresponse : packoffset(c5.z);
    float params_signaloffset : packoffset(c5.w);
    float params_ntscsignal : packoffset(c6);
};
Texture2D<float4> Source : register(t2);
SamplerState _Source_sampler : register(s2);

static float4 FragColor;
static float2 vTexCoord;

struct SPIRV_Cross_Input
{
    float2 vTexCoord : TEXCOORD0;
};

struct SPIRV_Cross_Output
{
    float4 FragColor : SV_Target0;
};

static bool NTSCSignal;
static float AValue;
static float BValue;
static float CCValue;
static float OValue;
static float PValue;
static float ScanTime;
static float NotchHalfWidth;
static float YFreqResponse;
static float IFreqResponse;
static float QFreqResponse;
static float SignalOffset;

float4 GetCompositeYIQ(float2 coord)
{
    float2 PValueSourceTexel = float2(PValue / params_SourceSize.x, 0.0f);
    float2 C0 = coord + (PValueSourceTexel * 0.0f);
    float2 C1 = coord + (PValueSourceTexel * 0.25f);
    float2 C2 = coord + (PValueSourceTexel * 0.5f);
    float2 C3 = coord + (PValueSourceTexel * 0.75f);
    float4 Cx = float4(C0.x, C1.x, C2.x, C3.x);
    float4 Cy = float4(C0.y, C1.y, C2.y, C3.y);
    float4 Texel0 = Source.Sample(_Source_sampler, C0);
    float4 Texel1 = Source.Sample(_Source_sampler, C1);
    float4 Texel2 = Source.Sample(_Source_sampler, C2);
    float4 Texel3 = Source.Sample(_Source_sampler, C3);
    float4 HPosition = Cx;
    float4 VPosition = Cy;
    float4 Y = float4(dot(Texel0, float4(0.2989999949932098388671875f, 0.58700001239776611328125f, 0.114000000059604644775390625f, 0.0f)), dot(Texel1, float4(0.2989999949932098388671875f, 0.58700001239776611328125f, 0.114000000059604644775390625f, 0.0f)), dot(Texel2, float4(0.2989999949932098388671875f, 0.58700001239776611328125f, 0.114000000059604644775390625f, 0.0f)), dot(Texel3, float4(0.2989999949932098388671875f, 0.58700001239776611328125f, 0.114000000059604644775390625f, 0.0f)));
    float4 I = float4(dot(Texel0, float4(0.595715999603271484375f, -0.2744530141353607177734375f, -0.3212629854679107666015625f, 0.0f)), dot(Texel1, float4(0.595715999603271484375f, -0.2744530141353607177734375f, -0.3212629854679107666015625f, 0.0f)), dot(Texel2, float4(0.595715999603271484375f, -0.2744530141353607177734375f, -0.3212629854679107666015625f, 0.0f)), dot(Texel3, float4(0.595715999603271484375f, -0.2744530141353607177734375f, -0.3212629854679107666015625f, 0.0f)));
    float4 Q = float4(dot(Texel0, float4(0.211456000804901123046875f, -0.52259099483489990234375f, 0.311134994029998779296875f, 0.0f)), dot(Texel1, float4(0.211456000804901123046875f, -0.52259099483489990234375f, 0.311134994029998779296875f, 0.0f)), dot(Texel2, float4(0.211456000804901123046875f, -0.52259099483489990234375f, 0.311134994029998779296875f, 0.0f)), dot(Texel3, float4(0.211456000804901123046875f, -0.52259099483489990234375f, 0.311134994029998779296875f, 0.0f)));
    float W = (6.283185482025146484375f * CCValue) * ScanTime;
    float WoPI = W / 3.1415927410125732421875f;
    float HOffset = (BValue + SignalOffset) / WoPI;
    float VScale = (AValue * params_SourceSize.y) / WoPI;
    float4 T = (HPosition + HOffset.xxxx) + (VPosition * VScale);
    float4 TW = T * W;
    float4 CompositeYIQ = (Y + (I * cos(TW))) + (Q * sin(TW));
    return CompositeYIQ;
}

void frag_main()
{
    NTSCSignal = params_ntscsignal != 0.0f;
    AValue = params_avalue;
    BValue = params_bvalue;
    CCValue = params_ccvalue;
    OValue = params_ovalue;
    PValue = params_pvalue;
    ScanTime = params_scantime;
    NotchHalfWidth = params_notchhalfwidth;
    YFreqResponse = params_yfreqresponse;
    IFreqResponse = params_ifreqresponse;
    QFreqResponse = params_qfreqresponse;
    SignalOffset = params_signaloffset;
    if (!NTSCSignal)
    {
        FragColor = Source.Sample(_Source_sampler, vTexCoord);
        return;
    }
    else
    {
        float4 BaseTexel = Source.Sample(_Source_sampler, vTexCoord);
        float TimePerSample = ScanTime / (params_SourceSize.x * 4.0f);
        float Fc_y1 = (CCValue - NotchHalfWidth) * TimePerSample;
        float Fc_y2 = (CCValue + NotchHalfWidth) * TimePerSample;
        float Fc_y3 = YFreqResponse * TimePerSample;
        float Fc_i = IFreqResponse * TimePerSample;
        float Fc_q = QFreqResponse * TimePerSample;
        float Fc_i_2 = Fc_i * 2.0f;
        float Fc_q_2 = Fc_q * 2.0f;
        float Fc_y1_2 = Fc_y1 * 2.0f;
        float Fc_y2_2 = Fc_y2 * 2.0f;
        float Fc_y3_2 = Fc_y3 * 2.0f;
        float Fc_i_pi2 = Fc_i * 6.283185482025146484375f;
        float Fc_q_pi2 = Fc_q * 6.283185482025146484375f;
        float Fc_y1_pi2 = Fc_y1 * 6.283185482025146484375f;
        float Fc_y2_pi2 = Fc_y2 * 6.283185482025146484375f;
        float Fc_y3_pi2 = Fc_y3 * 6.283185482025146484375f;
        float PI2Length = 0.098174773156642913818359375f;
        float W = (6.283185482025146484375f * CCValue) * ScanTime;
        float WoPI = W / 3.1415927410125732421875f;
        float HOffset = (BValue + SignalOffset) / WoPI;
        float VScale = (AValue * params_SourceSize.y) / WoPI;
        float4 YAccum = 0.0f.xxxx;
        float4 IAccum = 0.0f.xxxx;
        float4 QAccum = 0.0f.xxxx;
        float4 Cy = vTexCoord.yyyy;
        float4 VPosition = Cy;
        for (float i = 0.0f; i < 64.0f; i += 4.0f)
        {
            float n = i - 32.0f;
            float4 n4 = n.xxxx + float4(0.0f, 1.0f, 2.0f, 3.0f);
            float4 Cx = vTexCoord.x.xxxx + ((n4 * 0.25f) / params_SourceSize.x.xxxx);
            float4 HPosition = Cx;
            float2 param = float2(Cx.x, Cy.x);
            float4 C = GetCompositeYIQ(param);
            float4 T = (HPosition + HOffset.xxxx) + (VPosition * VScale);
            float4 WT = (T * W) + OValue.xxxx;
            float4 SincKernel = 0.540000021457672119140625f.xxxx + (cos(n4 * PI2Length) * 0.4600000083446502685546875f);
            float4 SincYIn1 = n4 * Fc_y1_pi2;
            float4 SincYIn2 = n4 * Fc_y2_pi2;
            float4 SincYIn3 = n4 * Fc_y3_pi2;
            float4 SincIIn = n4 * Fc_i_pi2;
            float4 SincQIn = n4 * Fc_q_pi2;
            float _447;
            if (SincYIn1.x != 0.0f)
            {
                _447 = sin(SincYIn1.x) / SincYIn1.x;
            }
            else
            {
                _447 = 1.0f;
            }
            float4 SincY1;
            SincY1.x = _447;
            float _462;
            if (SincYIn1.y != 0.0f)
            {
                _462 = sin(SincYIn1.y) / SincYIn1.y;
            }
            else
            {
                _462 = 1.0f;
            }
            SincY1.y = _462;
            float _478;
            if (SincYIn1.z != 0.0f)
            {
                _478 = sin(SincYIn1.z) / SincYIn1.z;
            }
            else
            {
                _478 = 1.0f;
            }
            SincY1.z = _478;
            float _494;
            if (SincYIn1.w != 0.0f)
            {
                _494 = sin(SincYIn1.w) / SincYIn1.w;
            }
            else
            {
                _494 = 1.0f;
            }
            SincY1.w = _494;
            float _510;
            if (SincYIn2.x != 0.0f)
            {
                _510 = sin(SincYIn2.x) / SincYIn2.x;
            }
            else
            {
                _510 = 1.0f;
            }
            float4 SincY2;
            SincY2.x = _510;
            float _525;
            if (SincYIn2.y != 0.0f)
            {
                _525 = sin(SincYIn2.y) / SincYIn2.y;
            }
            else
            {
                _525 = 1.0f;
            }
            SincY2.y = _525;
            float _540;
            if (SincYIn2.z != 0.0f)
            {
                _540 = sin(SincYIn2.z) / SincYIn2.z;
            }
            else
            {
                _540 = 1.0f;
            }
            SincY2.z = _540;
            float _555;
            if (SincYIn2.w != 0.0f)
            {
                _555 = sin(SincYIn2.w) / SincYIn2.w;
            }
            else
            {
                _555 = 1.0f;
            }
            SincY2.w = _555;
            float _571;
            if (SincYIn3.x != 0.0f)
            {
                _571 = sin(SincYIn3.x) / SincYIn3.x;
            }
            else
            {
                _571 = 1.0f;
            }
            float4 SincY3;
            SincY3.x = _571;
            float _586;
            if (SincYIn3.y != 0.0f)
            {
                _586 = sin(SincYIn3.y) / SincYIn3.y;
            }
            else
            {
                _586 = 1.0f;
            }
            SincY3.y = _586;
            float _601;
            if (SincYIn3.z != 0.0f)
            {
                _601 = sin(SincYIn3.z) / SincYIn3.z;
            }
            else
            {
                _601 = 1.0f;
            }
            SincY3.z = _601;
            float _616;
            if (SincYIn3.w != 0.0f)
            {
                _616 = sin(SincYIn3.w) / SincYIn3.w;
            }
            else
            {
                _616 = 1.0f;
            }
            SincY3.w = _616;
            float4 IdealY = ((SincY1 * Fc_y1_2) - (SincY2 * Fc_y2_2)) + (SincY3 * Fc_y3_2);
            float _641 = Fc_i_2;
            float _645;
            if (SincIIn.x != 0.0f)
            {
                _645 = sin(SincIIn.x) / SincIIn.x;
            }
            else
            {
                _645 = 1.0f;
            }
            float4 IdealI;
            IdealI.x = _641 * _645;
            float _658 = Fc_i_2;
            float _662;
            if (SincIIn.y != 0.0f)
            {
                _662 = sin(SincIIn.y) / SincIIn.y;
            }
            else
            {
                _662 = 1.0f;
            }
            IdealI.y = _658 * _662;
            float _675 = Fc_i_2;
            float _679;
            if (SincIIn.z != 0.0f)
            {
                _679 = sin(SincIIn.z) / SincIIn.z;
            }
            else
            {
                _679 = 1.0f;
            }
            IdealI.z = _675 * _679;
            float _692 = Fc_i_2;
            float _696;
            if (SincIIn.w != 0.0f)
            {
                _696 = sin(SincIIn.w) / SincIIn.w;
            }
            else
            {
                _696 = 1.0f;
            }
            IdealI.w = _692 * _696;
            float _710 = Fc_q_2;
            float _714;
            if (SincQIn.x != 0.0f)
            {
                _714 = sin(SincQIn.x) / SincQIn.x;
            }
            else
            {
                _714 = 1.0f;
            }
            float4 IdealQ;
            IdealQ.x = _710 * _714;
            float _727 = Fc_q_2;
            float _731;
            if (SincQIn.y != 0.0f)
            {
                _731 = sin(SincQIn.y) / SincQIn.y;
            }
            else
            {
                _731 = 1.0f;
            }
            IdealQ.y = _727 * _731;
            float _744 = Fc_q_2;
            float _748;
            if (SincQIn.z != 0.0f)
            {
                _748 = sin(SincQIn.z) / SincQIn.z;
            }
            else
            {
                _748 = 1.0f;
            }
            IdealQ.z = _744 * _748;
            float _761 = Fc_q_2;
            float _765;
            if (SincQIn.w != 0.0f)
            {
                _765 = sin(SincQIn.w) / SincQIn.w;
            }
            else
            {
                _765 = 1.0f;
            }
            IdealQ.w = _761 * _765;
            float4 FilterY = SincKernel * IdealY;
            float4 FilterI = SincKernel * IdealI;
            float4 FilterQ = SincKernel * IdealQ;
            YAccum += (C * FilterY);
            IAccum += ((C * cos(WT)) * FilterI);
            QAccum += ((C * sin(WT)) * FilterQ);
        }
        float3 YIQ = float3(((YAccum.x + YAccum.y) + YAccum.z) + YAccum.w, (((IAccum.x + IAccum.y) + IAccum.z) + IAccum.w) * 2.0f, (((QAccum.x + QAccum.y) + QAccum.z) + QAccum.w) * 2.0f);
        float3 RGB = float3(dot(YIQ, float3(1.0f, 0.95599997043609619140625f, 0.620999991893768310546875f)), dot(YIQ, float3(1.0f, -0.272000014781951904296875f, -0.647000014781951904296875f)), dot(YIQ, float3(1.0f, -1.10599994659423828125f, 1.70299994945526123046875f)));
        FragColor = float4(RGB, BaseTexel.w);
    }
}

SPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)
{
    vTexCoord = stage_input.vTexCoord;
    frag_main();
    SPIRV_Cross_Output stage_output;
    stage_output.FragColor = FragColor;
    return stage_output;
}
