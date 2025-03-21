-- vim:tw=0:ts=2:sw=2:et:ai:ft=lua
-- Author: Landon Bouma <https://tallybark.com/>
-- Project: https://github.com/landonb/nvim-lazyb#🧸

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

---@class lazyb.util.buffer-delights.normal-buffer
local M = {}

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

function M.IsNormalBuffer(ref_bufnr)
  -- Note that using special buffers (see :bufname for list)
  -- such as "%" (name of current buffer) doesn't work for
  -- &modifiable, which reports false (0) for modifiables.
  -- - DUNNO: I'm didn't investigate. It's just what I see.
  local bufnr = vim.fn.bufnr(ref_bufnr)

  local ftype = vim.fn.getbufvar(bufnr, "&filetype")

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
        .. "\n&buftype: " .. vim.fn.getbufvar(bufnr, "&buftype")
        .. "\n&previewwindow: " .. vim.fn.getbufvar(bufnr, "&previewwindow")
        .. "\n&modifiable: " .. vim.fn.getbufvar(bufnr, "&modifiable")
        .. "\nbuflisted: " .. vim.fn.buflisted(bufnr)
        .. "\n&filetype: " .. ftype
        .. "\nbufname: " .. vim.fn.bufname(bufnr)
    )
  end

  if
    false
    or vim.fn.getbufvar(bufnr, "&buftype") ~= ""
    or vim.fn.getbufvar(bufnr, "&previewwindow") ~= 0
    or vim.fn.getbufvar(bufnr, "&modifiable") ~= 1
    or vim.fn.buflisted(bufnr) ~= 1
    or ftype == "qf"
    or ftype == "git"
    or ftype == "fugitiveblame"
    or vim.fn.bufname(bufnr) == "-MiniBufExplorer-"
  then
    return false
  end

  return true
end

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

return M
