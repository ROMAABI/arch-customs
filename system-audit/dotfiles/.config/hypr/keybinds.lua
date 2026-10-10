-- Hyprland Keybinds

local mainMod = "SUPER"

local fileManager = "dolphin"

-- Apps
hl.bind(mainMod .. " + Q", hl.dsp.window.close())
hl.bind(mainMod .. " + L", hl.dsp.exec_cmd("hyprlock"))
hl.bind(mainMod .. " + K", hl.dsp.exec_cmd("pkill Hyprland"))
-- SUPER+ALT+Q: close all windows on ALL Hyprland sessions/instances
-- Pure-lua close for current instance (instant, no hyprctl dispatch needed)
-- + shell loop for any other uwsm sessions via `hyprctl --instance ... repl`
hl.bind(mainMod .. " + SHIFT + ESCAPE",hl.dsp.exec_cmd("shutdown now"))
hl.bind(mainMod .. " + ALT + Q", function()
    for _, w in ipairs(hl.get_windows()) do
        hl.dispatch(hl.dsp.window.close({ window = w }))
    end
    hl.exec_cmd("/home/spix/.config/hypr/scripts/close-all-windows.sh")
end)
hl.bind(mainMod .. " + W", hl.dsp.exec_cmd("hyde-shell logoutlaunch 1"))
hl.bind(mainMod .. " + B", hl.dsp.exec_cmd("blueman-manager"))
hl.bind(mainMod .. " + F", hl.dsp.exec_cmd("zen-browser"))
hl.bind(mainMod .. " + T", hl.dsp.exec_cmd("kitty"))
hl.bind(mainMod .. " + C", hl.dsp.exec_cmd("zeditor"))
hl.bind(mainMod .. " + D", hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + SPACE", hl.dsp.exec_cmd("hyde-shell rofilaunch"))
hl.bind(mainMod .. " + H", hl.dsp.layout("focus l"))
hl.bind(mainMod .. " + O", hl.dsp.exec_cmd("kitty opencode"))

-- Website launchers (Super + Alt + key)
hl.bind(mainMod .. " + ALT + Y", hl.dsp.exec_cmd("zen-browser --new-window https://youtube.com"))
hl.bind(mainMod .. " + ALT + M", hl.dsp.exec_cmd("zen-browser --new-window https://music.youtube.com"))
hl.bind(mainMod .. " + ALT + G", hl.dsp.exec_cmd("zen-browser --new-window https://gemini.google.com"))
hl.bind(mainMod .. " + ALT + N", hl.dsp.exec_cmd("zen-browser --new-window https://netmirror.app"))
hl.bind(mainMod .. " + ALT + S", hl.dsp.exec_cmd("zen-browser --new-window https://open.spotify.com"))
hl.bind(mainMod .. " + ALT + W", hl.dsp.exec_cmd("zen-browser --new-window https://web.whatsapp.com"))
hl.bind(mainMod .. " + ALT + A", hl.dsp.exec_cmd("zen-browser --new-window https://animex.one/home"))
hl.bind(mainMod .. " + ALT + T", hl.dsp.exec_cmd("zen-browser --new-window https://tlkstream.com"))
hl.bind(mainMod .. " + ALT + H", hl.dsp.exec_cmd("zen-browser --new-window https://github.com"))
hl.bind(mainMod .. " + ALT + I", hl.dsp.exec_cmd("zen-browser --new-window https://instagram.com"))
hl.bind(mainMod .. " + ALT + E", hl.dsp.exec_cmd("zen-browser --new-window https://mail.google.com"))
hl.bind(mainMod .. " + ALT + C", hl.dsp.exec_cmd("zen-browser --new-window https://claude.ai"))
hl.bind(mainMod .. " + ALT + O", hl.dsp.exec_cmd("zen-browser --new-window https://chatgpt.com"))
hl.bind(mainMod .. " + ALT + Z", hl.dsp.exec_cmd("zen-browser --new-window https://chat.z.ai"))
hl.bind(mainMod .. " + ALT + L", hl.dsp.exec_cmd("zen-browser --new-window https://linkedin.com"))
hl.bind(mainMod .. " + ALT + K", hl.dsp.exec_cmd("zen-browser --new-window https://naukri.com"))

-- Focus
hl.bind(mainMod .. " + left",  hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up",    hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down",  hl.dsp.focus({ direction = "down" }))

-- Workspaces
for i = 1, 10 do
    local key = i % 10
    hl.bind(mainMod .. " + " .. key,             hl.dsp.focus({ workspace = i}))
    hl.bind(mainMod .. " + SHIFT + " .. key,     hl.dsp.window.move({ workspace = i }))
end

-- Scratchpad
hl.bind(mainMod .. " + S",         hl.dsp.workspace.toggle_special("magic"))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))

-- Scroll workspaces
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

