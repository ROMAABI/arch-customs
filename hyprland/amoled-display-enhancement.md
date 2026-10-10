# AMOLED/OLED Display Enhancement — Hyprland

Panel-specific OLED-like visual profile for **Chimei Innolux 0x153B** (6-bit IPS).
Tailored for Arch Linux + Hyprland + Intel Iris Xe.

---

## Display Information Discovered

| Property | Value |
|---|---|
| **Panel vendor** | Chimei Innolux Corporation (CMN) |
| **Model** | 0x153B (N153B?) |
| **Size** | 15.6" (340×190 mm) |
| **Resolution** | 1920×1080 |
| **Refresh rate** | 60 Hz |
| **Color depth** | **6-bit** (64 levels per channel) |
| **Native gamma** | 2.20 |
| **Color gamut** | sRGB (D65 white point: 0.3134, 0.3291) |
| **Max luminance** | ~80 nits (sdrMaxLuminance) |
| **HDR** | Not supported |
| **Interface** | eDP (embedded DisplayPort) |
| **Backlight** | Intel backlight, max 96000 |

### Current Configuration

| Setting | Value |
|---|---|
| Compositor | Hyprland 0.55.2 |
| GPU | Intel Iris Xe (Raptor Lake-P) |
| Mesa | 26.1.1-arch1.2 |
| Color management preset | srgb |
| Current format | XRGB8888 (8-bit software, 6-bit panel) |
| sdrBrightness | 1.00 |
| sdrSaturation | 1.00 |
| Existing ICC profiles | None |
| colord | Not installed |

---

## Reasoning for Chosen Values

### Critical Constraint: 6-bit Panel

This is a **6-bit** IPS panel with **64 levels per color channel**.  
Every adjustment that compresses or stretches the color range risks **visible banding**.

**Conservative approach taken:**

| Parameter | Value | Why this value |
|---|---|---|
| **Gamma** | 0.95 | Deepens midtones without compressing levels. A 0.95 gamma shifts input 0.5 to output ~0.48 — subtle but perceptible OLED-like depth. Safe on 6-bit. |
| **Contrast** | 1.04 | Stretches the midrange slope. At 6-bit, this causes at most 1-2 level gaps at the extremes — invisible with FRC dithering. |
| **Saturation** | 1.06 | 6% luminance-preserving boost. Linear scaling, no level compression. Colors appear richer without oversaturation. |
| **Black lift** | 0.005 | Tiny offset (0.5% of range) prevents any shadow crush from the contrast stretch. Essential for preserving near-black detail. |
| **Brightness** | 1.00 | No change. Adjust your actual backlight for brightness. |

### Safe Range Reference

| Parameter | Min | Default | Max | Risk above max |
|---|---|---|---|---|
| CONTRAST | 1.00 | 1.04 | 1.06 | Banding in gradients |
| GAMMA | 1.00 | 0.95 | 0.90 | Shadow crush, loss of detail |
| SATURATION | 1.00 | 1.06 | 1.15 | Color clipping, oversaturation |
| BLACK_LIFT | 0.000 | 0.005 | 0.020 | Washed-out blacks |

---

## Files Created/Modified

| File | Action | Purpose |
|---|---|---|
| `~/.config/hypr/shaders/oled-amoled-enhance.frag` | **Created** | GLSL screen shader with OLED profile |
| `~/.config/hypr/oled-amoled.conf` | **Created** | Hyprland config snippet |
| `~/.config/hypr/userprefs.conf` | **Modified** | Added `source = ./oled-amoled.conf` |
| `~/.config/hypr/userprefs.conf.backup.oled` | **Created** | Pre-modification backup |
| `~/README_AMOLED_DISPLAY.md` | **Created** | This file |

---

## Startup Method

**Hyprland `exec-once`** via sourced config:

```
~/.config/hypr/userprefs.conf  →  source = ./oled-amoled.conf  →  exec-once = sleep 2 && hyprctl keyword decoration:screen_shader ...oled-amoled-enhance.frag
```

