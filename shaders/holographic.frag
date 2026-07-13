#version 460 core
#include <flutter/runtime_effect.glsl>

uniform vec2  uSize;    // kích thước card (px)
uniform float uTime;    // thời gian
uniform vec2  uTilt;    // góc nghiêng (x, y) từ gyro hoặc pointer, range -1..1
uniform float uGlare;   // cường độ glare 0..1 (khi nhìn thẳng = 0)

out vec4 fragColor;

// Palette cầu vồng
vec3 rainbow(float t) {
    t = fract(t);
    vec3 c = abs(vec3(t*6.0-3.0, t*6.0-2.0, t*6.0-4.0));
    return clamp(c - 1.0, 0.0, 1.0);
}

// Noise đơn giản
float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}
float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    return mix(
        mix(hash(i), hash(i+vec2(1,0)), f.x),
        mix(hash(i+vec2(0,1)), hash(i+vec2(1,1)), f.x),
        f.y
    );
}

void main() {
    vec2 uv = FlutterFragCoord().xy / uSize;

    // Distort UV theo góc nghiêng để vân cầu vồng dịch chuyển
    vec2 distorted = uv + uTilt * 0.18;

    // Vân holographic: sóng chéo nhiều tần số
    float holo = 0.0;
    holo += sin(distorted.x * 8.0  + distorted.y * 3.0  + uTime * 0.5) * 0.5 + 0.5;
    holo += sin(distorted.x * 5.0  - distorted.y * 7.0  + uTime * 0.3) * 0.5 + 0.5;
    holo += sin(distorted.x * 12.0 + distorted.y * 1.5  - uTime * 0.7) * 0.5 + 0.5;
    holo /= 3.0;

    // Noise layer tạo texture như màng dầu
    float n = noise(distorted * 6.0 + uTime * 0.15);
    holo = mix(holo, n, 0.25);

    // Màu cầu vồng
    vec3 iris = rainbow(holo * 1.2 + uTilt.x * 0.5 + uTilt.y * 0.3);

    // Glare highlight: điểm sáng trắng di chuyển theo tilt
    vec2 glarePos = vec2(0.5) + uTilt * 0.35;
    float glare = exp(-length((uv - glarePos) * vec2(2.0, 3.0)) * 4.0);

    vec3 col = iris * 0.75 + vec3(glare) * uGlare * 0.9;

    // Alpha: hologram layer bán trong suốt
    float alpha = 0.55 + holo * 0.25;
    fragColor = vec4(col, alpha);
}