-- Mouse
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Window management
hl.bind(mainMod .. " + E", hl.dsp.window.float({ action = "toggle" }))
hl.bind("ALT + F4", hl.dsp.window.close())
hl.bind(mainMod .. " + ALT + F4", hl.dsp.window.kill())
hl.bind(mainMod .. " + Delete", hl.dsp.exec_cmd("pkill Hyprland"))
hl.bind(mainMod .. " + G", hl.dsp.group.toggle())
hl.bind("ALT + P", hl.dsp.window.pseudo())
hl.bind("SHIFT + F11", function()
    local active_window = assert(hl.get_active_window(), "No active window")
    local current_state = tonumber(active_window.fullscreen) or 0
    local next_state = (current_state + 1) % 3
    hl.dispatch(hl.dsp.window.fullscreen_state({ internal = next_state, client = next_state, window = active_window }))
end)
hl.bind(mainMod .. " + SHIFT + F", hl.dsp.exec_cmd("hyde-shell window.pin"))
hl.bind("CTRL + ALT + DELETE", hl.dsp.exec_cmd("hyde-shell logoutlaunch 1"))
hl.bind(mainMod .. " + CTRL + B", hl.dsp.exec_cmd("hyde-shell waybar --hide"))

-- Group navigation
hl.bind(mainMod .. " + CTRL + H", hl.dsp.group.prev())
hl.bind(mainMod .. " + CTRL + L", hl.dsp.group.next())

-- Alt-Tab
hl.bind("ALT + TAB", hl.dsp.exec_cmd("hyde-shell altab --next"))
hl.bind("ALT + SHIFT + TAB", hl.dsp.exec_cmd("hyde-shell altab --prev"))
hl.bind("ALT + ALT_R", hl.dsp.exec_cmd("hyde-shell altab --apply"))
hl.bind("ALT + ALT_L", hl.dsp.exec_cmd("hyde-shell altab --apply"))

-- Resize
hl.bind(mainMod .. " + SHIFT + RIGHT", hl.dsp.window.resize({ x = 30, y = 0, relative = true }))
hl.bind(mainMod .. " + SHIFT + LEFT", hl.dsp.window.resize({ x = -30, y = 0, relative = true }))
hl.bind(mainMod .. " + SHIFT + UP", hl.dsp.window.resize({ x = 0, y = -30, relative = true }))
hl.bind(mainMod .. " + SHIFT + DOWN", hl.dsp.window.resize({ x = 0, y = 30, relative = true }))

-- Move windows
hl.bind(mainMod .. " + SHIFT + CTRL + LEFT", function()
    local w = hl.get_active_window()
    if w and w.floating then
        hl.dispatch(hl.dsp.window.move({ x = -30, y = 0, relative = true }))
    else
hl.dispatch(hl.dsp.window.move({ direction = "l" }))
    end
end)
hl.bind(mainMod .. " + SHIFT + CTRL + RIGHT", function()
    local w = hl.get_active_window()
    if w and w.floating then
        hl.dispatch(hl.dsp.window.move({ x = 30, y = 0, relative = true }))
    else
        hl.dispatch(hl.dsp.window.move({ direction = "r" }))
    end
end)
hl.bind(mainMod .. " + SHIFT + CTRL + UP", function()
    local w = hl.get_active_window()
    if w and w.floating then
        hl.dispatch(hl.dsp.window.move({ x = 0, y = -30, relative = true }))
    else
        hl.dispatch(hl.dsp.window.move({ direction = "u" }))
    end
end)
hl.bind(mainMod .. " + SHIFT + CTRL + DOWN", function()
    local w = hl.get_active_window()
    if w and w.floating then
        hl.dispatch(hl.dsp.window.move({ x = 0, y = 30, relative = true }))
    else
        hl.dispatch(hl.dsp.window.move({ direction = "d" }))
    end
end)

-- Hold to move/resize
hl.bind(mainMod .. " + Z", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. " + X", hl.dsp.window.resize(), { mouse = true })

-- Layout
hl.bind(mainMod .. " + J", hl.dsp.layout("togglesplit"))

-- Rofi menus
-- COMMENTED rofi drun (replaced by antigravity - uncomment to restore):
-- hl.bind(mainMod .. " + A", hl.dsp.exec_cmd("hyde-shell rofi drun"))
hl.bind(mainMod .. " + A", hl.dsp.exec_cmd("antigravity"))
-- COMMENTED for hymission SUPER+TAB (rofi window moved - uncomment to restore):
-- hl.bind(mainMod .. " + TAB", hl.dsp.exec_cmd("hyde-shell rofi window"))
hl.bind(mainMod .. " + SHIFT + E", hl.dsp.exec_cmd("hyde-shell rofi filebrowser"))
hl.bind(mainMod .. " + slash", hl.dsp.exec_cmd("hyde-shell keybinds_hint"))
hl.bind(mainMod .. " + comma", hl.dsp.exec_cmd("hyde-shell emoji-picker"))
hl.bind(mainMod .. " + period", hl.dsp.exec_cmd("hyde-shell glyph-picker"))
hl.bind(mainMod .. " + V", hl.dsp.exec_cmd("hyde-shell cliphist"))
hl.bind(mainMod .. " + SHIFT + V", hl.dsp.exec_cmd("hyde-shell cliphist"))
hl.bind(mainMod .. " + SHIFT + A", hl.dsp.exec_cmd("hyde-shell rofiselect"))
hl.bind(mainMod .. " + SHIFT + K", hl.dsp.exec_cmd("hyde-shell calculator"))
hl.bind(mainMod .. " + SHIFT + slash", hl.dsp.exec_cmd("hyde-shell rofi.websearch"))

