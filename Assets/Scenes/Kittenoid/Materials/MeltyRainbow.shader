Shader "Unlit/MeltyRainbow"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Bands("Bands", Float) = 4.0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            #define PI 3.14159265359
            float _Bands;
            float random(float2 st) {
                return frac(sin(dot(st.xy,
                    float2(12.9898, 78.233)))
                    * 43758.5453123);
            }

            float noise2(float2 st) {
                float2 i = floor(st);
                float2 f = frac(st);

                // Four corners in 2D of a tile
                float a = random(i);
                float b = random(i + float2(1.0, 0.0));
                float c = random(i + float2(0.0, 1.0));
                float d = random(i + float2(1.0, 1.0));

                // Smooth Interpolation
                // Cubic Hermine Curve.  Same as SmoothStep()
                float2 u = f * f * (3.0 - 2.0 * f);

                // lerp 4 corners percentages
                return lerp(a, b, u.x) +
                    (c - a) * u.y * (1.0 - u.x) +
                    (d - b) * u.x * u.y;
            }

            float f(float2 x) {
                float r = sqrt(x.x * x.x + x.y * x.y) + noise2(x + float2(_Time.y, _Time.y));
                float a = atan2(x.x, x.y);
                return r - 1.;
            }

            float2 grad(float2 x) {
                float2 h = float2(0.01, 0.0);
                return float2(f(x + h.xy) - f(x - h.xy),
                    f(x + h.yx) - f(x - h.yx)) / (2.0 * h.x);
            }

            float3 palette(float t) {
                float3 a = float3(0.7, 0.5, 0.9);
                float3 b = float3(0.5, 0.5, 0.5);
                float3 c = float3(1.0, 1.0, 1.0);
                float3 d = float3(0.00, 0.33, 0.67);
                return a + b * cos(2. * PI * (c * t + d));
            }

            float3 color(float2 x) {
                float v = f(x) * .8;
                float2 g = grad(x);
                float de = abs(v) / length(grad(x));
                float eps = .01;
                return palette(floor(v * _Bands - _Time.y) / 10.);
                //float3(floor(frac(v) * 2.),palette(frac(v)),0.0);
                //smoothstep(2.0 * eps, 1.0 * eps, de); //return abs(v);
            }

            fixed4 frag(v2f i) : SV_Target
            {
                float2 uv = i.uv;// i.uv.xy * 2 / i.uv_MainTex.xy - 1;
                uv *= 6;
                float3 c = color(uv);
                return float4(c, 1.0);
            }

            ENDCG
        }
    }
}
