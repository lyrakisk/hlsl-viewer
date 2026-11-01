// Procedural ocean at sunset: summed directional waves, Fresnel reflection of a
// gradient sky + sun, distance fog. Drag the mouse up/down to tilt the camera.
float timeScale = 1.0;                              // range(0, 3)
float sunHeight = 0.07;                             // range(-0.05, 0.4)
float waveAmp   = 0.30;                             // range(0, 1)
float3 sunColor = float3(1.0, 0.52, 0.22);
float3 skyColor = float3(0.12, 0.20, 0.45);

float3 sunDir() { return normalize(float3(0.0, sunHeight, 1.0)); }

float3 sky(float3 rd)
{
    float3 horizon = float3(1.0, 0.45, 0.20);
    float up = saturate(rd.y);
    float3 col = lerp(horizon, skyColor, pow(saturate(up * 1.6), 0.55));
    float sd = saturate(dot(rd, sunDir()));
    col += sunColor * pow(sd, 6.0) * 0.45;
    col += sunColor * pow(sd, 200.0) * 1.6;
    col += float3(1.0, 0.95, 0.85) * pow(sd, 3000.0) * 4.0;
    return col;
}

float height(float2 p, float t)
{
    float h = 0.0;
    float a = 1.0;
    float f = 0.55;
    for (int i = 0; i < 6; i++)
    {
        float k = float(i) * 2.399;
        float2 d = float2(cos(k), sin(k));
        h += a * sin(dot(p, d) * f + t * (0.9 + 0.25 * float(i)));
        a *= 0.55;
        f *= 1.85;
    }
    return h * waveAmp;
}

float4 main(float2 uv : TEXCOORD0) : SV_Target
{
    float t = iTime * timeScale;
    float2 p = (uv * 2.0 - 1.0) * float2(iResolution.x / iResolution.y, -1.0);
    float tilt = (iMouse.z > 0.0) ? (iMouse.y / iResolution.y - 0.5) * 0.6 : 0.0;

    float3 ro = float3(0.0, 1.4, 0.0);
    float3 rd = normalize(float3(p.x, p.y + 0.14 + tilt, 1.5));
    float3 col;

    if (rd.y >= -0.001)
    {
        col = sky(rd);
    }
    else
    {
        float dist = min(-ro.y / rd.y, 400.0);
        float3 pos = ro + rd * dist;

        float e = 0.05 + dist * 0.004;
        float hC = height(pos.xz, t);
        float hL = height(pos.xz - float2(e, 0.0), t);
        float hR = height(pos.xz + float2(e, 0.0), t);
        float hD = height(pos.xz - float2(0.0, e), t);
        float hU = height(pos.xz + float2(0.0, e), t);
        float3 n = normalize(float3(hL - hR, 2.0 * e, hD - hU));
        n = normalize(lerp(n, float3(0.0, 1.0, 0.0), saturate(dist * 0.02)));

        float3 r = reflect(rd, n);
        r.y = abs(r.y);
        float fres = 0.02 + 0.98 * pow(1.0 - saturate(dot(n, -rd)), 5.0);

        float3 deep = float3(0.01, 0.05, 0.09);
        float3 shallow = float3(0.02, 0.18, 0.20) * saturate(hC / max(waveAmp, 0.01) * 0.25 + 0.5);
        col = lerp(deep + shallow, sky(r), fres);

        float fog = 1.0 - exp(-dist * 0.012);
        col = lerp(col, float3(1.0, 0.45, 0.20) * 0.8, fog * 0.7);
    }

    col = 1.0 - exp(-col * 1.4);
    col *= 1.0 - 0.25 * dot(p * 0.5, p * 0.5);
    return float4(pow(col, float3(0.4545, 0.4545, 0.4545)), 1.0);
}
