local wezterm = require("wezterm")
local act = wezterm.action

local pain_control = wezterm.plugin.require("https://www.github.com/sei40kr/wez-pain-control")

local smart_splits = wezterm.plugin.require("https://www.github.com/smart-splits-nvim/backend-wezterm")

local config = wezterm.config_builder()

-- ============================================================================
-- LEADER
-- ============================================================================

-- config.debug_key_events = true

config.leader = {
	key = "a",
	mods = "CTRL",
	timeout_milliseconds = 1000,
}

-- ============================================================================
-- APPEARANCE
-- ============================================================================

config.font = wezterm.font("JetBrains Mono")
config.font_size = 14

config.color_scheme = "Dracula"

config.enable_tab_bar = true
config.hide_tab_bar_if_only_one_tab = false
config.use_fancy_tab_bar = false
config.tab_bar_at_bottom = false

config.colors = config.colors or {}

-- config.enable_kitty_keyboard = true

config.colors.tab_bar = {
	background = "#282a36",

	active_tab = {
		bg_color = "#f1fa8c",
		fg_color = "#282a36",
		intensity = "Bold",
	},

	inactive_tab = {
		bg_color = "#44475a",
		fg_color = "#bd93f9",
	},

	inactive_tab_hover = {
		bg_color = "#6272a4",
		fg_color = "#ffffff",
	},

	new_tab = {
		bg_color = "#282a36",
		fg_color = "#bd93f9",
	},
}

config.window_padding = {
	left = 1,
	right = 1,
	top = 1,
	bottom = 1,
}

config.scrollback_lines = 200000

config.enable_scroll_bar = false

-- ============================================================================
-- SMART SPLITS
-- ============================================================================

pain_control.apply_to_config(config, {})

smart_splits.apply_to_config(config, {
	-- the default config is shown here; omit the table entirely to use it as-is

	-- directional keys, in order of: left, down, up, right
	direction_keys = { "h", "j", "k", "l" },
	-- move/resize can also be configured separately, e.g.:
	--   direction_keys = {
	--     move = { 'h', 'j', 'k', 'l' },
	--     resize = { 'LeftArrow', 'DownArrow', 'UpArrow', 'RightArrow' },
	--   },

	-- modifiers = {
	-- 	move = "CTRL", -- e.g. CTRL+h to move left
	-- 	resize = "META", -- e.g. META+h to resize left
	-- },
	modifiers = {
		move = "CTRL",
		resize = "CTRL|META",
	},

	-- what happens when there's no WezTerm pane in that direction: both a *direct* keypress in a
	-- pane not running Neovim, and a request from Neovim reporting it hit its own edge, resolve
	-- through this same option — smart-splits.nvim's own `move.at_edge` config has no effect here:
	--   'stop'  -- pass the keystroke through to the program in the pane (default)
	--   'wrap'  -- activate the farthest pane in the opposite direction
	--   'split' -- split the current pane in that direction
	--   function(ctx) ... end -- decide yourself; see below
	at_edge = "stop",

	-- block navigation (both a direct keypress and a request from Neovim) while the current pane
	-- is zoomed in
	block_nav_on_zoom = false,

	log_level = "warn", -- 'error' | 'warn' | 'info'
})

-- ============================================================================
-- KEYBINDINGS
-- ============================================================================

