// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Effects/RayMarchShader"
{
	Properties
	{
		_Color("Color", Color) = (1,1,1,1)
		_MainTex ("Texture", 2D) = "white" {}
	}
	SubShader
	{
		Cull Off ZWrite Off ZTest Always
		Pass
		{
			Tags { "RenderType"="Opaque" }
			CGPROGRAM
	
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile __ DEBUG_PERFORMANCE
			#pragma target 3.0

			#include "UnityCG.cginc"

			uniform float4x4 _FrustumCornerES;
			uniform float4x4 _MatTorus_InvModel;
			uniform float4x4 _CameraInvViewMatrix;
			uniform float4 _MainTex_TexelSize;
			sampler2D _MainTex;
			uniform sampler2D _CameraDepthTexture;
			uniform sampler2D _ColorRamp;;
			uniform float3 _LightDir;
			uniform float3 _cameraWS;
			fixed4 colorTest = fixed4(1,0,0,0);
			fixed4 _Color;


			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 pos : SV_POSITION;
				float3 ray : TEXCOORD1;
			};


			////////////////////////////////////////////////////////////////////////////////////////
			///functions from : http://iquilezles.org/www/articles/distfunctions/distfunctions.htm
			////////////////////////////////////////////////////////////////////////////////////////

			// Union (with material data)
			float2 _opU( float2 d1, float2 d2 )
			{
				return (d1.x < d2.x) ? d1 : d2;
			}

			// Union (with material data)
			float2 _opS( float2 d1, float2 d2 )
			{
				return (-d1.x > d2.x) ? d1 : d2;
			}

			//union
			float opU( float d1, float d2 )
			{
				return min(d1,d2);
			}

			//subtraction
			float opS( float d1, float d2 )
			{
				return max(-d1,d2);
			}

			//intersection
			float opI( float d1, float d2 )
			{
				return max(d1,d2);
			}

			float sdSphere( float3 p, float s )
			{
			  return length(p) - s;
			}

			float sdTorus(float3 p, float2 t)
			{
				float2 q = float2(length(p.xz) - t.x, p.y);
				return length(q) - t.y;
			}

			float sdBox(float3 p, float3 b)
			{
				float3 d = abs(p) - b;
				return min(max(d.x, max(d.y, d.z)), 0.0) +
					length(max(d, 0.0));
			}
			////////////////////////////////////////////////////////////////////////////////////////
			////////////////////////////////////////////////////////////////////////////////////////


			float2 map(float3 p) {
				float4 q = mul(_MatTorus_InvModel, float4(p, 1));
			
				float torus = sdTorus(q.xyz, float2(1, 0.2));

				float unionBox = opU(
					sdBox(p - float3(-5, 0, 0), float3(1,1,1)), 
					sdBox(p - float3(-4.5, 0.5, 0.5), float3(1,1,1)) 
				);

				float differenceBox = opS(
					sdBox(p - float3(5, 0, 0), float3(1,1,1)), 
					sdBox(p - float3(4.5, 0.5, 0.5), float3(1,1,1)) 
				);

				float2 d_torus = float2(torus, 0.2);
				float2 d_unionBox = float2(unionBox, 0.6);
				float2 d_differenceBox = float2(differenceBox, 0.9);


				float2 u1 = _opU(d_differenceBox, d_unionBox);

				return _opU(u1, d_torus);
			}

			


			float3 CalcNormal(float3 pos)
			{
				const float2 eps = float2(0.001, 0.0);
			
				float3 normal = float3(
								map(pos + eps.xyy).x - map(pos - eps.xyy).x,
								map(pos + eps.yxy).x - map(pos - eps.yxy).x,
								map(pos + eps.yyx).x - map(pos - eps.yyx).x);

				return normalize(normal);
			}


			//Parameters: ro = rayOrigin ** rd = rayDirection ** db = Depth buffer calculated on vertexShader
			fixed4 RayMarching( float3 ro, float3 rd, float db)
			{
				fixed4 colorReturned = fixed4(0,0,0,0);

				const int maxStep = 65;
				float dist = 0;
				float maxDrawDist = 40;

				for(int i=0; i<maxStep; i++)
				{
					float3 p = ro + rd * dist;

					float2 d = map(p);

					if(dist >= db || dist > maxDrawDist )
					{
						colorReturned = fixed4(0,0,0,0);
						break;
					}
					
					if(d.x < 0.001)
					{
						float nor = CalcNormal(p);
						float light = dot(- _LightDir.xyz, nor);
						colorReturned = fixed4(tex2D(_ColorRamp, float2(d.y, 0)).xyz * light, 1);
						break;
					}

					dist += d.x;
				}
				return colorReturned;
			}



			v2f vert (appdata IN)
			{
				v2f OUT;

				half index = IN.vertex.z; // index passed via custom blit function
				IN.vertex.z = 0.1;

				OUT.pos = UnityObjectToClipPos(IN.vertex);
				OUT.uv = IN.uv.xy;

				#if UNITY_UV_STARTS_AT_TOP
					if (_MainTex_TexelSize.y < 0)
						OUT.uv.y = 1 - OUT.uv.y;
				#endif		
				
				OUT.ray = _FrustumCornerES[(int)index].xyz;
				OUT.ray /= abs(OUT.ray.z);
				OUT.ray = mul(_CameraInvViewMatrix, OUT.ray);

				return OUT;
			}
			
			fixed4 frag (v2f IN) : SV_Target
			{	
				float3 ro = _cameraWS;
				float3 rd = normalize(IN.ray.xyz);

				float2 frag_uv = IN.uv;

				#if UNITY_UV_STARTS_AT_TOP
					if (_MainTex_TexelSize.y < 0)
						frag_uv.y = 1 - frag_uv.y;
				#endif

				float depth = LinearEyeDepth(tex2D(_CameraDepthTexture, frag_uv).r);

				depth *= length(IN.ray.xyz);

				fixed3 col = tex2D(_MainTex, IN.uv);
				fixed4 add = RayMarching(ro, rd, depth);
				
				return fixed4(col*(1.0 - add.w) + add.xyz * add.w, 1.0);
			}
		
			ENDCG
		}

	}
}
