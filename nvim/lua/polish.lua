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

