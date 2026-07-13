#version 460 core
#include <flutter/runtime_effect.glsl>

// ── Uniforms ──
uniform vec2  uResolution;  // kích thước canvas (px)
uniform float uTime;        // thời gian (s)
uniform vec2  uPointer;     // vị trí con trỏ / chạm (px)
uniform float uActive;      // 0..1: mức độ tương tác (nhấn giữ)

out vec4 fragColor;

// Xoay 2D
mat2 rot(float a) {
    float c = cos(a), s = sin(a);
    return mat2(c, -s, s, c);
}

// Palette gradient mượt (Inigo Quilez cosine palette)
vec3 palette(float t) {
    vec3 a = vec3(0.5, 0.5, 0.5);
    vec3 b = vec3(0.5, 0.5, 0.5);
    vec3 c = vec3(1.0, 1.0, 1.0);
    vec3 d = vec3(0.263, 0.416, 0.557);
    return a + b * cos(6.28318 * (c * t + d));
}

void main() {
    vec2 fragCoord = FlutterFragCoord().xy;

    // Toạ độ chuẩn hoá, giữ tỉ lệ
    vec2 uv = (fragCoord * 2.0 - uResolution) / uResolution.y;
    vec2 pointer = (uPointer * 2.0 - uResolution) / uResolution.y;

    // Kéo trường về phía con trỏ tạo tương tác
    vec2 uv0 = uv;
    float pull = 0.35 + uActive * 0.5;
    uv -= pointer * pull * exp(-length(uv - pointer) * 1.5);

    vec3 finalColor = vec3(0.0);

    // Fractal fold lặp nhiều lớp tạo hiệu ứng plasma/kaleido
    for (float i = 0.0; i < 4.0; i++) {
        uv = fract(uv * 1.5) - 0.5;
        uv *= rot(uTime * 0.15 + i * 0.5 + uActive * 0.6);

        float d = length(uv) * exp(-length(uv0));

        // Màu phụ thuộc khoảng cách tới con trỏ để "chạm sáng lên"
        float glow = 0.02 / (length(uv0 - pointer) + 0.15);
        vec3 col = palette(length(uv0) + i * 0.4 + uTime * 0.25);

        d = sin(d * 8.0 + uTime) / 8.0;
        d = abs(d);
        d = pow(0.01 / d, 1.2);

        finalColor += col * d + col * glow * (0.4 + uActive);
    }

    // Vignette nhẹ
    finalColor *= 1.0 - 0.25 * length(uv0);

    fragColor = vec4(finalColor, 1.0);
}
