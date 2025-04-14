-- vim:tw=0:ts=2:sw=2:et:ai:ft=lua
-- Author: Landon Bouma <https://tallybark.com/>
-- Project: https://github.com/landonb/nvim-lazyb#🧸

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

local map = vim.keymap.set

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

-- Start selection on shifted special keys, akin to `set keymodel=startsel`,
-- but with an explicit `set selection=exclusive`, to avoid wonky behavior.
-- - Specifically, using selection=exclusive in snippet mode impairs <Tab>,
--   such that typing to replace the snippet selection leaves the trailing
--   character from the placeholder text.
--
-- - REFER: How shifted special keys normally work:
--
--   - <Shift-Left>/<Shift-Right> moves [count] words backward/forward,
--     same as |b|/|w|. (See also nvim-lazyb <Ctrl-Left/Right>.)
--
--   - <Shift-Up>/<Shift-Down> scrolls the window [count] pages up/down,
--     same as <PageUp>/<PageDown> and <Ctrl-B>/<Ctrl-F>.
--     (See also <Ctrl-D>/<Ctrl-U>, which scroll half a screen.)
--
--   - <Home>/<End>/<PageUp>/<PageDown> do nothing different with <Shift>.
--
-- - Considering that, changing shifted special key behavior doesn't make
--   any functionality unavailable (e.g., you can use <PageUp> or <Ctrl-B>
--   instead of <Shift-Up>).
--
-- Also stop selection on non-shifted special key, akin to "stopsel".
--
-- "Special keys" are the cursor keys, <End>, <Home>, <PageDown>, and <PageUp>.

-- Wire the shifted special key maps.
-- - Note we (possibly unconventionally) set "exclusive" selection mode
--   to ensure that Shift-selecting behaves more "expectedly".
--   - Why? Otherwise you'll select one more than you prob. want.
--     - E.g., <Shift-Right> in Normal mode selects *two* characters,
--       and if you only want to select one character, you'll have to
--       <Shift-Right>, and then backup <Left> one.
--       - Or, if you <Shift-Down>, you'll select a line plus a char.
--         E.g., <Shift-Down> from the first column selects the
--         current line, and the first character from the next line.
--     - Note you'll notice a caret used in "exclusive" mode, and a
--       block cursor used in "inclusive" mode, so you'll at least
--       be able to visually discern which |selection| mode is active.

for _, key in ipairs({ "Left", "Right", "Down", "Up", "Home", "End", "PageDown", "PageUp" }) do
  map({ "n", "i" }, "<S-" .. key .. ">", function()
    -- vim.o.keymodel = "startsel"
    vim.o.selection = "exclusive"
    return "<S-" .. key .. ">"
  end, {
    expr = true,
    noremap = true,
    silent = true,
    desc = "Start Select mode " .. key,
  })
end

-- DUNNO: I tried a different approach in an attempt to support
-- `vim.o.keymodel = ""`, but I couldn't get it to work properly.
-- - E.g.:
--     map({ "i" }, "<S-Down>", function()
--       vim.o.keymodel = ""
--       vim.o.selection = "exclusive"
--       -- DUNNO: This remains in Insert mode, despite the <C-g>.
--       -- - And then after it runs, <Esc> goes to Select mode...
--       vim.cmd([[exec "normal! vj\<C-g>"]])
--       -- I also tried `expr = true` and these:
--       --   return "<S-Down>"
--       --   return "vj\\<C-g>"
--       -- Nor did this kludgy approach work:
--       --   vim.defer_fn(function()
--       --     vim.cmd([[exec "normal! \<C-g>"]])
--       --   end, 1000)
--       -- See also |gh|, which should start Select mode... but
--       -- maybe not from Normal mode? Not sure how it works.
--       --   vim.cmd([[exec "normal! gh\<S-Down>"]])
--     end, {
--       noremap = true,
--       -- I tried with and without `silent = true`, but neither
--       -- makes the <C-g> work (I've got a comment elsewhere
--       -- that warns that `silent = true` leaves Insert map
--       -- in Insert mode until user presses another key).
--       silent = true,
--       desc = "Start Select mode Selection & Down",
--     })

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

