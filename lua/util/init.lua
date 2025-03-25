-- vim:tw=0:ts=2:sw=2:et:ai:ft=lua
-- Author: Landon Bouma <https://tallybark.com/>
-- Project: https://github.com/landonb/nvim-lazyb#🧸

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

-- SPIKE: Does using such a generic name conflict with plugins?
-- - E.g., `require("util").foo` vs. `require("lazyb.util").foo`?

---@class lazyb.util
local M = {}

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

-- FTREQ: Pass in specs instead, and get path that specs object.

M.lazy_build_fork = function(proj_dir)
  return function()
    vim.fn.system([[
      cd -- "]] .. vim.fn.stdpath("data") .. "/lazy/" .. proj_dir .. [[" &&
      git checkout liminal &&
      git fetch origin &&
      git rebase origin/main
      ]])
  end
end

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

function M.augroup(name)
  return vim.api.nvim_create_augroup("lazyb_" .. name, { clear = true })
end

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

return M
