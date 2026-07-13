#version 460 core
#include <flutter/runtime_effect.glsl>

uniform vec2  uSize;    // kích thước canvas
uniform float uTime;    // thời gian (s)
uniform vec4  uColor1;  // màu aurora thứ nhất  (RGBA)
uniform vec4  uColor2;  // màu aurora thứ hai
uniform vec4  uColor3;  // màu aurora thứ ba

out vec4 fragColor;

float hash(float n) { return fract(sin(n) * 43758.5453); }

// Smooth noise 1D
float noise1(float x) {
    float i = floor(x);
    float f = fract(x);
    f = f*f*(3.0-2.0*f);
    return mix(hash(i), hash(i+1.0), f);
}

void main() {
    vec2 uv = FlutterFragCoord().xy / uSize;

    // 3 layer aurora uốn lượn theo sine compound
    float t = uTime * 0.4;

    // Aurora band 1
    float wave1 = noise1(uv.x * 2.5 + t * 0.7) * 0.35
                + noise1(uv.x * 5.0 - t * 0.5) * 0.15;
    float band1 = exp(-pow((uv.y - 0.35 - wave1) * 5.0, 2.0));

    // Aurora band 2 (cao hơn)
    float wave2 = noise1(uv.x * 3.0 - t * 0.6) * 0.3
                + noise1(uv.x * 7.0 + t * 0.4) * 0.12;
    float band2 = exp(-pow((uv.y - 0.55 - wave2) * 6.0, 2.0));

    // Aurora band 3 (thấp, mờ)
    float wave3 = noise1(uv.x * 1.8 + t * 0.3) * 0.4;
    float band3 = exp(-pow((uv.y - 0.2 - wave3) * 7.0, 2.0)) * 0.6;

    // Flicker nhẹ (aurora thật lúc nào cũng nhấp nháy)
    float flicker1 = 0.85 + 0.15 * noise1(t * 3.0 + 1.0);
    float flicker2 = 0.8  + 0.2  * noise1(t * 2.5 + 5.0);
    float flicker3 = 0.9  + 0.1  * noise1(t * 4.0 + 9.0);

    // Blend 3 màu
    vec3 col = vec3(0.0);
    col += uColor1.rgb * band1 * flicker1;
    col += uColor2.rgb * band2 * flicker2;
    col += uColor3.rgb * band3 * flicker3;

    // Fade ra ở đỉnh và đáy màn hình
    float vignY = uv.y * (1.0 - uv.y) * 4.0;
    col *= vignY;

    float alpha = clamp(band1 * flicker1 * uColor1.a
                      + band2 * flicker2 * uColor2.a
                      + band3 * flicker3 * uColor3.a, 0.0, 1.0);
    alpha *= vignY;

    fragColor = vec4(col, alpha);
}