-- Ensure "exclusive" selection mode when making double-click selection.
-- - See util/mswin.lua for Insert mode 2-LeftMouse that similarly
--   sets "exclusive" mode, but also updates state for the
--   cut/copy/paste race condition kludges.
vim.keymap.set({ "n" }, "<2-LeftMouse>", function()
  -- vim.o.keymodel = "startsel"
  vim.o.selection = "exclusive"
  return "<2-LeftMouse>"
end, {
  expr = true,
  noremap = true,
  silent = true,
  desc = "Double-Click Selects Exclusive",
})

-- Ensure "exclusive" selection mode when making Visual selections.

vim.keymap.set({ "n" }, "v", function()
  vim.o.selection = "exclusive"
  return "v"
end, {
  expr = true,
  noremap = true,
  silent = true,
  desc = "Start Visual mode Charwise Exclusive",
})

vim.keymap.set({ "n" }, "V", function()
  vim.o.selection = "exclusive"
  return "V"
end, {
  expr = true,
  noremap = true,
  silent = true,
  desc = "Start Visual mode Linewise Exclusive",
})

-- REFER: See util/mswin.lua for similar <Ctrl-q>
-- map, "Start Visual mode Blockwise Exclusive".

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

-- ------------------------------------------------------------------
-- Wire Alt-Shift-Left/-Right to Selecting from Cursor to End of Line
-- ------------------------------------------------------------------
--
-- REFER: Built-in <Shift-Alt-Left|Right> jumps to start of prev|next
-- word, and in Insert mode stops Insert mode.

-- <Shift-Alt-Left> maps
-- ---------------------

-- Normal mode Alt-Shift-Left selects from cursor to start of line
-- (same as Shift-Home).
map({ "n" }, "<M-S-Left>", function()
  -- vim.o.keymodel = "startsel"
  vim.o.selection = "exclusive"
  return "v0<C-G>"
end, {
  expr = true,
  noremap = true,
  silent = true,
  desc = "Start Select mode to SOL",
})

-- Insert mode Alt-Shift-Left selects from cursor to start of line
-- (same as Shift-Home).
map({ "i" }, "<M-S-Left>", function()
  -- vim.o.keymodel = "startsel"
  vim.o.selection = "exclusive"
  return "<C-O>v0<C-G>"
end, {
  expr = true,
  noremap = true,
  silent = true,
  desc = "Start Select mode to SOL",
})

-- Visual mode Alt-Shift-Left selects from leftside of selection to
-- start of line (same as Shift-Home).
map({ "v" }, "<M-S-Left>", "0", {
  noremap = true,
  desc = "Extend Selection to SOL",
})

-- <Shift-Alt-Right> maps
-- ----------------------

-- Normal mode Alt-Shift-Right selects from cursor to end of line
-- (same as Shift-End).
map({ "n" }, "<M-S-Right>", function()
  -- vim.o.keymodel = "startsel"
  vim.o.selection = "exclusive"
  return "v$<C-G>"
end, {
  expr = true,
  noremap = true,
  silent = true,
  desc = "Start Select mode to EOL",
})

-- Insert mode Alt-Shift-Right selects from cursor to end of line
-- (same as Shift-End).
map({ "i" }, "<M-S-Right>", function()
  -- vim.o.keymodel = "startsel"
  vim.o.selection = "exclusive"
  return "<C-O>v$<C-G>"
end, {
  expr = true,
  noremap = true,
  silent = true,
  desc = "Start Select mode to EOL",
})

-- Visual mode Alt-Shift-Right selects from rightside of selection
-- to start of line (same as Shift-End).
map({ "v" }, "<M-S-Right>", "$", {
  noremap = true,
  desc = "Extend Selection to EOL",
})

-- ---------------------------------------------------------------------------
-- Wire Ctrl-Shift-PageUp/-PageDown to Selecting from Cursor to Edge of Window
-- ---------------------------------------------------------------------------

-- REFER:
-- - Built-in <Ctrl-PageUp|PageDown> does nothing in either mode.
-- - Built-in <Shift-Ctrl-PageUp|PageDown> does nothing in Insert mode,
--   but in Normal mode it starts Insert mode.
-- - Built-in <Shift-Alt-PageUp|PageDown is same as <Shift-PageUp|PageDown>
--   and selects text by the pageful.

