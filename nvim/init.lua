local function escape(str)
  -- You need to escape these characters to work correctly
  local escape_chars = [[;,."|\]]
  return vim.fn.escape(str, escape_chars)
end

-- Recommended to use lua template string
-- local en = [[`qwertyuiop[]asdfghjkl;'zxcvbnm]]
-- local en_shift = [[~QWERTYUIOP{}ASDFGHJKL:"ZXCVBNM<>]]
-- local ru = [[ёйцукенгшщзхъфывапролджэячсмить]]
-- local ru_shift = [[ËЙЦУКЕНГШЩЗХЪФЫВАПРОЛДЖЭЯЧСМИТЬБЮ]]
-- local ua       = [['йцукенгшщзхїфівапролджеячсмитбю]]
-- local ua_shift = [[ʼЙЦУКЕНГШЩЗХЇФІВАПРОЛДЖЕЯЧСМИТЬБЮ]]

-- local en = [[qwertyuiop[]asdfghjkl:'zxcvbnm,]]
-- local en_shift = [[~QWERTYUIOP{}ASDFGHJKL;"ZXCVBNM<>?]]
-- local ua       = [[йцукенгшщзхїфівапроджєячсмитьбю]]
-- local ua_shift = [[ʼЙЦУКЕНГШЩЗХЇФІВАПРОЛДЖЄЯЧСМИТЬБЮ,]]

-- local en = [[]]
-- local en_shift = [[]]
-- local ua       = [[]]
-- local ua_shift = [[]]

vim.opt.langmap = table.concat({
  "йq,цw,уe,кr,еt,нy,гu,шi,щo,зp,х[,ї],фa,іs,ыs,вd,аf,пg,рh,оj,лk,дl,ж:,є',яz,чx,сc,мv,иb,тn,ьm,ю." -- ,б,",
}, ",")

-- Lua version
vim.keymap.set('n', 'о', 'gj', { noremap = true, expr = false })
vim.keymap.set('n', 'л', 'gk', { noremap = true, expr = false })

-- vim.opt.langmap = vim.fn.join({
--   -- | `to` should be first     | `from` should be second
--   -- escape(ru_shift) .. ';' .. escape(en_shift),
--   -- escape(ru) .. ';' .. escape(en),
--   escape(ua_shift) .. ';' .. escape(en_shift),
--   escape(ua) .. ';' .. escape(en),
-- }, ',')

-- vim.opt.keymap = "ukrainian-jcuken"

--------------------------------------------------

-- This file simply bootstraps the installation of Lazy.nvim and then calls other files for execution
-- This file doesn't necessarily need to be touched, BE CAUTIOUS editing this file and proceed at your own risk.
local lazypath = vim.env.LAZY or vim.fn.stdpath "data" .. "/lazy/lazy.nvim"

if not (vim.env.LAZY or (vim.uv or vim.loop).fs_stat(lazypath)) then
  -- stylua: ignore
  local result = vim.fn.system({ "git", "clone", "--filter=blob:none", "https://github.com/folke/lazy.nvim.git", "--branch=stable", lazypath })
  if vim.v.shell_error ~= 0 then
    -- stylua: ignore
    vim.api.nvim_echo({ { ("Error cloning lazy.nvim:\n%s\n"):format(result), "ErrorMsg" }, { "Press any key to exit...", "MoreMsg" } }, true, {})
    vim.fn.getchar()
    vim.cmd.quit()
  end
end

vim.opt.rtp:prepend(lazypath)

-- validate that lazy is available
if not pcall(require, "lazy") then
  -- stylua: ignore
  vim.api.nvim_echo({ { ("Unable to load lazy from: %s\n"):format(lazypath), "ErrorMsg" }, { "Press any key to exit...", "MoreMsg" } }, true, {})
  vim.fn.getchar()
  vim.cmd.quit()
end

require "lazy_setup"
require "polish"
