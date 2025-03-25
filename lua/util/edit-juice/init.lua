-- vim:tw=0:ts=2:sw=2:et:ai:ft=lua
-- Author: Landon Bouma <https://tallybark.com/>
-- Project: https://github.com/landonb/nvim-lazyb#🧸

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

---@class lazyb.util.edit-juice
local M = {}

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

-- REFER: |undo-break| Create undo break, aka undo close block, using either:
--   let &g:undolevels = &g:undolevels
-- - Or |i_CTRL-G_u|:
--     exec "normal i\<C-g>u"
--
-- - WRONG: The Lua approach does not create undo blocks:
--     vim.g.undolevels = vim.g.undolevels
-- - QWRKY: The i_CTRL-G_u approach is quirky, because cursor maths.
--   - That is, the normal command moves the cursor one of the left,
--     except when it was in the first column, and to move it back
--     requires distinguishing whether cursor was in the first or
--     final column, or somewhere in between.
--   - ALTLY: Here's the <Ctrl-G>u approach, though I'm not
--     convinved that it's fullproof.
--
--       -- The normal! call below moves the cursor one to the left,
--       -- except for the first column, and `normal l` fixes the cursor
--       -- except for the final column, which also needs to set_cursor.
--       local mode = vim.api.nvim_get_mode().mode:sub(1, 1)
--       local curpos = vim.fn.getcurpos()
--       local i_curswant = 5 -- 1-based Lua arrays
--       local curswant = curpos[i_curswant]
--       local last_col = vim.fn.virtcol("$")
--       -- print("mode:", mode, "curswant:", curswant, "last_col:", last_col)
--
--       vim.cmd([[exec "normal! i\<C-g>u"]])
--
--       if curswant > 1 then
--         vim.cmd([[normal l]])
--         if (mode == "i" and curswant >= last_col)
--           or (mode == "n" and (curswant + 1) >= last_col)
--         then
--           M.set_cursor_at_end_of_line()
--         end
--       end

function M.undo_break()
  -- DUNNO: This doesn't create an undo block. E.g., type something,
  -- then <Ctrl-W>, and the Undo restores both edits:
  --  vim.g.undolevels = vim.g.undolevels
  vim.cmd([[let &g:undolevels = &g:undolevels]])
end

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

-- An Insert mode <C-]> that doesn't quite work well enough.
-- - Behaves like default <C-]>, which completes an iabbrev.
-- - Also adds Normal mode <C-]> behavior: When cursor is
--   over a keyword, this jumps to the tag def'n.
-- - ISOFF: However, there's a second or two delay after iabbrev
--   completion with <Ctrl-]>. The cursor stays in Normal mode
--   for a second or two before changing back to Insert mode
--   (possibly the pcall and expand(<cword>), oh well).
-- - In any case, this is all quite silly. I think mostly I
--   wanted to see if I could make it work...
if false then
  local wk = require("which-key")
  wk.add({
    mode = { "i" },
    "<C-]>",
    [[<C-]><C-O>:lua require("util.edit-juice").jump_to_tag_defn()<CR>]],
    desc = "Jump to tag def'n",
  })

  function M.jump_to_tag_defn()
    -- Am I doing this wrong? Calling <C-]> from rhs works, but not this:
    --   vim.cmd([[exec "normal \<C-]>"]])
    local success, cword = pcall(function()
      return vim.fn.expand("<cword>")
    end)
    if success and cword and cword:len() > 0 then
      vim.fn.execute("tag " .. cword)
    end
  end
end

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

return M
