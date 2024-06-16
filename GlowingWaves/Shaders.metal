//
//  Shaders.metal
//  GlowingWaves
//
//  Created by Grisha Tadevosyan on 16.06.24.
//

#include <metal_stdlib>
using namespace metal;

struct VertexOut {
    float4 position [[position]];
    float2 uv;
};

vertex VertexOut vertexShader(uint vertexID [[vertex_id]], constant float2 *resolution [[buffer(1)]]) {
    float2 positions[4] = {
        float2(-1.0, -1.0),
        float2( 1.0, -1.0),
        float2(-1.0,  1.0),
        float2( 1.0,  1.0)
    };

    VertexOut out;
    out.position = float4(positions[vertexID], 0.0, 1.0);
    out.uv = (positions[vertexID] + 1.0) * 0.5;
    return out;
}

float N2(float2 p) {
    p = fmod(p, float2(1456.2346));
    float3 p3 = fract(float3(p.xyx) * float3(443.897, 441.423, 437.195));
    p3 += dot(p3, p3.yzx + 19.19);
    return fract((p3.x + p3.y) * p3.z);
}

float CosineInterpolate(float y1, float y2, float t) {
    float mu = (1.0 - cos(t * 3.14159265359)) * 0.5;
    return (y1 * (1.0 - mu) + y2 * mu);
}

float Noise2(float2 uv) {
    float2 corner = floor(uv);
    float c00 = N2(corner + float2(0.0, 0.0));
    float c01 = N2(corner + float2(0.0, 1.0));
    float c11 = N2(corner + float2(1.0, 1.0));
    float c10 = N2(corner + float2(1.0, 0.0));
    
    float2 diff = fract(uv);
    
    return CosineInterpolate(CosineInterpolate(c00, c10, diff.x), CosineInterpolate(c01, c11, diff.x), diff.y);
}

float LineNoise(float x, float t) {
    float n = Noise2(float2(x * 0.6, t * 0.2));
    return n - 0.5;
}

float line(float2 uv, float t, float scroll) {
    float ax = abs(uv.x);
    uv.y *= 0.5 + ax * ax * 0.3;
    uv.y *= 5;
    uv.x += t * scroll;
    
    float n1 = LineNoise(uv.x, t);
    float n2 = LineNoise(uv.x + 0.5, t + 10.0) * 2.0;
    
    float ay = abs(uv.y - n1);
    float lum = smoothstep(0.02, 0.00, ay) * 1.5;
    lum += smoothstep(1.5, 0.00, ay) * 0.1;
    
    float r = (uv.y - n1) / (n2 - n1);
    float h = clamp(1.0 - r, 0.0, 1.0);
    if (r > 0.0) lum = max(lum, h * h * 0.7);
    
    return lum;
}

fragment float4 fragmentShader(VertexOut in [[stage_in]], constant float &iTime [[buffer(0)]]) {
    #define pi 3.14159265359
    #define pi2 (pi * 2.0)

 
    float2 uv = (2.0 * in.uv - 1.0);

    float lum = line(uv * float2(2.0, 1.0), iTime * 0.3, 0.1) * 0.6;
        lum += line(uv * float2(1.5, 0.9) + float2(0.33, 0.0), iTime * 0.5 + 45.0, 0.15) * 0.5;
        lum += line(uv * float2(1.3, 1.2) + float2(0.66, 0.0), iTime * 0.4 + 67.3, 0.2) * 0.3;
        lum += line(uv * float2(1.5, 1.15) + float2(0.8, 0.0), iTime * 0.77 + 1235.45, 0.23) * 0.43;
        lum += line(uv * float2(1.5, 1.15) + float2(0.8, 0.0), iTime * 0.77 + 456.45, 0.3) * 0.25;
    
    float ax = abs(uv.x);
    lum += ax * ax * 0.005;
    
    float x = uv.x * 1.2 + iTime * 0.2;
    float3 hue = (sin(float3(x, x + pi2 * 0.33, x + pi2 * 0.66)) + float3(1.0)) * 0.7;

    float3 col;
    float thres = 0.7;
    if (lum < thres)
        col = hue * lum / thres;
    else
        col = float3(1.0) - (float3(1.0 - (lum - thres)) * (float3(1.0) - hue));

   
    float alpha = saturate(col.r + col.g + col.b);
    
   
    float4 premultipliedColor = float4(col , alpha);

    return premultipliedColor;
}
