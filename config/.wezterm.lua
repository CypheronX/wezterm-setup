-- WezTerm config: Git Bash + Catppuccin Mocha
local wezterm = require 'wezterm'
local act = wezterm.action
local config = wezterm.config_builder()

local GIT_BASH = { 'C:\\Program Files\\Git\\bin\\bash.exe', '-i', '-l' }

---------------------------------------------------------------- shell
config.default_prog = GIT_BASH
config.default_cwd = wezterm.home_dir
config.launch_menu = {
  { label = 'Git Bash',    args = GIT_BASH },
  { label = 'PowerShell',  args = { 'powershell.exe', '-NoLogo' } },
  { label = 'CMD',         args = { 'cmd.exe' } },
  { label = 'Claude Code', args = { 'C:\\Program Files\\Git\\bin\\bash.exe', '-i', '-l', '-c', 'claude' } },
}

---------------------------------------------------------------- looks
config.color_scheme = 'Catppuccin Mocha'
config.font = wezterm.font_with_fallback {
  { family = 'JetBrainsMono Nerd Font', weight = 'Regular' },
  'Segoe UI Emoji',
}
config.font_size = 11.5
config.line_height = 1.1
config.harfbuzz_features = { 'calt=1', 'clig=1', 'liga=1' } -- ligatures

config.window_background_opacity = 0.94
config.win32_system_backdrop = 'Acrylic'
config.window_decorations = 'INTEGRATED_BUTTONS|RESIZE'
config.window_padding = { left = 12, right = 12, top = 8, bottom = 6 }
config.initial_cols = 140
config.initial_rows = 36

config.default_cursor_style = 'BlinkingBar'
config.cursor_blink_rate = 600
config.inactive_pane_hsb = { saturation = 0.8, brightness = 0.65 }
config.scrollback_lines = 20000
config.audible_bell = 'Disabled'
config.window_close_confirmation = 'NeverPrompt'

---------------------------------------------------------------- tab bar
config.use_fancy_tab_bar = true
config.hide_tab_bar_if_only_one_tab = false
config.tab_max_width = 32
config.show_new_tab_button_in_tab_bar = true
config.window_frame = {
  font = wezterm.font { family = 'JetBrainsMono Nerd Font', weight = 'Bold' },
  font_size = 10,
  active_titlebar_bg = '#11111b',
  inactive_titlebar_bg = '#11111b',
}
config.colors = {
  tab_bar = {
    inactive_tab_edge = '#11111b',
    active_tab = { bg_color = '#cba6f7', fg_color = '#11111b' },
    inactive_tab = { bg_color = '#181825', fg_color = '#a6adc8' },
    inactive_tab_hover = { bg_color = '#313244', fg_color = '#cdd6f4' },
    new_tab = { bg_color = '#11111b', fg_color = '#a6adc8' },
    new_tab_hover = { bg_color = '#313244', fg_color = '#cdd6f4' },
  },
}

-- Tab title: "<index> <icon> <folder>"
local function basename(s)
  return (s:gsub('[/\\]+$', ''):match('([^/\\]+)$')) or s
end

wezterm.on('format-tab-title', function(tab)
  local pane = tab.active_pane
  local title = pane.title
  local cwd = pane.current_working_dir
  if cwd then
    local path = type(cwd) == 'userdata' and cwd.file_path or tostring(cwd)
    title = basename(path)
  end
  local proc = basename(pane.foreground_process_name or '')
  local icon = '  '
  if proc:match('claude') then icon = ' 󰚩 '
  elseif proc:match('powershell') or proc:match('pwsh') then icon = ' 󰨊 '
  elseif proc:match('nvim') or proc:match('vim') then icon = '  ' end
  if tab.tab_title and #tab.tab_title > 0 then title = tab.tab_title end
  return ' ' .. (tab.tab_index + 1) .. icon .. title .. ' '
end)

-- Right status: workspace + time
wezterm.on('update-right-status', function(window)
  window:set_right_status(wezterm.format {
    { Foreground = { Color = '#89b4fa' } },
    { Text = '  ' .. window:active_workspace() .. '  ' },
    { Foreground = { Color = '#a6e3a1' } },
    { Text = '  ' .. wezterm.strftime '%H:%M' .. '  ' },
  })
end)