for _, key in ipairs({
	{
		key = "]",
		mods = "LEADER|CTRL",
		action = act.ActivateCopyMode,
	},

	-- --------------------------------------------------------------------------
	-- PANE MANAGEMENT
	-- --------------------------------------------------------------------------

	-- Split vertically (left/right)
	{
		key = "v",
		mods = "LEADER",
		action = act.SplitHorizontal({
			domain = "CurrentPaneDomain",
		}),
	},

	-- Split horizontally (top/bottom)
	{
		key = "s",
		mods = "LEADER",
		action = act.SplitVertical({
			domain = "CurrentPaneDomain",
		}),
	},

	-- Close current pane
	{
		key = "x",
		mods = "LEADER",
		action = act.CloseCurrentPane({
			confirm = true,
		}),
	},

	-- Toggle pane zoom
	{
		key = "z",
		mods = "LEADER",
		action = act.TogglePaneZoomState,
	},

	-- -- Pane navigation
	-- {
	--   key = "h",
	--   mods = "LEADER",
	--   action = act.ActivatePaneDirection("Left"),
	-- },
	-- {
	--   key = "j",
	--   mods = "LEADER",
	--   action = act.ActivatePaneDirection("Down"),
	-- },
	-- {
	--   key = "k",
	--   mods = "LEADER",
	--   action = act.ActivatePaneDirection("Up"),
	-- },
	-- {
	--   key = "l",
	--   mods = "LEADER",
	--   action = act.ActivatePaneDirection("Right"),
	-- },

	-- --------------------------------------------------------------------------
	-- TAB MANAGEMENT
	-- --------------------------------------------------------------------------

	-- New tab with current working directory
	{
		key = "w",
		mods = "LEADER|CTRL",
		action = act.SpawnTab("CurrentPaneDomain"),
	},

	-- Next tab
	{
		key = "n",
		mods = "LEADER|CTRL",
		action = act.ActivateTabRelative(-1),
	},

	-- Previous tab
	{
		key = "p",
		mods = "LEADER|CTRL",
		action = act.ActivateTabRelative(1),
	},

	-- Close pane
	{
		key = "x",
		mods = "LEADER|CTRL",
		action = act.CloseCurrentPane({
			confirm = false,
		}),
	},

	-- Move tab left
	{
		key = "<",
		mods = "LEADER|SHIFT",
		action = act.MoveTabRelative(-1),
	},

	-- Move tab right
	{
		key = ">",
		mods = "LEADER|SHIFT",
		action = act.MoveTabRelative(1),
	},

	-- Rename tab
	-- {
	--   key = "r",
	--   mods = "LEADER",
	--   action = act.PromptInputLine({
	--     description = "Rename tab",
	--     action = wezterm.action_callback(function(window, pane, line)
	--       if line then
	--         window:active_tab():set_title(line)
	--       end
	--     end),
	--   }),
	-- },

	-- --------------------------------------------------------------------------
	-- DIRECT TAB SELECTION
	-- --------------------------------------------------------------------------

	-- {
	--   key = "1",
	--   mods = "CTRL",
	--   action = act.ActivateTab(0),
	-- },
	-- {
	--   key = "2",
	--   mods = "CTRL",
	--   action = act.ActivateTab(1),
	-- },
	-- {
	--   key = "3",
	--   mods = "CTRL",
	--   action = act.ActivateTab(2),
	-- },
	-- {
	--   key = "4",
	--   mods = "CTRL",
	--   action = act.ActivateTab(3),
	-- },
	-- {
	--   key = "5",
	--   mods = "CTRL",
	--   action = act.ActivateTab(4),
	-- },
	-- {
	--   key = "6",
	--   mods = "CTRL",
	--   action = act.ActivateTab(5),
	-- },
	-- {
	--   key = "7",
	--   mods = "CTRL",
	--   action = act.ActivateTab(6),
	-- },
	-- {
	--   key = "8",
	--   mods = "CTRL",
	--   action = act.ActivateTab(7),
	-- },
	-- {
	--   key = "9",
	--   mods = "CTRL",
	--   action = act.ActivateTab(-1),
	-- },

	-- --------------------------------------------------------------------------
	-- PANE RESIZING
	-- --------------------------------------------------------------------------

	-- {
	--   key = "h",
	--   mods = "LEADER|SHIFT",
	--   action = act.AdjustPaneSize({
	--     "Left",
	--     5,
	--   }),
	-- },
	-- {
	--   key = "j",
	--   mods = "LEADER|SHIFT",
	--   action = act.AdjustPaneSize({
	--     "Down",
	--     5,
	--   }),
	-- },
	-- {
	--   key = "k",
	--   mods = "LEADER|SHIFT",
	--   action = act.AdjustPaneSize({
	--     "Up",
	--     5,
	--   }),
	-- },
	-- {
	--   key = "l",
	--   mods = "LEADER|SHIFT",
	--   action = act.AdjustPaneSize({
	--     "Right",
	--     5,
	--   }),
	-- },

	-- --------------------------------------------------------------------------
	-- LAYOUT MANAGEMENT
	-- --------------------------------------------------------------------------

	-- Rotate panes
	{
		key = "r",
		mods = "LEADER|CTRL",
		action = act.RotatePanes("Clockwise"),
	},

	-- --------------------------------------------------------------------------
	-- FONT SIZE
	-- --------------------------------------------------------------------------

	{
		key = "=",
		mods = "CTRL|SHIFT",
		action = act.IncreaseFontSize,
	},
	{
		key = "-",
		mods = "CTRL|SHIFT",
		action = act.DecreaseFontSize,
	},
	{
		key = "Backspace",
		mods = "CTRL|SHIFT",
		action = act.ResetFontSize,
	},

	-- --------------------------------------------------------------------------
	-- FULLSCREEN
	-- --------------------------------------------------------------------------

	-- {
	--   key = "F11",
	--   mods = "CTRL|SHIFT",
	--   action = act.ToggleFullScreen,
	-- },

	-- --------------------------------------------------------------------------
	-- RELOAD CONFIG
	-- --------------------------------------------------------------------------

	-- {
	--   key = "l",
	--   mods = "LEADER|CTRL",
	--   action = act.ReloadConfiguration,
	-- },
	--
	-- -- --------------------------------------------------------------------------
	-- -- CLEAR SCROLLBACK
	-- -- --------------------------------------------------------------------------
	--
	-- {
	--   key = "Delete",
	--   mods = "CTRL|SHIFT",
	--   action = act.ClearScrollback("ScrollbackAndViewport"),
	-- },

	-- Open ~/.dotfiles in Neovim in a new tab
	{
		key = "d",
		mods = "LEADER",
		action = act.SpawnCommandInNewTab({
			args = { "nvim" },
			cwd = wezterm.home_dir .. "/.dotfiles",
		}),
	},
}) do
	table.insert(config.keys, key)