-- Volume
hl.bind("F10", hl.dsp.exec_cmd("hyde-shell volumecontrol -o m"), { locked = true })
hl.bind("F11", hl.dsp.exec_cmd("hyde-shell volumecontrol -o d"), { locked = true, repeating = true })
hl.bind("F12", hl.dsp.exec_cmd("hyde-shell volumecontrol -o i"), { locked = true, repeating = true })
hl.bind(mainMod .. " + CTRL + M", hl.dsp.exec_cmd("hyde-shell volumecontrol -i m"))

-- Utilities
hl.bind(mainMod .. " + SHIFT + G", hl.dsp.exec_cmd("hyde-shell gamelauncher"))
hl.bind(mainMod .. " + SHIFT + P", hl.dsp.exec_cmd("hyprpicker -an"))
hl.bind(mainMod .. " + P", hl.dsp.exec_cmd("hyde-shell screenshot s"))
hl.bind(mainMod .. " + CONTROL + P", hl.dsp.exec_cmd("hyde-shell screenshot sf"))
hl.bind(mainMod .. " + ALT + P", hl.dsp.exec_cmd("hyde-shell screenshot m"))
hl.bind("Print", hl.dsp.exec_cmd("hyde-shell screenshot p"))
hl.bind(mainMod .. " + CONTROL + S", hl.dsp.exec_cmd("hyde-shell screenshot sc"))

-- Voice input
hl.bind("ALT + V", hl.dsp.exec_cmd("/home/spix/.local/share/astra-voice/voice-input.sh"))
hl.bind("ALT + S", hl.dsp.exec_cmd("pkill ffplay; pkill aplay"))

-- scrcpy wireless mirror, phone physical screen off (-S)
-- -e = --select-tcpip, required when USB + WiFi devices both present
hl.bind("CTRL + P", hl.dsp.exec_cmd("scrcpy -e --turn-screen-off --stay-awake --show-touches -m 1920 --window-title scrcpy"))

-- Wallpaper and theming
hl.bind(mainMod .. " + ALT + Right", hl.dsp.exec_cmd("hyde-shell wallpaper --next"))
hl.bind(mainMod .. " + ALT + Left", hl.dsp.exec_cmd("hyde-shell wallpaper --prev"))
hl.bind(mainMod .. " + ALT + Up", hl.dsp.exec_cmd("hyde-shell waybar --next"))
hl.bind(mainMod .. " + ALT + Down", hl.dsp.exec_cmd("hyde-shell waybar --prev"))
hl.bind(mainMod .. " + SHIFT + W", hl.dsp.exec_cmd("hyde-shell wallpaper -SG"))
hl.bind(mainMod .. " + SHIFT + R", hl.dsp.exec_cmd("hyde-shell wallbashtoggle -m"))
hl.bind(mainMod .. " + SHIFT + T", hl.dsp.exec_cmd("hyde-shell theme.select"))
hl.bind(mainMod .. " + SHIFT + Y", hl.dsp.exec_cmd("hyde-shell animations --select"))
hl.bind(mainMod .. " + SHIFT + U", hl.dsp.exec_cmd("hyde-shell hyprlock --select"))

-- Laptop media keys
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("hyde-shell volumecontrol -o i"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("hyde-shell volumecontrol -o d"), { locked = true, repeating = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("hyde-shell volumecontrol -o m"), { locked = true, repeating = true })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("hyde-shell volumecontrol -i m"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("hyde-shell brightnesscontrol -i"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("hyde-shell brightnesscontrol -d"), { locked = true, repeating = true })

-- Playerctl
hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),       { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),   { locked = true })

-- hymission Mission Control overview (safe: no runtime error if plugin not loaded)
local function hymission_call(fn_name, arg)
    local plug = hl.plugin and hl.plugin.hymission
    if plug and plug[fn_name] then
        if arg ~= nil then
            plug[fn_name](arg)
        else
            plug[fn_name]()
        end
    else
        hl.notification.create({ text = "hymission not loaded - restart Hyprland", timeout = 3000 })
    end
end
hl.bind("SUPER + TAB", function()
    hymission_call("toggle")
end)


-- GPU Screen Recorder

hl.bind(mainMod .. " + R", hl.dsp.exec_cmd("~/.local/bin/screenrecord"))
