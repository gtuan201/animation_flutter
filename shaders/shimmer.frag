#version 460 core
#include <flutter/runtime_effect.glsl>

uniform vec2  uSize;       // kích thước widget (px)
uniform float uTime;       // thời gian (s)
uniform float uSpeed;      // tốc độ chạy shimmer (default 1.0)
uniform vec4  uBaseColor;  // màu nền skeleton
uniform vec4  uShimColor;  // màu dải sáng

out vec4 fragColor;

void main() {
    vec2 uv = FlutterFragCoord().xy / uSize;

    // Dải sáng chạy chéo 25° từ trái sang phải
    float angle = 0.4;  // ~23 độ
    float pos = uv.x * cos(angle) + uv.y * sin(angle);

    // Vị trí dải hiện tại theo thời gian, chạy từ -0.3 → 1.3 rồi lặp
    float t = fract(uTime * uSpeed * 0.45);
    float sweep = t * 1.6 - 0.3;

    // Dải gaussian mịn, bề rộng ~0.12
    float width = 0.11;
    float shim = exp(-pow((pos - sweep) / width, 2.0));

    vec4 col = mix(uBaseColor, uShimColor, shim);
    fragColor = col;
}
