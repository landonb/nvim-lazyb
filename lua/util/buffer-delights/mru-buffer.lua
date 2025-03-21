-- vim:tw=0:ts=2:sw=2:et:ai:ft=lua
-- Author: Landon Bouma <https://tallybark.com/>
-- Project: https://github.com/landonb/nvim-lazyb#🧸

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

---@class lazyb.util.buffer-delights.mru-buffer
local M = {}

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

-- ------------------------------------------------------
-- MRU Buffer Jumping
-- ------------------------------------------------------

-- Vim has 2 built-in MRU buffer jumpers:
--
--   :help edit_#
--   - Edit the [count]th buffer (as shown by |:files|).
--     This command does the same as [count] CTRL-^.
--     But `:e #` doesn't work if the alternate buffer doesn't
--     have a file name, while CTRL-^ still works then.
--
--   :help CTRL-6
--   :help CTRL-^*
--   - It is equivalent to `:e #`, except that it also
--     works when there is no file name.
--
-- But here we bake our own approach, to deal with
-- special buffers properly.

local isNormalBuffer = require("util.buffer-delights.normal-buffer").IsNormalBuffer

function M.Switch_MRU_Safe()
  -- Check the current buffer for normality.
  if not isNormalBuffer("%") then
    vim.notify("Special buffer has no MRU")
  -- The special '#' is what Vim calls the alternate-file.
  elseif vim.fn.expand("#") ~= "" then
    -- Check the alternate buffer for normality.
    if not isNormalBuffer("#") then
      -- FIXME: Replace nvim-lazyb print() usage with vim.notify().
      vim.notify("MRU is a special buffer; cannot switch")
    else
      vim.cmd([[edit #]])
    end
  else
    vim.notify("No MRU buffer yet")
  end
end

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

return M
