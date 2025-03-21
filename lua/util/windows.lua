-- vim:tw=0:ts=2:sw=2:et:ai:ft=lua
-- Author: Landon Bouma <https://tallybark.com/>
-- Project: https://github.com/landonb/nvim-lazyb#🧸

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

---@class lazyb.util.windows
local M = {}

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

function M.close_windows_by_ft(opts)
  return vim.tbl_filter(function(winid)
    -- DUNNO: Need to check window ID again, though unsure how it
    -- could become invalid between list_wins and tbl_filter!
    -- - Otherwise you might see an error, e.g.:
    --     E5108: Error executing lua: /Users/.../windows.lua:41:
    --     Invalid window id: 1018
    -- - "But where'd it go?!"
    if not vim.api.nvim_win_is_valid(winid) then
      return false
    end
    local bufnr = vim.api.nvim_win_get_buf(winid)
    local winft = vim.api.nvim_get_option_value("filetype", { buf = bufnr })
    if winft == opts.filetype then
      vim.api.nvim_win_close(winid, false)

      return true
    end

    return false
  end, vim.api.nvim_tabpage_list_wins(0))
end

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

function M.last_visible_window()
  -- -- THANX:
  -- -- https://www.reddit.com/r/neovim/comments/thynt9/what_api_to_get_the_current_count_of_windows/
  -- local wc = 0
  -- local windows = vim.api.nvim_tabpage_list_wins(0)
  --
  -- for _, win in pairs(windows) do
  --   local cfg = vim.api.nvim_win_get_config(win)
  --   local ft = vim.api.nvim_get_option_value("filetype", { buf = vim.api.nvim_win_get_buf(win) })
  --
  --   if (cfg.relative == "" or cfg.external == false) and ft ~= "qf" then
  --     wc = wc + 1
  --   end
  -- end
end

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

return M
