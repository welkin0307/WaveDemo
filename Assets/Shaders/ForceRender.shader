Shader "Reference/Partices/Template"
{
    Properties
    {
        //深度偏移
        _ZOffset                     ("粒子深度偏移",Range(-1.0, 1.0)) = 0
        
        //效果贴图
        _EffectTex                      ("效果贴图[t0]",2D) = "white"{}
        
        [Enum(R,0,G,1,B,2,A,3,White,4)]
        _ColorChannel                   ("颜色通道选项",Int) = 0
        
        [Toggle(_USE_MESHINFORMATION)]
        _UseMeshInformation             ("使用模型uv1和uv2上保存的颜色",Int) = 0
        _EffectCol                      ("效果颜色(不使用uv1、uv2的备选项)",Color) = (1,1,1,1)
        _ColorIntensity                 ("整体颜色强度", Range(0.0,25)) = 5  
        _OverlayColor                   ("叠加颜色",Color) = (1,1,1,1) 
        
        [Enum(R,0,G,1,B,2,A,3,White,4)]
        _AlphaChannel                   ("Alpha通道选项",Int) = 0
        _AlphaIntensity                 ("透明强度", Range(0.0,25)) = 1
        
        //调试选项
        [KeywordEnum(None,VertexColor,uv1,uv2)]
        _Debug                          ("调试选项",Int) = 0
        
        [Enum(RGBA,0,R,1,G,2,B,3,A,4)]
        _Debug_VertexColorChannel       ("调试选项-顶点色",Int) = 0
        
        [Enum(RGBA,0,R,1,G,2,B,3,A,4)]
        _Debug_UV1                      ("调试选项-第二套UV(uv1)",Int) = 0
        
        [Enum(RGBA,0,R,1,G,2,B,3,A,4)]
        _Debug_UV2                      ("调试选项-第三套UV(uv2)",Int) = 0
        
    }

    SubShader
    {
        Tags{"RenderType" = "Transparent" "RenderPipeline" = "UniversalPipeline" "Queue" = "Transparent" }

        Pass
        {
            Name "ForwardLit"
            Tags{"LightMode" = "UniversalForward"}

            Blend SrcAlpha OneMinusSrcAlpha
            ZWrite On
            Cull Off

            HLSLPROGRAM
            #pragma prefer_hlslcc gles
            #pragma target 3.0

            #pragma shader_feature_local _DEBUG_NONE _DEBUG_VERTEXCOLOR _DEBUG_UV1 _DEBUG_UV2
            #pragma shader_feature_local _USE_MESHINFORMATION
            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing

            #pragma vertex LitPassVertex
            #pragma fragment LitPassFragment

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceInput.hlsl"

            CBUFFER_START(UnityPerMaterial)
            float  _ZOffset;
            float4 _EffectTex_ST;
            half   _ColorChannel;
            half4  _EffectCol;
            half   _ColorIntensity;  
            half4  _OverlayColor;
            half   _AlphaChannel;
            half   _AlphaIntensity;
            //Debug选项
            half   _Debug_VertexColorChannel;
            half   _Debug_UV1;
            half   _Debug_UV2;
            CBUFFER_END

            TEXTURE2D(_EffectTex);        SAMPLER(sampler_EffectTex);

            struct Attributes
            {
                float4 positionOS   : POSITION;
                float4 color        : COLOR;
                float4 texcoord0    : TEXCOORD0;
            #if defined(_USE_MESHINFORMATION)
                float4 texcoord1    : TEXCOORD1;
                float4 texcoord2    : TEXCOORD2;
            #endif
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varyings
            {
                float4 uv0                       : TEXCOORD0;
                float4 uv1                       : TEXCOORD1;
                float4 uv2                       : TEXCOORD2;
                //float4 screenPos                 : TEXCOORD3;
                float4 vertexColor               : COLOR0;
                float4 positionCS                : SV_POSITION;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            Varyings LitPassVertex(Attributes input)
            {
                Varyings output = (Varyings)0;

                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_TRANSFER_INSTANCE_ID(input, output);

                VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);
                
                output.uv0 = input.texcoord0;

            #if defined(_USE_MESHINFORMATION) 
                output.uv1 = input.texcoord1;
                output.uv2 = input.texcoord2;
            #endif
                
                output.vertexColor = input.color;                

                //output.screenPos = ComputeScreenPos(vertexInput.positionCS);
                output.positionCS = vertexInput.positionCS;

                //粒子深度偏移
                output.positionCS.z = -_ZOffset*output.positionCS.w + output.positionCS.z;
                

                return output;
            }

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"

            half4 LitPassFragment(Varyings input) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(input);

                half4 output = 1;

                //采样效果贴图_EffectTex
                float2 uvEffectTex = input.uv0.xy*_EffectTex_ST.xy+_EffectTex_ST.zw;
                half4  effectTex = SAMPLE_TEXTURE2D(_EffectTex, sampler_EffectTex, uvEffectTex);

                half   colorChannel = 1;
                half4  colorSelection = (_ColorChannel == half4(0,1,2,3));
                
                colorChannel = colorSelection.w ? effectTex.a : colorChannel;
                colorChannel = colorSelection.z ? effectTex.b : colorChannel;
                colorChannel = colorSelection.y ? effectTex.g : colorChannel;
                colorChannel = colorSelection.x ? effectTex.r : colorChannel;

                #if defined(_USE_MESHINFORMATION)

                half3 effectCol = lerp(input.uv1.rgb, input.uv2.rgb, colorChannel);
                
                #else

                half3 effectCol = _EffectCol.rgb;
                
                #endif

                output.rgb = effectCol.rgb*input.vertexColor.rgb*_OverlayColor.rgb*_ColorIntensity;

                half   alphaChannel = 1;
                half4  alphaSelection = (_AlphaChannel == half4(0,1,2,3));
                
                alphaChannel = alphaSelection.w ? effectTex.a : alphaChannel;
                alphaChannel = alphaSelection.z ? effectTex.b : alphaChannel;
                alphaChannel = alphaSelection.y ? effectTex.g : alphaChannel;
                alphaChannel = alphaSelection.x ? effectTex.r : alphaChannel;
                
                output.a   = saturate(alphaChannel*input.vertexColor.a*_AlphaIntensity);

                //output = colorChannel;

                //Debug部分----------------------------------------------------------------------------------------------
                #if defined(_DEBUG_VERTEXCOLOR)

                    half4  debugVertexColorChannel = input.vertexColor;
                    half4  debugVertexColorSelection = (_Debug_VertexColorChannel == half4(1,2,3,4));
                    
                    debugVertexColorChannel = debugVertexColorSelection.w ? half4(input.vertexColor.aaa,1) : debugVertexColorChannel;
                    debugVertexColorChannel = debugVertexColorSelection.z ? half4(input.vertexColor.bbb,1) : debugVertexColorChannel;
                    debugVertexColorChannel = debugVertexColorSelection.y ? half4(input.vertexColor.ggg,1) : debugVertexColorChannel;
                    debugVertexColorChannel = debugVertexColorSelection.x ? half4(input.vertexColor.rrr,1) : debugVertexColorChannel;
                    return debugVertexColorChannel;

                #elif defined(_DEBUG_UV1)
                    
                    #if defined(_USE_MESHINFORMATION)
                        half4  debugUV1Channel = input.uv1;
                        half4  debugUV1Selection = (_Debug_UV1 == half4(1,2,3,4));
                        
                        debugUV1Channel = debugUV1Selection.w ? half4(input.uv1.aaa,1) : debugUV1Channel;
                        debugUV1Channel = debugUV1Selection.z ? half4(input.uv1.bbb,1) : debugUV1Channel;
                        debugUV1Channel = debugUV1Selection.y ? half4(input.uv1.ggg,1) : debugUV1Channel;
                        debugUV1Channel = debugUV1Selection.x ? half4(input.uv1.rrr,1) : debugUV1Channel;
                        return debugUV1Channel;
                    #endif

                #elif defined(_DEBUG_UV2)

                    #if defined(_USE_MESHINFORMATION)
                        half4  debugUV2Channel = input.uv2;
                        half4  debugUV2Selection = (_Debug_UV2 == half4(1,2,3,4));
                        
                        debugUV2Channel = debugUV2Selection.w ? half4(input.uv2.aaa,1) : debugUV2Channel;
                        debugUV2Channel = debugUV2Selection.z ? half4(input.uv2.bbb,1) : debugUV2Channel;
                        debugUV2Channel = debugUV2Selection.y ? half4(input.uv2.ggg,1) : debugUV2Channel;
                        debugUV2Channel = debugUV2Selection.x ? half4(input.uv2.rrr,1) : debugUV2Channel;
                        return debugUV2Channel;
                    #endif

                #endif
                //------------------------------------------------------------------------------------------------------
              
                return output;
            }

            ENDHLSL
        }
    }
    
    FallBack "Hidden/Universal Render Pipeline/FallbackError"
}
