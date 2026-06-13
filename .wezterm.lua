local wezterm = require 'wezterm'
local config = wezterm.config_builder()

-- Color scheme (preserved from your config)
config.color_scheme = 'carbonfox'

-- Window decorations and frame (preserved and enhanced)
config.window_decorations = "INTEGRATED_BUTTONS|RESIZE"
config.automatically_reload_config = true

-- macOS-style window frame with cleaner borders
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

-- Tab bar configuration to mimic macOS tabs
config.enable_tab_bar = true
config.use_fancy_tab_bar = true
config.hide_tab_bar_if_only_one_tab = true
config.tab_bar_at_bottom = false
config.show_tab_index_in_tab_bar = false
config.show_new_tab_button_in_tab_bar = true

-- macOS-style appearance
config.window_background_opacity = 0.95
config.macos_window_background_blur = 20
config.text_background_opacity = 1.0
config.native_macos_fullscreen_mode = true

-- Integrated title bar buttons (macOS-style)
config.integrated_title_buttons = { 'Hide', 'Maximize', 'Close' }
config.integrated_title_button_style = 'MacOsNative'
config.integrated_title_button_alignment = 'Right'

-- Environment variables to ensure Fish is found
config.set_environment_variables = {
    PATH = '/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin',
}

-- Default program: Use Fish shell
config.default_prog = { 'fish', '-l' }

-- Default working directory (optional, remove if you want to use home directory)
-- config.default_cwd = "/Users/takinprofit"  -- or your preferred starting directory

-- Font configuration
config.font = wezterm.font 'Cartograph CF'
config.font_size = 14.0
config.line_height = 1.1
config.cell_width = 0.95

-- macOS-style keyboard shortcuts
local act = wezterm.action
config.keys = {
    -- Standard macOS shortcuts
    { key = 'n', mods = 'SUPER', action = act.SpawnWindow },
    { key = 't', mods = 'SUPER', action = act.SpawnTab('CurrentPaneDomain') },
    { key = 'w', mods = 'SUPER', action = act.CloseCurrentTab({ confirm = true }) },
    { key = 'q', mods = 'SUPER', action = act.QuitApplication },

    -- Tab switching (like Safari/Chrome)
    { key = '1', mods = 'SUPER', action = act.ActivateTab(0) },
    { key = '2', mods = 'SUPER', action = act.ActivateTab(1) },
    { key = '3', mods = 'SUPER', action = act.ActivateTab(2) },
    { key = '4', mods = 'SUPER', action = act.ActivateTab(3) },
    { key = '5', mods = 'SUPER', action = act.ActivateTab(4) },
    { key = '6', mods = 'SUPER', action = act.ActivateTab(5) },
    { key = '7', mods = 'SUPER', action = act.ActivateTab(6) },
    { key = '8', mods = 'SUPER', action = act.ActivateTab(7) },
    { key = '9', mods = 'SUPER', action = act.ActivateTab(-1) },

    -- Tab navigation with Cmd+Shift+[{ and }]
    { key = '[', mods = 'SUPER|SHIFT', action = act.ActivateTabRelative(-1) },
    { key = ']', mods = 'SUPER|SHIFT', action = act.ActivateTabRelative(1) },

    -- Copy/Paste (macOS style)
    { key = 'c', mods = 'SUPER', action = act.CopyTo('Clipboard') },
    { key = 'v', mods = 'SUPER', action = act.PasteFrom('Clipboard') },
    { key = 'x', mods = 'SUPER', action = act.CopyTo('Clipboard') },
    -- Select all is not directly available as a key action

    -- Find
    { key = 'f', mods = 'SUPER', action = act.Search({ CaseSensitiveString = '' }) },

    -- Zoom
    { key = '+', mods = 'SUPER', action = act.IncreaseFontSize },
    { key = '-', mods = 'SUPER', action = act.DecreaseFontSize },
    { key = '0', mods = 'SUPER', action = act.ResetFontSize },

    -- Quick edit config (Cmd+, like most macOS apps)
    {
        key = ',',
        mods = 'SUPER',
        action = act.SpawnCommandInNewTab({
            args = {
                'hx',
                wezterm.config_file
            }
        })
    },

    -- Pane management
    { key = 'd', mods = 'SUPER|SHIFT', action = act.SplitHorizontal({ domain = 'CurrentPaneDomain' }) },
    { key = 'd', mods = 'SUPER|ALT', action = act.SplitVertical({ domain = 'CurrentPaneDomain' }) },
}

-- Mouse bindings for more native feel
config.mouse_bindings = {
    -- Right-click context menu feel (paste)
    {
        event = { Down = { streak = 1, button = 'Right' } },
        mods = 'NONE',
        action = act.PasteFrom('PrimarySelection'),
    },
    -- Cmd+Click to open links
    {
        event = { Up = { streak = 1, button = 'Left' } },
        mods = 'SUPER',
        action = act.OpenLinkAtMouseCursor,
    },
}

-- Launch menu for quick access
config.launch_menu = {
    {
        label = 'fish',
        args = { 'fish', '-l' },
    },
    {
        label = 'zsh',
        args = { 'zsh', '-l' },
    },
    {
        label = 'bash',
        args = { 'bash', '-l' },
    },
}

-- Dynamic color scheme based on macOS appearance (optional)
-- This automatically switches between light/dark variants if they exist
wezterm.on('window-config-reloaded', function(window, pane)
    local overrides = window:get_config_overrides() or {}
    local appearance = wezterm.gui.get_appearance()

    -- You can create separate light/dark variants of your theme
    -- For now, we'll keep carbonfox
    if appearance:find('Dark') then
        -- You could switch to 'carbonfox' here if you have a light variant
        -- config.color_scheme = 'carbonfox'
    else
        -- config.color_scheme = 'dawnfox' (if exists)
    end
end)

-- Custom tab bar styling to make it more macOS-like
config.colors = {
    -- Extend your carbonfox theme with custom tab colors
    tab_bar = {
        -- The background color of the tab bar when the window is focused
        background = '#1a1a1a',

        -- The active tab
        active_tab = {
            -- The color of the background area for the tab
            bg_color = '#282828',
            -- The color of the text for the tab
            fg_color = '#f2f2f2',
            -- Specify whether you want "Half", "Normal" or "Bold" intensity
            intensity = 'Normal',
            -- Specify whether you want "None", "Single" or "Double" underline
            underline = 'None',
            -- Specify whether you want the text to be italic (true) or not (false)
            italic = false,
            -- Specify whether you want the text to be rendered with strikethrough (true)
            strikethrough = false,
        },

        -- Inactive tabs
        inactive_tab = {
            bg_color = '#1a1a1a',
            fg_color = '#888888',
            intensity = 'Normal',
            underline = 'None',
            italic = false,
            strikethrough = false,
        },

        -- The new tab button that let you create new tabs
        new_tab = {
            bg_color = '#1a1a1a',
            fg_color = '#888888',
            intensity = 'Normal',
            underline = 'None',
            italic = false,
            strikethrough = false,
        },

        -- You can configure some alternate styling when the mouse pointer
        -- moves over inactive tabs or the new tab button
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

-- Performance optimizations
config.max_fps = 144
config.animation_fps = 144

-- Shell integration (optional but recommended)
config.front_end = "WebGpu"  -- or "OpenGL" if you have issues

return config
