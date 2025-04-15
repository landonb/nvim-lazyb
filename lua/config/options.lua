-- vim:tw=0:ts=2:sw=2:et:ai:ft=lua
-- Author: Landon Bouma <https://tallybark.com/>
-- Project: https://github.com/landonb/nvim-lazyb#🧸

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

-- Options are automatically loaded before lazy.nvim startup
-- CXREF:
-- ~/.local/share/nvim/lazy/LazyVim/lua/lazyvim/config/options.lua
-- ~/.local/share/nvim/lazy/LazyVim/lua/lazyvim/config/init.lua
-- REFER: Default options that are always set:
-- https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

if vim.g.neovide then
  -- FTREQ/2025-02-25: Add macOS literal Option character maps.
  vim.g.neovide_input_macos_option_key_is_meta = "both"

  -- Inhibit cursor animation when switching to/from cmdline, which also
  -- happens as a side effect when some maps run various commands.
  -- - OWELL: Unfortunately, doesn't work with Noice's command line float.
  vim.g.neovide_cursor_animate_command_line = false
  -- ALTLY: Disable all Neovide animations, and rely on various plugin
  -- animations.
  -- - REFER: See Snacks animations.
  --   - If running LazyVim, this'll be set:
  --       vim.g.snacks_animate = true
  vim.g.neovide_cursor_animation_length = 0
  vim.g.neovide_cursor_trail_size = 0
  -- SAVVY: Disabling scroll animation makes <PageUp>/<PageDown> a little
  -- less pleasant.
  if false then
    vim.g.neovide_scroll_animation_length = 0
  end
end

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

local opt = vim.opt

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

require("util.mswin").setup()

-- Unset |'clipboard'|, otherwise Visual/Select mode
-- <Del>, etc., overwrites clipboard registers.
-- - Neovim default: clipboard = "".
-- - LazyVim default: clipboard = "unnamedplus" (unless vim.env.SSH_TTY).
-- - We'll define our own <C-x>, <C-c>, <C-v>, etc., map commands which
--   use the clipboard registers when appropriate (see util/mswin.lua).
opt.clipboard = ""

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

-- |vim.o.conceallevel|
--
-- LazyVim <Leader>uc toggles Conceal Level, which defaults 2.
--
-- Except I find this makes Markdown and Vim help files more
-- difficult to edit.

opt.conceallevel = 0

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

-- LazyVim enables cursorline. I've historically kept if off...
-- but we'll give it a whirl.
--  opt.cursorline = false

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

-- Adjust :Gvdiffsplit behavior.
-- ISOFF: I don't use :Gdiffsplit (I prefer Meld), and this option
-- doesn't change any behavior (though I might be testing it wrong).
-- - CXREF:
--   ~/.kit/nvim/DepoXy/start/vim-depoxy/plugin/set-diffopt-hiddenoff.vim
--
--  vim.opt.diffopt:append("hiddenoff")

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

-- A statusline for every window!
-- - LazyVim default:
--   opt.laststatus = 3 -- global statusline
opt.laststatus = 2

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

-- Disable relative line numbers (also: <leader>uL)
--  opt.relativenumber = false

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

-- ISOFF: LazyVim sets scrolloff to 4, which sometimes helps (e.g.,
-- showing more context when cursor approaches window top or bottom),
-- but it also sometimes hinders (e.g., <Ctrl-PageDown> doesn't go
-- to the last line, but especially double-clicking in the scrolloff
-- boundary does not work, and it causes window to scroll, which is
-- annoying me and I'm not sure I can remember not to click within 4
-- lines of the window boundary (especially when the top or bottom of
-- the buffer is a special case where then the window *won't* scroll)).

opt.scrolloff = 0

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

-- ISOFF: At first I didn't necessarily like that new windows opened
-- below — mostly I didn't necessarily like that help windows opened
-- below.
-- - But that behavior has been growing on me...
--   - In any case, here's the simple switch to open help windows above,
--     etc.
--
--  -- Put new windows above current.
--  opt.splitbelow = false

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

-- LazyVim disables wrap by default, which I don't generally mind
-- for most buffers
-- - But it's annoying in the snacks view, especially <Leader>n to
--   look at notification history, oftentimes I cannot read the
--   full error output, but have to move the cursor to the view
--   window and then scroll right.
opt.wrap = true

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

-- CXREF: Optional user config:
-- ~/.config/nvim_lazyb/lua/config/options-client.lua
pcall(function()
  require("config.options-client").setup()
end)

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
