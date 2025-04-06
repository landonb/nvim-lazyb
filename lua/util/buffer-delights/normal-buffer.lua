-- vim:tw=0:ts=2:sw=2:et:ai:ft=lua
-- Author: Landon Bouma <https://tallybark.com/>
-- Project: https://github.com/landonb/nvim-lazyb#🧸

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

---@class lazyb.util.buffer-delights.normal-buffer
local M = {}

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

-- FIXME: Need window ID to check &previewwindow.
--
-- - Maybe rename IsNormalBuffer → IsNormalWindow and pass, e.g.,
--     vim.api.nvim_win_get_number(0)
--   And then:
--     local bufnr = vim.api.nvim_win_get_buf(winid)
--     local previewwindow = vim.api.nvim_get_option_value("previewwindow", { win = winid })

function M.IsNormalBuffer(ref_bufnr)
  local bufnr = vim.fn.bufnr(ref_bufnr)

  local filetype = vim.fn.getbufvar(bufnr, "&filetype")

  -- REFER: Use vim.api.nvim_buf_get_name(), not vim.fn.bufname().
  local bufname = vim.api.nvim_buf_get_name(bufnr)

  -- REFER: Use vim.api.nvim_get_option_value(), not vim.fn.getbufvar().
  local buftype = vim.api.nvim_get_option_value("buftype", { buf = bufnr })
  local modifiable = vim.api.nvim_get_option_value("modifiable", { buf = bufnr })
  -- REFER: Use vim.api.nvim_get_option_value(), not vim.fn.buflisted().
  local buflisted = vim.api.nvim_get_option_value("buflisted", { buf = bufnr })

  -- SAVVY: Don't avoid user help file window, i.e., if user is
  -- editing their own plugin's help file.
  -- - So not this:
  --     or ftype == "help"
  -- But rely on &modifiable instead (which is 0 for Vim help docs)
  -- to not open files in a *Vim* help window.

  -- PRIVY:
  if false then
    -- stylua: ignore
    print(
      ""
        .. "bufnr: " .. bufnr
        .. "\n&buftype: " .. buftype
        .. "\n&previewwindow: " .. vim.fn.getbufvar(bufnr, "&previewwindow")
        .. "\n&modifiable: " .. modifiable
        .. "\nbuflisted: " .. buflisted
        .. "\n&filetype: " .. filetype
        .. "\nbufname: " .. bufname
    )
  end

  if
    false
    or buftype ~= ""
    or vim.fn.getbufvar(bufnr, "&previewwindow") ~= 0
    or not modifiable
    or not buflisted
    or filetype == "qf"
    or filetype == "git"
    or filetype == "fugitiveblame"
    or bufname == "-MiniBufExplorer-"
  then
    return false
  end

  return true
end

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

return M
