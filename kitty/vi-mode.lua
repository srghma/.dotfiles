local api = vim.api

-- ============================================================================
-- 1. VISUAL SETTINGS (Black Background & Line Numbers)
-- ============================================================================
vim.opt.termguicolors = true
vim.opt.number = false
vim.opt.relativenumber = false
vim.opt.cursorline = true
vim.opt.scrolloff = 5
vim.opt.wrap = false
vim.opt.laststatus = 0           -- Hide status bar
vim.opt.showmode = false         -- Hide "-- TERMINAL --"
vim.opt.ruler = false
vim.opt.scrollback = 100000
vim.opt.clipboard = "unnamedplus"
vim.opt.ignorecase = true
vim.opt.smartcase = true

-- FORCE BLACK BACKGROUND
vim.cmd [[
  highlight Normal guibg=#000000 guifg=white
  highlight SignColumn guibg=#000000
  highlight LineNr guibg=#000000
  highlight CursorLineNr guibg=#000000
  highlight EndOfBuffer guibg=#000000 guifg=#000000
]]

-- ============================================================================
-- 2. KEYMAPPINGS (Kakoune & Tmux Style)
-- ============================================================================
local map = vim.keymap.set
local opts = { noremap = true, silent = true }

-- Quit
map('n', 'q', '<cmd>qa!<cr>', opts)
map('n', '<Esc>', '<cmd>qa!<cr>', opts)
map('n', 'i', '<cmd>qa!<cr>', opts)

-- Kakoune Movements
map({'n', 'v'}, 'gh', '0', opts)
map({'n', 'v'}, 'gi', '^', opts)
map({'n', 'v'}, 'gl', 'g_', opts)
map({'n', 'v'}, 'gj', 'G', opts)
map({'n', 'v'}, 'gk', 'gg', opts)

-- Standard Vim Navigation
map('n', '<C-u>', '<C-u>zz', opts)
map('n', '<C-d>', '<C-d>zz', opts)

-- Copy/Paste (System Clipboard)
map('v', 'y', '"+y', opts)
map('v', 'Y', '"+y$', opts)
-- ============================================================================
-- 3. ANSI COLOR PARSING LOGIC
-- ============================================================================
vim.schedule(function()
  -- 1. Grab raw lines from current buffer (stdin)
  local cur_buf = api.nvim_get_current_buf()
  local lines = api.nvim_buf_get_lines(cur_buf, 0, -1, false)

  -- Pre-trim input: Remove trailing empty lines from source *before* feeding the terminal.
  -- This prevents the terminal channel from creating the empty lines in the first place.
  while #lines > 0 and lines[#lines]:match("^%s*$") do
    table.remove(lines)
  end

  -- 2. Create a clean new buffer for the terminal
  local term_buf = api.nvim_create_buf(false, true)

  -- 3. Open a "Terminal Channel" to interpret ANSI codes
  local chan = api.nvim_open_term(term_buf, {})

  -- 4. Feed lines into the terminal (renders colors)
  -- Note: We assume lines do not need an extra newline at the very end to avoid creating a phantom line.
  api.nvim_chan_send(chan, table.concat(lines, "\r\n"))

  -- 5. Swap buffers
  api.nvim_set_current_buf(term_buf)
  api.nvim_buf_delete(cur_buf, { force = true })

  -- 6. SCROLL LOGIC & CLEANUP
  local function trim_trailing_empty_lines()
    -- Force the terminal buffer to be modifiable so we can delete lines
    vim.bo[term_buf].modifiable = true

    local total_lines = api.nvim_buf_line_count(term_buf)
    local last_content_line = 0

    -- Scan backwards to find the actual content
    for i = total_lines, 1, -1 do
      local line = api.nvim_buf_get_lines(term_buf, i - 1, i, false)[1]
      -- Check if line has any visible content (not just whitespace)
      if line and line:match("%S") then
        last_content_line = i
        break
      end
    end

    -- Delete lines after the last content
    if last_content_line > 0 then
      if last_content_line < total_lines then
        api.nvim_buf_set_lines(term_buf, last_content_line, -1, false, {})
      end
    else
      -- If buffer is totally empty, just keep 1 empty line
      api.nvim_buf_set_lines(term_buf, 0, -1, false, {""})
      last_content_line = 1
    end

    return last_content_line
  end

  local last_line = trim_trailing_empty_lines()

  -- 7. Position cursor at the end of the content
  api.nvim_win_set_cursor(0, {last_line, 0})
  vim.cmd("normal! $")

  -- 8. Ensure mappings work and we are in Normal mode
  vim.cmd("stopinsert")
end)
