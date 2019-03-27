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

static float4 gl_Position;
static float4 Position;
static float2 vTexCoord;
static float2 TexCoord;

struct SPIRV_Cross_Input
{
    float4 Position : TEXCOORD0;
    float2 TexCoord : TEXCOORD1;
};

struct SPIRV_Cross_Output
{
    float2 vTexCoord : TEXCOORD0;
    float4 gl_Position : SV_Position;
};

static bool NTSCSignal;

void vert_main()
{
    NTSCSignal = params_ntscsignal != 0.0f;
    gl_Position = mul(Position, global_MVP);
    vTexCoord = TexCoord;
}

SPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)
{
    Position = stage_input.Position;
    TexCoord = stage_input.TexCoord;
    vert_main();
    SPIRV_Cross_Output stage_output;
    stage_output.gl_Position = gl_Position;
    stage_output.vTexCoord = vTexCoord;
    return stage_output;
}
