-- vim:tw=0:ts=2:sw=2:et:ai:ft=lua
-- Author: Landon Bouma <https://tallybark.com/>
-- Project: https://github.com/landonb/nvim-lazyb#🧸

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

---@class lazyb.util.edit-juice.paste-swap
local M = {}

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

-- SAVVY: Clear the package cache to pick up changes:
--   :lua package.loaded["util.edit-juice.paste-swap"] = nil

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

-- ------------------------------------------------------
-- Swap selection and clipboard contents
-- ------------------------------------------------------

-- 2021-01-31: Trying a Clipboard Paste-Copy-Swapper.
-- - REFER/2025-04-14: See yanky.nvim, seems like a better approach.
--
-- Ref:
--
--   https://stackoverflow.com/questions/1502218/copy-from-one-register-to-another
--   https://vim.fandom.com/wiki/Comfortable_handling_of_registers
--
-- Use Case: I want to highlight something to paste over it, but I want
--           selection to become next clipboard contents.
--
-- - I.e., press `\dS` to swap highlighted text with clipboard contents.
-- How it works:
--   "ax       Delete selection and store deleted text in register 'a'.
--   "+gP      Put text (from @+ register, aka Paste clipboard), and leave
--             the cursor after the pasted text (so ends in insert mode).
--   :let ...  Swap @a and @+ registers, using @x for temporary storage.
--             (The Vim tip has an example where `\s` rotates @", @a, and @b,
--              which seems cool, but I'm not sure I'd use it; I mean, I've
--              survived almost two decades using just the 1 clipboard value!
--              So I'm not sure that I'd know how to manage *3* such values!!
--              I'm not even sure I'll use this mapping that often; it's just
--              something every once in a while I think about... and who does
--              not love to grind their Vim teeth every once in a while to put
--              out a new, slightly novel mapping?)
-- - Thanks @quickcougar for the great find! This was not working with `put`.
--   - Copy something with <Ctrl-c>, run :reg, and it updates three registers:
--     <""> <"*> <"+> (without the <>'s, which are just a highlight jammer)
--     - "": unnamed register (*always* filled on "d", "c", "s", "x" and "y")
--     - "*: clipboard (not system)
-- CALSO/2024-12-10: See also YankRing
--   https://github.com/vim-scripts/YankRing.vim
-- - Or consider using built-in numbered registers that contain last 9 deletes.

function M.clipboard_paste_rotate()
  print(vim.inspect(vim.api.nvim_get_mode()))
  -- Returns: { blocking = true|false, mode = <mode> }
  local mode = vim.api.nvim_get_mode().mode:sub(1, 1)
  if mode ~= "v" or mode ~= "s" then
    vim.cmd('normal "ax"+gP')
    print("done")
  end
  vim.cmd('let @x=@+ | let @+=@a | let @a=@x | let @"=@+ | let @*=@+')
end

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

return M
