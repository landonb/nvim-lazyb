-- vim:tw=0:ts=2:sw=2:et:ai:ft=lua
-- Author: Landon Bouma <https://tallybark.com/>
-- Project: https://github.com/landonb/nvim-lazyb#🧸

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

---@class lazyb.util.edit-juice.delete-backward
local M = {}

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

function M.cursor_friendly_indent(direction)
  local sol = vim.o.startofline
  vim.o.startofline = false

  local vcol = vim.fn.virtcol(".")
  if direction > 0 then
    vim.cmd([[normal! >>]])
    vim.cmd([[exe "normal!" .. (]] .. vcol .. [[ + shiftwidth()) .. "|"]])
  else
    vim.cmd([[normal! <<]])
    vim.cmd([[exe "normal!" .. (]] .. vcol .. [[ - shiftwidth()) .. "|"]])
  end

  vim.o.startofline = sol
end

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

return M
