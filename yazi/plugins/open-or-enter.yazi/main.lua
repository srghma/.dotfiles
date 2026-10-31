--- @sync entry

return {
  entry = function()
    local h = cx.active.current.hovered

    if not h then
      return
    end

    ya.emit(h.cha.is_dir and "enter" or "open", {})
  end,
}
