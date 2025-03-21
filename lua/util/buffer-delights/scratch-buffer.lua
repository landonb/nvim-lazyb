-- vim:tw=0:ts=2:sw=2:et:ai:ft=lua
-- Author: Landon Bouma <https://tallybark.com/>
-- Project: https://github.com/landonb/nvim-lazyb#🧸

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

---@class lazyb.util.buffer-delights.scratch-buffer
local M = {}

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

-- FIXME: FTREQ: Port the source to Lua (TRYME: Compare various LLM outputs).

-- CXREF:
-- ~/.kit/nvim/embrace-vim/start/vim-buffer-delights/autoload/embrace/scratch.vim
pcall(function()
  vim.cmd(
    "source "
      .. vim.env.HOME
      .. "/.kit/nvim/embrace-vim/start/vim-buffer-delights/autoload/embrace/scratch.vim"
  )
end)

-- FIXME: Port g:embrace#windows#FocusCursorInNormalBufferWindow()
-- (to a different Lua file)
-- - NTHEN: Adjust gvim-open-kindness accordingly...
--   - though, ugh, how best to plumb that, ha...
--   - you could just call both??

pcall(function()
  vim.cmd(
    "source "
      .. vim.env.HOME
      .. "/.kit/nvim/embrace-vim/start/vim-buffer-delights/autoload/embrace/windows.vim"
  )
end)

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

-- function! g:embrace#scratch#CreateScratchWindow(type = '') abort
--   let l:oldwin = winnr()
--
--   let l:old_h = winheight(l:oldwin)
--
--   if a:type == 'log'
--     " Move cursor to bottom-right window.
--     wincmd b
--
--     below new
--   else
--     horizontal new
--   endif
--
--   let l:bufnr = bufnr()
--
--   if a:type == 'log'
--     wincmd J
--     10wincmd _
--     " See also |equalalways| and |CTRL-W_=|
--     set winfixheight
--   else
--     execute str2nr(l:old_h / 3) .. 'wincmd _'
--   endif
--
--   call g:embrace#scratch#SetupScratchBuffer()
--
--   " Don't name it, which would create a path for it
--   " (though won't write to it until you :write).
--   "  file event.log
--
--   " Return to previous window.
--   " - Nope. Might be second-to-last window b/c
--   "   wincmd's above.
--   "  wincmd p
--   execute l:oldwin .. 'wincmd w'
--
--   return l:bufnr
-- endfunction

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

-- " SAVVY: When you :bd a buffer, Vim refers to it as [No Name] in the
-- "   titlebar (though expand('%:p') returns empty string).
-- "   - After buftype=nofile, the title changes to [Scratch].
-- "   - But not when --noplugin — I think it's titlestring=%t that does it
-- "     (Vim returns [Scratch] for the "File name (tail)".
-- "        |statusline| |titlestring|
-- "      ~/.kit/nvim/landonb/vim-title-bar-time-of-day/plugin/title_bar_time_of_day.vim
-- " ALTLY:
-- "   " :wincmd b
-- "   "   \ | below new
-- "   "   \ | wincmd J
-- "   "   \ | 10wincmd _
-- "   "   \ | setlocal modifiable buftype=nofile bufhidden=hide noswapfile nobuflisted
-- "   " :h special-buffers
-- "   " :h put
-- "   " :h :w
-- "   " :h :file
-- "   " :h <mods>
-- "   command! -nargs=* -complete=shellcmd R new | setlocal buftype=nofile bufhidden=hide noswapfile | r !<args>
-- " REFER: |scratch-buffer|
-- " USYNC: See similar fcn. in project tray project.
-- function! g:embrace#scratch#SetupScratchBuffer() abort
--   set modifiable
--   setlocal buftype=nofile
--   " setlocal bufhidden=hide
--   setlocal bufhidden=wipe
--   setlocal noswapfile
--   setlocal nobuflisted
--   " setlocal readonly
-- endfunction

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

return M
