-- vim:tw=0:ts=2:sw=2:et:ai:ft=lua
-- Author: Landon Bouma <https://tallybark.com/>
-- Project: https://github.com/landonb/nvim-lazyb#🧸

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

---@class lazyb.util.edit-juice
local M = {}

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

-- Closing a floating window isn't quite the same as deleting a buffer.
-- - The latter won't close the window it's in.
function M.close_floats_or_delete_buffer()
  -- REMEM: vim.api.nvim_win_get_number(0) is 1-based winnr().
  local window_id = vim.api.nvim_tabpage_get_win(0)
  local force = false
  local floats = vim.tbl_filter(function(winid)
    -- Check for floating windows, except for certain windows.
    -- - Skip Snacks Explorer windows:
    --   snacks_picker_list, snacks_picker_input, snacks_picker_preview
    -- - Skip notification toast window: snacks_notif
    --   (which I thought was a Noice window, huh).
    local winbuf = vim.api.nvim_win_get_buf(winid)
    return vim.api.nvim_win_get_config(winid).relative ~= ""
      and not vim.startswith(vim.bo[winbuf].filetype, "snacks_picker_")
      and vim.bo[winbuf].filetype ~= "snacks_notif"
  end, vim.api.nvim_tabpage_list_wins(0))
  if #floats > 0 then
    -- Close inactive floating window(s) (ALTLY: :fclose!).
    for _, winid in ipairs(floats) do
      vim.api.nvim_win_close(winid, force)
    end
  elseif vim.api.nvim_win_get_config(window_id).relative ~= "" then
    -- Close active floating window (ALTLY: :fclose!), regardless
    -- of filetype (e.g., close Snacks Explorer if active).
    vim.api.nvim_win_close(window_id, force)
  else
    -- Not quite the same as closing a window...
    local winbuf = vim.api.nvim_win_get_buf(window_id)
    if vim.bo[winbuf].bufhidden == "wipe" and vim.bo[winbuf].modified then
      -- Beware :Bdelete errors, e.g., if you create a new buffer
      -- and change it, but "wipe" enabled, then try to close it:
      --   E89: No write since last change for buffer 1234 (add ! to override)
      -- - But because the silent!, user actually sees nothing.
      -- - INERT/2025-10-07: Should we use Noice error popup?
      print("Ope! Cannot close modified bufhidden buffer")
    else
      vim.cmd("silent! Bdelete")
    end
  end
end

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

return M