end

-- ============================================================================
-- COPY MODE
-- ============================================================================

-- extend defualt, bc G would not work without it
local copy_mode = config.key_tables.copy_mode or wezterm.gui.default_key_tables().copy_mode

for _, key in ipairs({
	-- Word navigation
	{ key = "w", mods = "NONE", action = act.CopyMode("MoveForwardWord") },
	{ key = "b", mods = "NONE", action = act.CopyMode("MoveBackwardWord") },
	{ key = "e", mods = "NONE", action = act.CopyMode("MoveForwardWordEnd") },

	-- TODO
	-- W = move right until whitespace, then skip whitespace
	-- B = move left across whitespace, then to start of previous non-whitespace sequence
	-- E = skip whitespace, then move to end of current/next non-whitespace sequence

	-- -- BIG word navigation (whitespace-delimited)
	-- Jump forward/backward by semantic zone
	{ key = "}", mods = "SHIFT", action = act.CopyMode("MoveForwardSemanticZone") },
	{ key = "{", mods = "SHIFT", action = act.CopyMode("MoveBackwardSemanticZone") },

	-- Line navigation
	{ key = "0", mods = "NONE", action = act.CopyMode("MoveToStartOfLine") },
	{ key = "^", mods = "NONE", action = act.CopyMode("MoveToStartOfLineContent") },
	{ key = "$", mods = "NONE", action = act.CopyMode("MoveToEndOfLineContent") },
}) do
	table.insert(copy_mode, key)
end

config.key_tables.copy_mode = copy_mode

return config
