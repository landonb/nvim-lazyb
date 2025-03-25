-- vim:tw=0:ts=2:sw=2:et:ai:ft=lua
-- Author: Landon Bouma <https://tallybark.com/>
-- Project: https://github.com/landonb/nvim-lazyb#🧸

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

---@class lazyb.util.edit-juice.transpose
local M = {}

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

-- ------------------------------------------------------
-- Character Transposition
-- ------------------------------------------------------

-- SAVVY: `X` deletes [count] chars. before the cursor,
-- but when the cursor is on the first column, 'X' is a
-- no-op, and then the 'p' puts what was previously in
-- the @" register. So use 'Xp' if the cursor is anywhere
-- but the first column, but use 'xp' otherwise.

function M.transpose_characters()
  if not vim.bo.modifiable then
    print("Cannot modify this buffer")

    return
  end

  local cursor_col = vim.fn.col(".")

  if 1 == cursor_col then
    vim.fn.execute("normal! xp")
  else
    vim.fn.execute("normal! Xp")
  end
end

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

return M
