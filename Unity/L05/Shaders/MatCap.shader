Shader "Custom/MatCap"
{
    Properties
    {
        _NormalMap("Normal Map",2D)="bump"{}
        _MatCap("Mat Cap",2D)="gray"{}
        _FresnelPow("Fre Pow",Range(0,5))=1
        _EnvSpecInt("Env Light Intensity",Range(0,5))=1
    }
    SubShader
    { 
        Tags { "RenderType"="Opaque" }

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            uniform sampler2D _NormalMap;
            uniform sampler2D _MatCap;
            uniform float _FresnelPow;
            uniform float _EnvSpecInt;

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float4 normal:NORMAL;
                float4 tangent:TANGENT;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 pos : SV_POSITION;
                float3 nDirWS:TEXCOORD1;
                float3 tDirWS:TEXCOORD2;
                float3 bDirWS:TEXCOORD3;
                float3 posWS:TEXCOORD4;
            };

            v2f vert (appdata v)
            {
                v2f o;

                o.pos = UnityObjectToClipPos(v.vertex);
                o.posWS=mul(unity_ObjectToWorld,v.vertex);
                o.uv = v.uv;
                o.nDirWS=UnityObjectToWorldNormal(v.normal);
                o.tDirWS=normalize(mul(unity_ObjectToWorld,float4(v.tangent.xyz,0.0)).xyz);
                o.bDirWS=normalize(cross(o.nDirWS,o.tDirWS)*v.tangent.w);
                return o;
            }

            fixed4 frag (v2f i) : COLOR
            {
                float3 nDirTS=UnpackNormal(tex2D(_NormalMap,i.uv));
                float3x3 TBN=float3x3(i.tDirWS,i.bDirWS,i.nDirWS);
                float3 nDirWS=normalize(mul(nDirTS,TBN));
                float3 nDirVS=mul(UNITY_MATRIX_V,float4(nDirWS,0.0));
                float3 vDirWS=normalize(_WorldSpaceCameraPos.xyz-i.posWS);
                float2 matcapUV=nDirVS.rg*0.5+0.5;
                float nDotv=dot(nDirWS,vDirWS);
                float3 matcap=tex2D(_MatCap,matcapUV);
                float fresnel=pow(1.0-nDotv,_FresnelPow);
                float3 envSpecLight=matcap*fresnel*_EnvSpecInt;
                return float4(envSpecLight,1.0);
            }
            ENDCG
        }
    }
}