---------------------------------------------------------------- keys
config.keys = {
  -- Ctrl+C copies when text is selected, otherwise sends interrupt
  { key = 'c', mods = 'CTRL', action = wezterm.action_callback(function(win, pane)
      local sel = win:get_selection_text_for_pane(pane)
      if sel and sel ~= '' then
        win:perform_action(act.CopyTo 'Clipboard', pane)
        win:perform_action(act.ClearSelection, pane)
      else
        win:perform_action(act.SendKey { key = 'c', mods = 'CTRL' }, pane)
      end
    end) },
  { key = 'v', mods = 'CTRL', action = act.PasteFrom 'Clipboard' },

  -- Tabs
  { key = 't', mods = 'CTRL', action = act.SpawnTab 'CurrentPaneDomain' },
  { key = 'w', mods = 'CTRL|SHIFT', action = act.CloseCurrentPane { confirm = false } },
  { key = 'Tab', mods = 'CTRL', action = act.ActivateTabRelative(1) },
  { key = 'Tab', mods = 'CTRL|SHIFT', action = act.ActivateTabRelative(-1) },
  { key = 'r', mods = 'CTRL|SHIFT', action = act.PromptInputLine {
      description = 'Rename tab',
      action = wezterm.action_callback(function(win, _, line)
        if line then win:active_tab():set_title(line) end
      end) } },

  -- Splits (Windows Terminal style) + navigation
  { key = 'd', mods = 'CTRL|SHIFT', action = act.SplitHorizontal { domain = 'CurrentPaneDomain' } },
  { key = 'e', mods = 'CTRL|SHIFT', action = act.SplitVertical { domain = 'CurrentPaneDomain' } },
  { key = 'LeftArrow',  mods = 'ALT', action = act.ActivatePaneDirection 'Left' },
  { key = 'RightArrow', mods = 'ALT', action = act.ActivatePaneDirection 'Right' },
  { key = 'UpArrow',    mods = 'ALT', action = act.ActivatePaneDirection 'Up' },
  { key = 'DownArrow',  mods = 'ALT', action = act.ActivatePaneDirection 'Down' },
  { key = 'LeftArrow',  mods = 'ALT|SHIFT', action = act.AdjustPaneSize { 'Left', 3 } },
  { key = 'RightArrow', mods = 'ALT|SHIFT', action = act.AdjustPaneSize { 'Right', 3 } },
  { key = 'UpArrow',    mods = 'ALT|SHIFT', action = act.AdjustPaneSize { 'Up', 2 } },
  { key = 'DownArrow',  mods = 'ALT|SHIFT', action = act.AdjustPaneSize { 'Down', 2 } },
  { key = 'z', mods = 'CTRL|SHIFT', action = act.TogglePaneZoomState },

  -- Claude Code in a split to the right
  { key = 'a', mods = 'CTRL|SHIFT', action = act.SplitPane {
      direction = 'Right', size = { Percent = 45 },
      command = { args = { 'C:\\Program Files\\Git\\bin\\bash.exe', '-i', '-l', '-c', 'claude' } } } },

  -- Misc
  { key = 'l', mods = 'CTRL|SHIFT', action = act.ShowLauncher },
  { key = 'p', mods = 'CTRL|SHIFT', action = act.ActivateCommandPalette },
  { key = 'f', mods = 'CTRL|SHIFT', action = act.Search 'CurrentSelectionOrEmptyString' },
  { key = 'x', mods = 'CTRL|SHIFT', action = act.ActivateCopyMode },
  { key = '=', mods = 'CTRL', action = act.IncreaseFontSize },
  { key = '-', mods = 'CTRL', action = act.DecreaseFontSize },
  { key = '0', mods = 'CTRL', action = act.ResetFontSize },
}

-- Right-click pastes, like classic Windows consoles
config.mouse_bindings = {
  { event = { Down = { streak = 1, button = 'Right' } }, mods = 'NONE', action = act.PasteFrom 'Clipboard' },
}

return config
