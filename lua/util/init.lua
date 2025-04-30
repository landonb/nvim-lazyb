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

M.lazy_build_fork = function(proj_dir, upstream)
  return function()
    vim.fn.system([[
      cd -- "]] .. vim.fn.stdpath("data") .. "/lazy/" .. proj_dir .. [[" &&
      git fetch origin &&
      git checkout ]] .. upstream .. [[ &&
      git merge --ff-only origin/]] .. upstream .. [[ &&
      git checkout liminal &&
      git rebase ]] .. upstream .. [[
      ]])
  end
end

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

function M.augroup(name)
  return vim.api.nvim_create_augroup("lazyb_" .. name, { clear = true })
end

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

-- HSTRY: I used this to inspect the which-key popup, because
-- you cannot run a :colon command when it's showing (it'll be
-- dismissed when you type `:`).
-- - USAGE: To include which-key windows, run via defer_fn, e.g.,
--     lua vim.defer_fn(function() vim.cmd("InspectWindows") end, 2000)
--   then press <Leader> or <LocalLeader> to show which-key.
--   - SAVVY: which-key window and buffer characteristics:
--     modifiable: false / relative: editor / win_gettype: popup / filetype: wk
-- - REFER: Note there are (at least) two ways to check if a
--   window is floating:
--   - Check if window is not popup:
--       vim.api.nvim_win_get_config(winid).relative == ""
--   - Check if window is not popup or otherwise special:
--       vim.fn.win_gettype(winnr) == ""
vim.api.nvim_create_user_command("InspectWindows", function()
  -- CALSO: nvim_list_wins fetches all window IDs from all tabpages.
  for _, winid in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    local bufnr = vim.api.nvim_win_get_buf(winid)
    -- stylua: ignore
    print("winid:", winid, "/ bufnr:", bufnr,
      "/ modifiable:", vim.api.nvim_get_option_value("modifiable", { buf = bufnr }),
      "/ relative:", vim.api.nvim_win_get_config(winid).relative,
      "/ win_gettype:", vim.fn.win_gettype(winid),
      "/ filetype:", vim.bo[bufnr].filetype
    )
  end
end, { desc = "Print info about each window on current tabpage" })

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

return M
