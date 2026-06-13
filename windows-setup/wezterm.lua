local wezterm = require 'wezterm'
local config = wezterm.config_builder()

config.color_scheme = 'carbonfox'

config.window_decorations = "INTEGRATED_BUTTONS|RESIZE"
config.automatically_reload_config = true

config.window_frame = {
    border_left_width = '0.5cell',
    border_right_width = '0.5cell',
    border_bottom_height = '0.5cell',
    border_top_height = '0px',
    border_left_color = '#151515',
    border_right_color = '#151515',
    border_bottom_color = '#151515',
    border_top_color = '#151520',
}

config.enable_tab_bar = true
config.use_fancy_tab_bar = true
config.hide_tab_bar_if_only_one_tab = true
config.tab_bar_at_bottom = false
config.show_tab_index_in_tab_bar = false
config.show_new_tab_button_in_tab_bar = true

config.window_background_opacity = 0.95
config.text_background_opacity = 1.0

config.integrated_title_buttons = { 'Hide', 'Maximize', 'Close' }
-- Windows-native style (not MacOsNative)
config.integrated_title_button_style = 'Windows'
config.integrated_title_button_alignment = 'Right'

-- Launch WSL as the default shell
-- Change 'Ubuntu' to match your WSL distribution name (run `wsl --list` to check)
config.default_prog = { 'wsl.exe', '-d', 'Ubuntu', '--', 'zsh', '-l' }

-- Font: Cartograph CF must be installed on the Windows side
-- If not installed, swap for 'JetBrainsMono Nerd Font' which is in your yadm fonts
config.font = wezterm.font 'Cartograph CF'
config.font_size = 14.0
config.line_height = 1.1
config.cell_width = 0.95

-- ALT replaces SUPER (Cmd) on Windows — WIN key conflicts with system shortcuts
local act = wezterm.action
config.keys = {
    { key = 'n', mods = 'ALT', action = act.SpawnWindow },
    { key = 't', mods = 'ALT', action = act.SpawnTab('CurrentPaneDomain') },
    { key = 'w', mods = 'ALT', action = act.CloseCurrentTab({ confirm = true }) },

    -- Tab switching
    { key = '1', mods = 'ALT', action = act.ActivateTab(0) },
    { key = '2', mods = 'ALT', action = act.ActivateTab(1) },
    { key = '3', mods = 'ALT', action = act.ActivateTab(2) },
    { key = '4', mods = 'ALT', action = act.ActivateTab(3) },
    { key = '5', mods = 'ALT', action = act.ActivateTab(4) },
    { key = '6', mods = 'ALT', action = act.ActivateTab(5) },
    { key = '7', mods = 'ALT', action = act.ActivateTab(6) },
    { key = '8', mods = 'ALT', action = act.ActivateTab(7) },
    { key = '9', mods = 'ALT', action = act.ActivateTab(-1) },

    { key = '[', mods = 'ALT|SHIFT', action = act.ActivateTabRelative(-1) },
    { key = ']', mods = 'ALT|SHIFT', action = act.ActivateTabRelative(1) },

    -- Copy/Paste — CTRL+SHIFT is standard in Windows terminals
    { key = 'c', mods = 'CTRL|SHIFT', action = act.CopyTo('Clipboard') },
    { key = 'v', mods = 'CTRL|SHIFT', action = act.PasteFrom('Clipboard') },

    { key = 'f', mods = 'ALT', action = act.Search({ CaseSensitiveString = '' }) },

    { key = '+', mods = 'CTRL', action = act.IncreaseFontSize },
    { key = '-', mods = 'CTRL', action = act.DecreaseFontSize },
    { key = '0', mods = 'CTRL', action = act.ResetFontSize },

    {
        key = ',',
        mods = 'ALT',
        action = act.SpawnCommandInNewTab({
            args = { 'wsl.exe', '-d', 'Ubuntu', '--', 'hx', wezterm.config_file }
        })
    },

    -- Pane management
    { key = 'd', mods = 'ALT|SHIFT', action = act.SplitHorizontal({ domain = 'CurrentPaneDomain' }) },
    { key = 'd', mods = 'ALT',       action = act.SplitVertical({ domain = 'CurrentPaneDomain' }) },
}

config.mouse_bindings = {
    {
        event = { Down = { streak = 1, button = 'Right' } },
        mods = 'NONE',
        action = act.PasteFrom('PrimarySelection'),
    },
    {
        event = { Up = { streak = 1, button = 'Left' } },
        mods = 'ALT',
        action = act.OpenLinkAtMouseCursor,
    },
}

config.launch_menu = {
    { label = 'WSL zsh',  args = { 'wsl.exe', '-d', 'Ubuntu', '--', 'zsh',  '-l' } },
    { label = 'WSL bash', args = { 'wsl.exe', '-d', 'Ubuntu', '--', 'bash', '-l' } },
    { label = 'PowerShell', args = { 'pwsh.exe' } },
    { label = 'CMD',        args = { 'cmd.exe' } },
}

config.colors = {
    tab_bar = {
        background = '#1a1a1a',
        active_tab = {
            bg_color = '#282828',
            fg_color = '#f2f2f2',
            intensity = 'Normal',
            underline = 'None',
            italic = false,
            strikethrough = false,
        },
        inactive_tab = {
            bg_color = '#1a1a1a',
            fg_color = '#888888',
            intensity = 'Normal',
            underline = 'None',
            italic = false,
            strikethrough = false,
        },
        new_tab = {
            bg_color = '#1a1a1a',
            fg_color = '#888888',
        },
        inactive_tab_hover = {
            bg_color = '#222222',
            fg_color = '#f2f2f2',
            italic = false,
            strikethrough = false,
        },
        new_tab_hover = {
            bg_color = '#222222',
            fg_color = '#f2f2f2',
            italic = false,
            strikethrough = false,
        },
    },
}

config.max_fps = 144
config.animation_fps = 144

-- WebGpu works well on Surface Pro; fall back to OpenGL if you see rendering issues
config.front_end = "WebGpu"

return config