-- Much like how Ctrl-PageUp and Ctrl-PageDown move the cursor to the top of
-- the window or to the bottom of the window, respectively, without changing
-- the view, Ctrl-Shift-PageUp and Ctrl-Shift-PageDown select text from the
-- cursor to the top or bottom of the window without shifting the view.
-- - When selecting from Insert mode, use <C-G> to change from Visual to Select
--   mode, so that if user uses arrow keys after, it stops the selection (though
--   if you start a visual mode selection and use <C-S-PageUp|PageDown>, it'll
--   stay in Visual mode, and then arrow keys will adjust the selection).

-- Ctrl-Shift-PageUp selects from cursor to first line of window.
map({ "n" }, "<C-S-PageUp>", function()
  -- vim.o.keymodel = "startsel"
  vim.o.selection = "exclusive"
  return "vH<C-G>"
end, {
  expr = true,
  noremap = true,
  silent = true,
  desc = "Start Select mode to PageUp",
})

map({ "i" }, "<C-S-PageUp>", function()
  -- vim.o.keymodel = "startsel"
  vim.o.selection = "exclusive"
  return "<C-O>vH<C-G>"
end, {
  expr = true,
  noremap = true,
  silent = true,
  desc = "Start Select mode to PageUp",
})

map({ "v" }, "<C-S-PageUp>", "H", {
  noremap = true,
  desc = "Extend Selection PageUp",
})

-- Ctrl-Shift-PageDown selects from cursor to last line of window.
map({ "n" }, "<C-S-PageDown>", function()
  -- vim.o.keymodel = "startsel"
  vim.o.selection = "exclusive"
  return "vL<C-G>"
end, {
  expr = true,
  noremap = true,
  silent = true,
  desc = "Start Select mode to PageDown",
})

map({ "i" }, "<C-S-PageDown>", function()
  -- vim.o.keymodel = "startsel"
  vim.o.selection = "exclusive"
  return "<C-O>vL<C-G>"
end, {
  expr = true,
  noremap = true,
  silent = true,
  desc = "Start Select mode to PageDown",
})

map({ "v" }, "<C-S-PageDown>", "L", {
  noremap = true,
  desc = "Extend Selection PageDown",
})

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

-- CXREF: See related <Ctrl-Shift-Left|Right> maps
-- (which also set selection=exclusive on demand):
-- ~/.kit/nvim/landonb/vim-select-mode-stopped-down/autoload/embrace/alt_select_motion.vim

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

-- Stop selection on non-shifted special keys.
--
-- This emulates |'keymodel'|'s "stopsel", except we don't use "stopsel"
-- because it breaks snippet mode.

map({ "s" }, "<Left>", "<Esc>h", { noremap = true, silent = true, desc = "Stop Selection & Left" })
map({ "s" }, "<Right>", "<Esc>l", { noremap = true, silent = true, desc = "Stop Selection & Right" })
map(
  { "s" },
  "<Down>",
  "&wrap == 1 ? '<C-O><Esc>gj' : '<C-O><Esc>j'",
  { desc = "Stop Selection & Down", expr = true, silent = true }
)
map(
  { "s" },
  "<Up>",
  "&wrap == 1 ? '<C-O><Esc>gk' : '<C-O><Esc>k'",
  { desc = "Stop Selection & Up", expr = true, silent = true }
)
map(
  { "s" },
  "<Home>",
  "&wrap == 1 ? '<C-O><Esc>g0' : '<C-O><Esc>0'",
  { desc = "Home", expr = true, silent = true }
)
map(
  { "s" },
  "<End>",
  "&wrap == 1 ? '<C-O><Esc>g$' : '<C-O><Esc>$'",
  { desc = "End", expr = true, silent = true }
)

map(
  { "s" },
  "<PageDown>",
  "<Esc><C-f>",
  { noremap = true, silent = true, desc = "Stop Selection & PageDown" }
)
-- SAVVY: <Shift-PageUp> does not work if already scrolled to the
-- top of the buffer (though <Shift-PageDown> works at the bottom).
-- - USAGE: Try <Shift-Ctrl-PageUp> or <Shift-Ctrl-Home> instead.
-- INERT: Try to fix this.
-- - E.g., if first line visible, select to buffer start.
map(
  { "s" },
  "<PageUp>",
  "<Esc><C-b>",
  { noremap = true, silent = true, desc = "Stop Selection & PageUp" }
)

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
