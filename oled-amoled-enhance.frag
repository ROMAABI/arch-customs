#version 300 es

// OLED/AMOLED Display Enhancement Shader for Hyprland
// Panel-specific OLED-like visual profile for Chimei Innolux 0x153B (6-bit IPS)
// Tailored for Arch Linux + Hyprland + Intel Iris Xe.
// NOTE: #version MUST be the very first token (Hyprland glslang requirement).

#ifndef PROFILE_CONTRAST
    #define PROFILE_CONTRAST 1.04
#endif

#ifndef PROFILE_GAMMA
    #define PROFILE_GAMMA 0.95
#endif

#ifndef PROFILE_SATURATION
    #define PROFILE_SATURATION 1.06
#endif

#ifndef PROFILE_BLACK_LIFT
    #define PROFILE_BLACK_LIFT 0.005
#endif

precision highp float;

in vec2 v_texcoord;
out vec4 fragColor;

uniform sampler2D tex;

const float CONTRAST    = PROFILE_CONTRAST;
const float GAMMA       = PROFILE_GAMMA;
const float SATURATION  = PROFILE_SATURATION;
const float BLACK_LIFT  = PROFILE_BLACK_LIFT;

// Luminance using HDTV coefficients (luminance-preserving saturation)
float getLuminance(vec3 c) {
    return dot(c, vec3(0.2126, 0.7152, 0.0722));
}

void main() {
    vec4 color = texture(tex, v_texcoord);
    vec3 rgb = color.rgb;

    // 1. Gamma: deepen midtones for OLED-like depth (1.0/gamma so lower gamma = brighter midtones)
    rgb = pow(rgb, vec3(1.0 / GAMMA));

    // 2. Contrast: stretch slope around midpoint
    rgb = (rgb - 0.5) * CONTRAST + 0.5;

    // 3. Saturation: luminance-preserving boost
    float lum = getLuminance(rgb);
    rgb = mix(vec3(lum), rgb, SATURATION);

    // 4. Black lift: prevent shadow crush from the contrast stretch
    rgb = rgb + vec3(BLACK_LIFT);

    // Keep within valid range
    rgb = clamp(rgb, 0.0, 1.0);

    fragColor = vec4(rgb, color.a);
}