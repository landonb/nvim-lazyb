-- vim:tw=0:ts=2:sw=2:et:ai:ft=lua
-- Author: Landon Bouma <https://tallybark.com/>
-- Project: https://github.com/landonb/nvim-lazyb#🧸

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

---@class lazyb.util.edit-juice
local M = {}

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
