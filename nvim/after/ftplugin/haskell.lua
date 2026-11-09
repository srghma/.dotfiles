local move_splits_to_left = function(positions)
  local res = {}
  -- Start from index 2 to have first argument on the same line
  -- End with second to last to move right bracket on separate line
  for i = 2, #positions - 1 do
    table.insert(res, { line = positions[i].line, col = positions[i].col - 1 })
  end
  table.insert(res, positions[#positions])
  return res
end

vim.b.minisplitjoin_config = { split = { hooks_pre = { move_splits_to_left } } }
