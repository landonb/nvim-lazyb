-- vim:tw=0:ts=2:sw=2:et:ai:ft=lua
-- Author: Landon Bouma <https://tallybark.com/>
-- Project: https://github.com/landonb/nvim-lazyb#🧸

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

local map = vim.keymap.set

-- *** Insert today's date using iabbrev and map

-- Note that completing an iabbrev requires <CR>, space, or punctuation
-- (or <C=]> expect dubs_edit_juice.vim assigns an imap to that, so it
-- doesn't work).
--
-- - So depending on the iabbrev, you might not want a carriage return,
--   punction, or a space after the inserted text.
--
-- - But for some iabbrev, it works out okay!
--
--   - For instance, I use the `TTT` abbreviation to enter todays'
--     date, and I almost always follow that with a colon. Which
--     is perfect, because you can type `TTT:` and you'll end up
--     with, e.g.,
--
--       2024-12-11:{cursor}

-- REFER: An old dog can learn new tricks,
--        - like the P in <CR>P
--        - and the <expr> in iabbrev <expr>.
--
-- http://vim.wikia.com/wiki/Insert_current_date_or_time
--
-- “The uppercase P at the end inserts before the current character,
--  which allows datestamps inserted at the beginning of an existing line.”
--
--   " :nnoremap <F5> "=strftime("%Y-%m-%d")<CR>P
--   :inoremap <F5> <C-R>=strftime("%Y-%m-%d")<CR>
--
-- REFER: Re: <expr>, see:
-- http://vimdoc.sourceforge.net/htmldoc/map.html#:map-expression

-- -------------------------------------------------------------------

-- YYYY-MM-DD
vim.cmd([[iabbrev <expr> TTT strftime("%Y-%m-%d")]])

-- YYYY_MM_DD
vim.cmd([[iabbrev <expr> TTT_ strftime("%Y_%m_%d")]])

-- YYYY-MM-DD HH:MM
vim.cmd([[iabbrev <expr> TTTtt strftime("%Y-%m-%d %H:%M")]])
-- PRIVY/MAYBE/2024-08-07: Remove this abbrev?
-- - I can't recall the last time I used it.
-- - 2024-12-11: Though `::: ` is easier than `TTTtt:`, perhaps.
--   - Probably I just remember `TTTtt` and need to wire-in :::.
--
-- (lb): 2020-09-21: I keep typing `:::`, might as well wire it.
vim.cmd([[iabbrev <expr> ::: strftime("%Y-%m-%d %H:%M:")]])

-- YYYY-MM-DDTHH:MM
vim.cmd([[iabbrev <expr> TTTTtt strftime("%Y-%m-%dT%H:%M")]])

-- HH:MM
vim.cmd([[iabbrev <expr> ttt strftime("%H:%M")]])

-- DUNNO/2025-03-03: These don't work in LazyVim, but they work in nvim-depoxy.
-- TRYME/2025-02-07: Trying a quicker abbreviation, under the assumption
-- that you'd never type comma *not* followed by a space in text or code.
-- - BEGET: https://www.reddit.com/r/neovim/comments/16mijcz/comment/k18jbee/
--   https://www.reddit.com/r/neovim/comments/16mijcz/anyone_here_use_iabbrev/
--   - FOREX:
--       vim.cmd("iabbrev <expr> ,d strftime('%Y-%m-%d')")
--       vim.cmd("iabbrev <expr> ,t strftime('%Y-%m-%dT%TZ')")
vim.cmd([[iabbrev <expr> ,t strftime("%Y-%m-%d")]])
vim.cmd([[iabbrev <expr> ,T strftime("%Y-%m-%d %H:%M")]])

-- -------------------------------------------------------------------

-- PRIVY/MAYBE/2024-12-11 01:25: Use \d{?} instead?
-- - Also, what about <F12> at \d{?} also?

-- /YYYY-MM-DD HH:MM:
--
-- TRYME/2023-06-03: For adding datetime after a FIVER.
--
-- - Type `FIVER\T` and you get `FIVER/TTT: `
--
-- - Type `FIVER<F12>` and you get `FIVER/TTTtt: `
--
-- - The author had been typing 'FIXME/TTT:` and 'FIXME/TTTtt:'
--   often enough that I wanted something quicker.
--
-- - I tried using the abbreviation, '::', but the '/' after the FIVER is
--   not a keyword character, and neither is ':', so an iabbrev doesn't work.
map(
  { "i" },
  "<localleader>t",
  [[<C-R>=strftime("/%Y-%m-%d: ")<CR>]],
  { desc = "Insert YYYY-MM-DD", noremap = true, silent = true }
)
map(
  { "i" },
  "<F12>",
  [[<C-R>=strftime("/%Y-%m-%d %H:%M: ")<CR>]],
  { desc = "Insert YYYY-MM-DD %H:%M", noremap = true, silent = true }
)