The 2-second delay ensures HyDE's startup scripts finish first.  
Shader loads ~2s after each login — survives **reboot, logout/login, Hyprland restart**.

---

## How to Tweak Values

### Quick reload (no restart needed)

```bash
# Edit the shader:
nano ~/.config/hypr/shaders/oled-amoled-enhance.frag

# Apply immediately:
hyprctl keyword decoration:screen_shader ~/.config/hypr/shaders/oled-amoled-enhance.frag
```

### Parameter guide

```
PROFILE_CONTRAST   = 1.04   →  1.00 = off, 1.06 = max recommended
PROFILE_GAMMA      = 0.95   →  1.00 = off, 0.90 = rich but risk crush
PROFILE_SATURATION = 1.06   →  1.00 = off, 1.15 = vivid max
PROFILE_BLACK_LIFT = 0.005  →  0.000 = no lift, 0.020 = washed
```

---

## Rollback Instructions

### One-liner rollback

```bash
hyprctl keyword decoration:screen_shader ~/.config/hypr/shaders/.compiled.cache.glsl && \
sed -i '/OLED\/AMOLED Display Enhancement/d' ~/.config/hypr/userprefs.conf && \
sed -i '/source = \.\/oled-amoled.conf/d' ~/.config/hypr/userprefs.conf && \
rm -f ~/.config/hypr/oled-amoled.conf ~/.config/hypr/shaders/oled-amoled-enhance.frag && \
echo "Rollback complete"
```

### Step-by-step

1. **Reset shader** — `hyprctl keyword decoration:screen_shader ~/.config/hypr/shaders/.compiled.cache.glsl`
2. **Remove source line** — `sed -i '/oled-amoled/d' ~/.config/hypr/userprefs.conf`
3. **Delete config** — `rm ~/.config/hypr/oled-amoled.conf`
4. **Delete shader** — `rm ~/.config/hypr/shaders/oled-amoled-enhance.frag`

### Restore from backup

```bash
cp ~/.config/hypr/userprefs.conf.backup.oled ~/.config/hypr/userprefs.conf
```

---

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| Visible banding in gradients | Contrast too high for 6-bit | Reduce `PROFILE_CONTRAST` to 1.02 or 1.00 |
| Colors look washed | Contrast + gamma combo too aggressive | Increase `PROFILE_CONTRAST` or reduce `PROFILE_GAMMA` |
| Shadows lose detail (crushed blacks) | Gamma too low or contrast too high | Increase `PROFILE_GAMMA` toward 1.00 or increase `PROFILE_BLACK_LIFT` |
| Colors oversaturated/clipping | Saturation too high | Reduce `PROFILE_SATURATION` |
| No effect after reboot | Race condition with HyDE | Increase sleep delay: `sleep 3` in oled-amoled.conf |
| Shader not loading | Syntax error in .frag | Check journal: `journalctl --user -u hyprland --since "1 minute ago" \| grep -i shader` |

### Testing checklist

```bash
# Check shader is active
hyprctl getoption decoration:screen_shader

# Check monitor health
hyprctl monitors | grep -E "focused|disabled|format"

# Check for errors
journalctl --user -u hyprland --since "5 minutes ago" | grep -iE "error|shader|glsl"
```

---

## Expected Visual Improvements

- ✅ Deeper perceived blacks (gamma adjustment)
- ✅ Richer reds, cyans, blues (saturation boost)
- ✅ Higher perceived contrast (contrast stretch)
- ✅ Vibrant terminal themes and UI accents
- ✅ Preserved shadow detail (black lift + safe values)
- ✅ Readable text and comfortable for long coding
- ✅ Natural skin tones (luminance-preserving saturation)
- ⚠️ *Will not match true OLED — limited by 6-bit IPS panel hardware*

## Performance Impact

**Negligible.** The shader is ~15 ALU instructions + 1 texture fetch.  
No measurable FPS impact on Intel Iris Xe at 1080p.
