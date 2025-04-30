-- Keymaps are automatically loaded on the VeryLazy event
-- REFER: Default keymaps that are always set:
--   https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- CXREF:
-- ~/.local/share/nvim_lazyb/lazy/LazyVim/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

---@class lazyb.config.keymaps
local M = {}

local map = vim.keymap.set

local wk = require("which-key")

local alt_keys = require("util.alt2meta-keys")

local ctrl_keys = require("util.ctrl2pua-keys")

-- -----------------------------------------------------------------
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

-- BUGGN: Using any of the Unicode Private Use Area (PUA) characters for
--        the {lhs} causes an errant which-key entry for "î" (<Opt-i>i):
--          î →   +1 keymap
-- In this file, you'll find these 5 PUA characters that cause the problem:
--          (Used by Ctrl-; | Ctrl-' | <C-S-D> | <C-S-U> | <C-S-W> respectively)
-- - There's also the <C-S-D> char,  (ctrl_keys.lookup("D")), but it's
--   only mapped in Insert mode, so it doesn't cause the issue.
-- DUNNO: The best I can figure out so far is to at least title the item...
-- - FIXME/2025-03-03: Investigate which-key and figure out what's up...
-- <Opt-i>i → î
wk.add({ "î", group = "(Ignore me — See \\uE0xx chars.)" })

-- DUNNO: This is digraph a^ and not macOS <Option-a>... not sure what causes it.
-- - Says "+1 keymap".
wk.add({ "â", group = "(Ignore me — See \\uE0xx chars.)" })

-- -----------------------------------------------------------------
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

-- Reassign LazyVim bindings.

-- Resize window using <ctrl> arrow keys
-- - LazyVim uses <C-Up|Down|Left|Right>
map("n", "<D-Up>", "<cmd>resize +2<cr>", { desc = "Increase Window Height" })
map("n", "<D-Down>", "<cmd>resize -2<cr>", { desc = "Decrease Window Height" })
map("n", "<D-Left>", "<cmd>vertical resize -2<cr>", { desc = "Decrease Window Width" })
map("n", "<D-Right>", "<cmd>vertical resize +2<cr>", { desc = "Increase Window Width" })

-- -----------------------------------------------------------------
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

-- SAVVY: Command line `lua =expr` same as `lua print(vim.inspect(expr))` same as `=expr`.

-- REFER:
-- https://www.reddit.com/r/neovim/comments/yzfpx3/til_you_can_type_lua_code_instead_of_lua/

-- Another approach:
--   P = function(...)
--     local args = {}
--     for _, arg in ipairs({...}) do
--       table.insert(args, vim.inspect(arg))
--     end
--     print(unpack(args))
--     return ...
--   end
-- https://www.reddit.com/r/neovim/comments/uonvnc/better_global_p_function_to_print_lua_data/

vim.cmd([[:command! -nargs=1 I lua require("config.keymaps").inspectFn(<f-args>)]])
function M.inspectFn(obj)
  -- BWARE: If you use this implementation:
  --     print(vim.inspect(vim.fn.luaeval(obj)))
  -- Then you may see the error:
  --     E5100: Cannot convert given Lua table: table should
  --     contain either only integer keys or only string keys
  -- Which I've seen with this call:
  --      I Snacks.picker.get({ source = "explorer" })
  -- But sending a table works fine, e.g.,
  --      I {{ foo = "bar" }}
  -- ... so something else is going on.
  -- And for whatever reason, moving the inspect inside the eval
  -- works (to which I say, IDGI! which isn't that surprising,
  -- there's a lot of IDGI going on in nvim-lazyb! =):
  print(vim.fn.luaeval("vim.inspect(" .. obj .. ")"))
end

-- LATER: Find a different lhs (assumes I'll want <f9> for some IDE call; but until then...)
-- For just Lua:
--   map("n", "<F9>", "<cmd>luafile %<CR>", { desc = "Reload Luafile", noremap = true, silent = true })
-- A <cmd> one-liner doesn't work here (and the Lua function() end looks better):
--   [[<cmd>if expand("%:e") == "lua" | luafile % | else | exec "source " .. bufname("%") | endif<CR>]]
--
-- FEATR: Clear package.loaded[] cache.
-- - REFER: Here's a similar approach to what we've implemented below:
--   https://github.com/milisims/vimfiles/blob/94c723e11b526d83a5504198a79792d3a79f9344/lua/mia/source.lua
-- - Another approach:
--   https://joseustra.com/blog/reloading-neovim-config-with-telescope/
--
-- FTREQ: Use `au FileType` or similar mechanism and restrict to Vim and Lua files.
map({ "n", "i" }, "<F9>", function()
  local ext = vim.fn.expand("%:e")
  if ext == "lua" then
    vim.cmd([[luafile %]])
    M.clearRequirePackageCache()
  elseif ext == "vim" then
    vim.cmd([[exec "source " .. bufname("%")]])
    local bufname = vim.api.nvim_buf_get_name(0)
    print("Reloaded “" .. vim.fs.basename(bufname) .. "”")
  else
    print("Cannot reload unknown file type: " .. ext)
  end
end, { desc = "Reload Luafile/Vimscript", noremap = true, silent = true })

function M.clearRequirePackageCache()
  local repo_root = LazyVim.root()
  local norm_root = vim.fs.normalize(repo_root)

  local file_path = vim.fn.expand("%:p")
  -- Normalize path (expand ~ (no-op), resolve . and .. (no-op), convert \ → / (Windows))
  -- - ALTLY: vim.fs.abspath converts \ → /, too, and would resolve symlink paths.
  --   - SPIKE: What's the package.loaded key value for a symlink?
  --     - I'm gonna guess... the symlink path, and not the target.
  --       In which case using normalize() is correct.
  local norm_path = vim.fs.normalize(file_path)

  local alert_failed = function(fiver, norm_path, norm_root)
    print(
      fiver
        .. ": Cannot suss package.loaded[] key for file ("
        .. norm_path
        .. ") with root ("
        .. norm_root
        .. ")"
    )
  end

  if not vim.startswith(norm_path, norm_root) then
    alert_failed("ALERT", norm_path, norm_root)
  else
    local relative_path = vim.fn.substitute(norm_path, "^" .. norm_root, "", "")
    if relative_path == norm_path then
      alert_failed("GAFFE", norm_path, norm_root)
    else
      local reduced_path = relative_path
      -- MAYBE: Replace with Lua string.gsub usage.
      reduced_path = vim.fn.substitute(reduced_path, "^/lua/", "", "")
      reduced_path = vim.fn.substitute(reduced_path, "/init.lua$", "", "")
      reduced_path = vim.fn.substitute(reduced_path, ".lua$", "", "")
      local parts = vim.split(reduced_path, "/", { plain = true })
      -- Because table, not List, not this: vim.cmd.join(parts, ".")
      local module = require("plenary.functional").join(parts, ".")
      -- Note that `package.loaded[module]` remains nil until it's
      -- require()'d again.
      package.loaded[module] = nil
      print("Reloaded “" .. module .. "”")
    end
  end
end

-- -----------------------------------------------------------------
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

-- -------------------------------------------------------------------------
-- Fast save-and-exit for special apps (opt-in feature)
-- -------------------------------------------------------------------------

-- Ctrl-s to save and exit from any mode. For git-commit EDITOR, etc.

-- Commands can opt-in to these maps using special ENVIRON.
-- - Use case: `pass edit`, `dob edit`, `git commit`,
--   anywhere you want to make it easy to save and exit
--   (and where you can use readline <Up><Enter> to re-
--   run the command if you forgot special <C-s> exits
--   you).

-- Also tweak Insert mode <Ctrl-s> to stay in Insert mode.
--
-- - LazyVim uses <cmd>w<cr><esc> for every <Ctrl-s> map, so save
--   from Insert mode ends Insert mode.
--
-- DUNNO: I'm guessing this is how LazyVim prefers it, and isn't an oversight...
-- though couldn't hurt to ask, I suppose...

-- REFER: Neovim v0.11 wires Insert mode <Ctrl-S> to LSP Show Signature |i_CTRL-S|

-- CXREF: LazyVim's <C-S> map:
--   map({ "i", "x", "n", "s" }, "<C-s>", "<cmd>w<cr><esc>", { desc = "Save File" })
-- ~/.local/share/nvim_lazyb/lazy/LazyVim/lua/lazyvim/config/keymaps.lua @ 78

local mapCtrlSSave = function()
  if not vim.env.VIM_EDIT_JUICE_EXIT_ON_SAVE or vim.env.VIM_EDIT_JUICE_EXIT_ON_SAVE == "" then
    map({ "n", "v", "i" }, "<C-s>", "<cmd>update<CR>", {
      desc = "Save File",
      noremap = true,
      silent = true,
    })
  else
    map({ "n", "v", "i" }, "<C-s>", "<cmd>wq<CR>", {
      desc = "Save and Quit",
      noremap = true,
      silent = true,
    })
  end
end

mapCtrlSSave()

-- -----------------------------------------------------------------
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

map({ "i" }, "<C-t>", function()
  require("util.edit-juice.transpose").transpose_characters()
end, { desc = "Transpose Characters", noremap = true, silent = true })

-- For parity with DepoXy/dot-inputrc:
--   \et": transpose-chars
--   \eT": transpose-words
-- https://github.com/DepoXy/dot-inputrc#🎛️
-- - Though note we're not adding transpose-words.

map({ "i" }, alt_keys.lookup("t"), function()
  require("util.edit-juice.transpose").transpose_characters()
end, { desc = alt_keys.AltKeyDesc("Transpose Characters", "<M-t>"), noremap = true, silent = true })

-- BUGGN: which-keys shows as "Tt" (to see the popup, from
-- Insert mode, press <Ctrl-R>, then <BS>).
map({ "i" }, "<T-t>", function()
  require("util.edit-juice.transpose").transpose_characters()
end, { desc = "Transpose Characters", noremap = true, silent = true })

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

-- TRACK: Do we ever need { silent = true } considering Noice hides
-- a bunch of echo messages (or I think it does).
-- - SPIKE: TRYME: Disable Noice command line changes, and demo lazyb.

map({ "i" }, "<C-t>", function()
  require("util.edit-juice.transpose").transpose_characters()
end, { desc = "Transpose Characters", noremap = true, silent = true })

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

-- DROPD: dubs_edit_juice maps <Ctrl-Alt-Tab>/<Shift-Ctrl-Alt-Tab>
-- to a slighlty modified Next / Previous Buffer
-- - CXREF: s:BufNext_SkipSpecialBufs
--   ~/.kit/nvim/landonb/dubs_edit_juice/after/plugin/buffer-navigation.vim

-- SPIKE/2025-03-04: Decide if you need i or v modes, then cleanup.

-- HSTRY/2024-12-10: Let's try \dS for 'swap'.
--map({ "n", "i", "v" }, "<localleader>dS", function()
map({ "n" }, "<localleader>dS", function()
  require("util.edit-juice.paste-swap").clipboard_paste_rotate()
end, { desc = "Clipboard Paste Rotate", noremap = true, silent = true })

wk.add({ mode = "n", "<localleader>dS", icon = "" })

-- map({ "v" }, "<localleader>dS", function()
--   vim.cmd('"ax"+gP')
--   require("util.edit-juice.paste-swap").clipboard_paste_rotate()
-- end, { desc = "Clipboard Paste Rotate", noremap = true, silent = true })

-- vnoremap <LocalLeader>dS "ax"+gP:let @x=@+ \| let @+=@a \| let @a=@x \| let @"=@+ \| let @*=@+<CR>
-- nnoremap <LocalLeader>dS        :let @x=@+ \| let @+=@a \| let @a=@x \| let @"=@+ \| let @*=@+<CR>
-- inoremap <LocalLeader>dS   <C-O>:let @x=@+ \| let @+=@a \| let @a=@x \| let @"=@+ \| let @*=@+<CR>

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

-- INERT/2025-03-02 19: Should we nmap <BS>? Default <BS> same as |h|.
-- - Note that LazyVim assigns xmap <BS> to tree-sitter Decrement Selection.

vim.keymap.set({ "n" }, "<Del>", function()
  require("util.edit-juice.delete-backward").delete_char()
end, { desc = "Delete Character" })

-- Builtin n_CTRL-BS jumps backward to start of word (though I cannot
-- find its documentation...). Builtin i_CTRL-BS is simply <BS>.
-- HSTRY/2025-03-02:
vim.keymap.set({ "n", "i" }, "<C-BS>", function()
  require("util.edit-juice.delete-backward").delete_back_word()
end, { desc = "Delete Back Word" })
-- ALTLY:
--   vim.keymap.set({ "n" }, "<C-BS>", [[<Cmd>execute "normal i\<C-w>"<CR>]],
--     { desc = "Delete Back Word" })
--   vim.keymap.set({ "i" }, "<C-BS>", "<C-w>", { desc = "Delete Back Word" })

-- Map Alt-Backspace to same as Ctrl-Backspsace, if not just because Readline
-- (Bash prompt) maps Alt-Backspace to the same (similar) behavior.
-- - Builtin i_ALT-BS escapes to normal mode and moves cursor left.
-- - Builtin n_ALT-BS moves cursor left, like normal <BS>.
vim.keymap.set({ "n", "i" }, "<M-BS>", function()
  require("util.edit-juice.delete-backward").delete_back_word()
end, { desc = "Delete Back Word" })

vim.keymap.set({ "i" }, "<C-W>", function()
  require("util.edit-juice.delete-backward").delete_back_word()
end, { desc = "Delete Back Word" })

vim.keymap.set({ "s" }, "<C-W>", "<Delete>", { desc = "Delete Selected Text" })

-- BNDNG: <Shift-Ctrl-W> <C-S-W>
vim.keymap.set(
  { "n", "i" },
  ctrl_keys.lookup("W"),
  -- Basically "<cmd>normal! dB<CR>", except fixes cursor position.
  function()
    require("util.edit-juice.delete-backward").delete_back_WORD()
  end,
  { desc = "Delete Back WORD (M-S-W)", noremap = true, silent = true }
)

-- Ctrl-Shift-Backspace deletes to start of line. Aka *<C-S-Backspace>*
-- - Like `d<Home>` but way more complicated. As usual.
-- Builtins same as <C-BS>: Jumps backward to start of word in Normal
-- mode, or is simply <BS> in Insert mode.
vim.keymap.set({ "n", "i" }, "<C-S-BS>", function()
  -- MAYBE: Should this use built-in <C-U> instead?
  require("util.edit-juice.delete-backward").delete_back_line()
end, { desc = "Delete Back Line" })
-- Ctrl-Shift-W like Ctrl-Shift-BS (default <c-s-w> is same as <c-w>).
-- - SAVVY: Works in Debian Vim, but not MacVim (where Shift-Control
--   input maps to unshifted Control-only).
--   - See below for user character kludge using  (ctrl_keys.lookup("W")).
vim.keymap.set({ "n", "i" }, "<C-S-W>", function()
  -- MAYBE: Should this use built-in <C-U> instead?
  require("util.edit-juice.delete-backward").delete_back_line()
end, { desc = "Delete Back Line" })
-- -- OKILL: Also map to <Shift-Alt-W> (aka <M-S-W> <S-M-W> <Alt-Shift-W>)
-- -- - So now you have 3 options to delete_back_line: <C-S-BS>, <C-S-W>, <M-S-W>.
-- -- - SAVVY: <Shift-Alt-W> prints '×' by default if no mapping set (tho dunno why),
-- --   so this binding does not change anything important.
-- -- Builtins same as <W> and <S-W>: In Normal mode, jumps forward to start of
-- -- next word; in Insert mode, escapes first, then jumps forward to next word.
-- -- mode, or is simply <BS> in Insert mode.
-- vim.keymap.set({ "i" }, alt_keys.lookup("W"), function()
--   require("util.edit-juice.delete-backward").delete_back_line()
-- end, { desc = alt_keys.AltKeyDesc("Delete Back Line", "<M-S-W>") })

-- CXREF: ~/.kit/nvim/landonb/dubs_edit_juice/plugin/ctrl-backspace.vim
--   inoremap <c-s-w> <C-O>:<C-U>call <SID>delete_back_line()<CR>
--   if has('macunix')
--     inoremap „ <C-O>:<C-U>call <SID>delete_back_line()<CR>
--   else
--     inoremap <m-s-w> <C-O>:<C-U>call <SID>delete_back_line()<CR>
--   endif
-- CXREF: ~/.depoxy/ambers/home/.config/alacritty/alacritty.toml
--   { key = "W", mods = "Control|Shift", chars = "\uE016" },
-- BUGGN: Causes errant "î" which-key entry (see notes above).
-- BNDNG: <Shift-Alt-W> <M-S-W> <S-M-W>
vim.keymap.set({ "n", "i" }, alt_keys.lookup("W"), function()
  require("util.edit-juice.delete-backward").delete_back_line()
end, { desc = alt_keys.AltKeyDesc("Delete Back Line", "<M-W>"), noremap = true, silent = true })

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

-- Builtin n_CTRL-DELETE and i_CTRL-DELETE simply <Del> a single character.
-- n_SHIFT-CTRL-DELETE does nothing.
-- i_SHIFT-CTRL-DELETE inserts literal string, "<C-S-Del>".
-- n_META-DELETE is same as <Del>, deletes character under cursor.
-- i_META-DELETE deletes character in front of cursor, then leaves Insert mode.
-- n_SHIFT-META-DELETE does nothing.
-- i_SHIFT-META-DELETE escapes Insert mode.

-- Ctrl-Delete deletes to start of word...
-- - Use <silent> — You'll still see a search pattern echoed in the
--   command line, but Neovide won't animate the cursor jumping to
--   the command line and back to the buffer. [2025-01-25: I'm new
--   to Neovide, and I should probably disable cursor animation, but
--   it's an interesting feature, and it supplants blinky-search
--   functionality à la Damian Conway's die_blinkënmatchen.vim]
--  nnoremap <silent> <C-Del> :call <SID>Del2EndOfWsAz09OrPunct('n', 0)<CR>
-- HSTRY/2020-05-15: I switched from using <Esc> to <C-O>,
-- to break out of insert mode. My rationale was:
--   - If we <C-O> and the cursor is on either the last
--     column or the second-to-last-column, the cursor
--     is moved to the last column.
--   - If we <Esc> and the cursor is on either the first
--     column or the second column, the cursor is moved
--     to the first column.
--   - At the time I chose <Esc> (5-10 years ago), I did not solve the
--     problem, but I figured I had to live with one of two scenarios:
--     - With <C-O>, if the cursor is at the second-to-last column,
--       a join happens, but the last character remains.
--     - With <Esc>, if you <Ctrl-Del> from the second column, both the
--       first and second columns are deleted.
--     - And I chose <Esc>'s behavior, because, I noted:
--       I <Ctrl-Del> from the end of a line much more often than from
--       the second column of a line.
-- - But now it's 2020 and I seem to have been able to handle both
--   those issues, and I prefer <C-O>, so that I can run a one-off
--   command and not have to worry about 'i' later, or explicitly
--   re-entering insert mode.
--  inoremap <silent> <C-Del> <C-O>:call <SID>Del2EndOfWsAz09OrPunct('i', 0)<CR>
vim.keymap.set({ "n", "i" }, "<C-Del>", function()
  require("util.edit-juice.delete-forward").Del2EndOfWsAz09OrPunct(0)
end, { desc = "Delete Forward Word" })

-- Ctrl-Shift-Delete deletes to end of line.
-- - Sorta like
--       nnoremap <C-S-Del> d$
--       inoremap <C-S-Del> <C-O>d$
--   but more robuster.
vim.keymap.set({ "n", "i" }, "<C-S-Del>", function()
  require("util.edit-juice.delete-forward").Del2EndOfWsAz09OrPunct(1)
end, { desc = "Delete Forward Line" })

-- HSTRY/2011-02-01: Doing same [as Ctrl-Shift-Delete] for Alt-Delete.
vim.keymap.set({ "n", "i" }, "<M-Del>", function()
  require("util.edit-juice.delete-forward").Del2EndOfWsAz09OrPunct(1)
end, { desc = "Delete Forward Line" })

-- Alt-Shift-Delete deletes the entire line. Which `dd` does perfectly.
-- - Note using wk.add, not vim.keymap.set, for the "icon".
-- CALSO: Delete current line: <M-S-Del> or <LocalLeader>dd
wk.add({
  mode = { "n", "i" },
  "<M-S-Del>",
  "<Cmd>normal! dd<CR>",
  desc = "Delete Line",
  icon = "󰛲",
})

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

-- CXREF: ~/.kit/nvim/landonb/dubs_edit_juice/plugin/dubs_edit_juice.vim
--   inoremap <S-C-D> <C-O>:call CursorFriendlyIndent(1)<CR>
--   inoremap <S-M-D> <C-O>:call CursorFriendlyIndent(1)<CR>
-- CXREF: ~/.depoxy/ambers/home/.config/alacritty/alacritty.toml
--   { key = "D", mods = "Control|Shift", chars = "\uE003" },
-- - I.e., not this:
--   vim.keymap.set({ "i", "v" }, ctrl_keys.lookup("D"), function()
-- - From Select mode, use <Tab>/<Shift-Tab> to indent/dedent.
-- BUGGN: This one *does not* cause "î" which-key entry (unlike similar
-- user space characters that do), though probably because Insert mode only.
-- BNDNG: <Shift-Ctrl-D> aka <>
vim.keymap.set({ "i" }, ctrl_keys.lookup("D"), function()
  require("util.edit-juice.indent").cursor_friendly_indent(1)
end, { desc = "Indent (C-S-D)" })

-- <S-C-D>: Add Normal mode <C-D> complement at <S-C-D> (does the opposite — Scrolls up).
-- BUGGN: Causes "î" which-key entry (see notes above).
-- BNDNG: <Shift-Ctrl-D>
vim.keymap.set(
  { "n", "v" },
  ctrl_keys.lookup("D"),
  "<C-U>",
  { desc = "Scroll Window Upwards (like C-U) (C-S-D)" }
)

-- <C-S-U>: Add Normal mode <C-U> complement at <C-S-U> (does the opposite — Scrolls down).
-- - ISOFF/2025-03-03: See comment above: Leave vmap <C-D>/<C-S-D> for which-key.
--   vim.keymap.set({ "n", "v" }, ctrl_keys.lookup("U"), "<C-D>",
--     { desc = "Scroll Window Downwards (like C-D) (C-S-U)" })
-- BUGGN: Causes errant "î" which-key entry (see notes above).
-- BNDNG: <Shift-Ctrl-U> <C-S-U> <>
vim.keymap.set(
  { "n", "v" },
  ctrl_keys.lookup("U"),
  "<C-D>",
  { desc = "Scroll Window Downwards (like C-D) (C-S-U)" }
)

-- As defined by dubs_edit_juice.vim (see big wk.add() section below).
wk.add({
  {
    mode = { "n" },
    -- BNDNG: <Shift-Ctrl-D> <C-S-D> <S-C-D>
    { "<C-S-D>", desc = "Scroll Window Upwards (like <C-U>)" },
    -- BNDNG: <Shift-Ctrl-U> <C-S-U> <S-C-U>
    { "<C-S-U>", desc = "Scroll Window Downwards (like <C-D>)" },
  },
})

-- -----------------------------------------------------------------
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

-- COPYD: And added 'desc', from:
-- https://github.com/ecosse3/nvim/blob/master/lua/config/keymappings.lua

-- Don't yank on delete char
map({ "n", "x" }, "x", '"_x', { silent = true, desc = "Delete characters" })
map({ "n", "x" }, "X", '"_X', { silent = true, desc = "Delete characters" })

-- Don't yank on visual paste
--  map("x", "p", '"_dP', { silent = true, desc = "Put from register" })

-- -----------------------------------------------------------------
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

-- CXREF:
-- ~/.config/nvim_lazyb/lua/config/keymaps/date-and-time.lua
require("config.keymaps.date-and-time")

-- CXREF:
-- ~/.config/nvim_lazyb/lua/config/keymaps/alt-menu.lua
require("config.keymaps.alt-menu")

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

-- CXREF:
-- ~/.kit/nvim/landonb/dubs_edit_juice/plugin/dubs_edit_juice.vim
-- FIXME: Localize these files.
pcall(function()
  vim.g.dubs_edit_juice_everything = false
  vim.cmd(
    "source " .. vim.env.HOME .. "/.kit/nvim/landonb/dubs_edit_juice/plugin/dubs_edit_juice.vim"
  )
end)

-- CXREF:
-- ~/.kit/nvim/landonb/dubs_edit_juice/plugin/chartab.vim
pcall(function()
  vim.cmd("source " .. vim.env.HOME .. "/.kit/nvim/landonb/dubs_edit_juice/plugin/chartab.vim")
end)

wk.add({
  -- Keybindings from dubs_edit_juice, in file order:
  --   ~/.kit/nvim/landonb/dubs_edit_juice/plugin/dubs_edit_juice.vim
  {
    mode = { "n", "i" },
    { "<C-Left>", desc = "Move Cursor Back Word |b|", mode = { "n", "i", "v" } },
    { "<C-Right>", desc = "Move Cursor Next Word |el|", mode = { "n", "i", "v" } },
    { "<C-M-Left>", desc = "Move Cursor Back Word |B|" },
    { "<C-M-Right>", desc = "Move Cursor Next WORD |El|" },
    { "<M-S-Left>", desc = "Select to Start of Line", mode = { "n", "i", "v" } },
    { "<M-S-Right>", desc = "Select to End of Line", mode = { "n", "i", "v" } },
    { "<C-S-PageUp>", desc = "Select to Start of Window", mode = { "n", "i", "v" } },
    { "<C-S-PageDown>", desc = "Select to End of Window", mode = { "n", "i", "v" } },
    { "<C-Up>", desc = "Sticky Cursor Scroll Window Up" },
    { "<C-Down>", desc = "Sticky Cursor Scroll Window Down" },
    { "<C-PageUp>", desc = "Move Cursor to Start of Window" },
    { "<C-PageDown>", desc = "Move Cursor to End of Window" },
    { "<M-Left>", desc = "Move Cursor to Start of Line", mode = { "n", "i", "v" } },
    { "<M-Right>", desc = "Move Cursor to End of Line", mode = { "n", "i", "v" } },
    { "<M-F12>", desc = "Move to Middle Line & Start Insert", mode = { "n", "i", "v" } },
    { "<localleader>dt", desc = "Toggle Tab Highlighting" },
    { "<localleader>d<", desc = "Left Justify Line", icon = "󰞓" },
  },
  {
    { mode = "n", "<Tab>", desc = "Indent Line" },
    { mode = "n", "<S-Tab>", desc = "Dedent Line" },
    { mode = "v", "<Tab>", desc = "Indent Selected" },
    { mode = "v", "<S-Tab>", desc = "Dedent Selected" },
    -- BUGGN: Pressing "<" from which-key popup shows subset of non-<LocalLeader> maps.
    -- - But the ">" which-key popup works, and just shows the one ">>" map.
    { mode = "n", ">", desc = "Cursor-Friendly Indent" },
    { mode = "n", ">>", desc = "Cursor-Friendly Indent" },
    { mode = "n", "<", desc = "Cursor-Friendly Dedent" },
    { mode = "n", "<<", desc = "Cursor-Friendly Dedent" },
    -- ISOFF/2025-03-04: See notes above re: which-key conflicts.
    --  { mode = "v", "<S-C-D>", desc = "Indent Selection" },
    --  { mode = "v", "<C-D>", desc = "Dedent Selection" },
  },
  {
    mode = { "n", "i" },
    { "<localleader>dK", desc = "Move Paragraph Up", icon = "" },
    { "<localleader>dJ", desc = "Move Paragraph Down", icon = "" },
  },
  {
    icon = "", -- ¶ 󰉽
    mode = { "v" },
    { "<F2>", desc = "Reformat Paragraph (79)" },
    { "<S-F2>", desc = "Reformat Paragraph (67)" },
    { "<C-S-F2>", desc = "Reformat Paragraph (89)" },
    { "<C-S-F3>", desc = "Reformat Paragraph (55)" },
    { "<C-S-F4>", desc = "Reformat Paragraph (44)" },
    { "<M-S-F2>", desc = "Reformat ¶ (len. of first line)" },
  },
  {
    --    󰨎  
    { mode = "n", "<LocalLeader>d/", desc = "Convert \\ → /", icon = "" },
    { mode = "n", "<LocalLeader>d<Bslash>", desc = "Convert / → \\", icon = "󰨎" },
  },
  {
    mode = { "n", "i" },
    { "<C-CR>", desc = "Newline without Comment Leader" },
  },
  {
    icon = "󰛔",
    { mode = "n", "<localleader>s", desc = "Substitute Word Under Cursor" },
    { mode = "v", "<localleader>s", desc = "Substitute Selected Word" },
    { mode = { "n", "i", "v" }, "<localleader>S", group = "Substitute Commands" },
    { mode = { "n", "i" }, "<localleader>SS", desc = "Sub. Word Under Cursor (#-delims)" },
    { mode = "v", "<localleader>SS", desc = "Substitute Selected Word (#-delims)" },
    -- ISOFF/2025-03-04: The inccommand-enabled s/ub/stitute/ maps don't play well.
    --  { mode = { "n", "v" }, "<localleader>Ss", desc = "Sub. Word (live inccommand)" },
    --  { mode = { "n", "i", "v" }, "<localleader>S#", desc = "Sub. Word (#-delims, live inccommand)" },
  },
  {
    icon = "󰉠",
    { mode = { "n", "i" }, "<localleader>dz", desc = "Redraw Line at Window Center" },
    { mode = { "n", "i" }, "<localleader>dZ", desc = "Redraw Line 5 from the Top" },
    -- HSTRY/2025-03-03: Why not make a few more window commands available from Insert mode...
    { mode = { "n", "i" }, "<localleader>z", group = "Fold and Scroll Commands" },
    { mode = { "n", "i" }, "<localleader>zz", desc = "Redraw Line at Window Center" },
    { mode = { "n", "i" }, "<localleader>zb", desc = "Redraw Line &scrolloff from Bottom" },
    { mode = { "n", "i" }, "<localleader>zt", desc = "Redraw Line &scrolloff from Top" },
    { mode = { "n", "i" }, "<localleader>za", desc = "Toggle the Fold Under the Cursor" },
  },
  {
    { mode = { "n", "i" }, "<localleader>dA", desc = "Show ASCII Character Table" },
    -- Built-in Normal and Visual mode CTRL-] and v_CTRL-]
    -- - CXREF: See broken-ish Insert mode <Ctrl-]>:
    --   ~/.kit/nvim/landonb/nvim-lazyb/lua/util/edit-juice/init.lua
    { mode = { "n", "v" }, "<C-]>", desc = "Jump to tag def'n" },
    -- <M-]> calls <C-T>. See also :pop (and the reverse, :tag to newer tag).
    -- - The cursor position jumpers, <Ctrl-O> and <Ctrl-I> kinda work similarly.
    {
      mode = { "n", "i", "v" },
      alt_keys.lookup("]"),
      desc = alt_keys.AltKeyDesc("Jump backward in tag stack", "<M-]>"),
    },
    -- CALSO: <M-f>o — <O>pen buffer in new tabpage — (same feature)
    {
      mode = { "n", "i" },
      "<localleader>dT",
      -- HSTRY: Previously opened via path, but doesn't work w/ scratch buffers.
      --   "<cmd>exec 'tabedit ' .. expand('%')<CR>",
      function()
        -- REFER: Call vim.api.nvim_get_current_buf() instead of vim.fn.bufnr().
        -- - Unless you need to pass arg: vim.fn.bufnr(bufnr) (AFAIK).
        local bufnr = vim.api.nvim_get_current_buf()
        vim.cmd("tabnew")
        -- ALTLY: We can use vim.cmd() or vim.cmd.buffer().
        -- - DUNNO: What's the better style?
        --   (I sorta like vim.cmd() because less verbose.)
        -- vim.cmd("buffer " .. bufnr)
        vim.cmd.buffer({ args = { bufnr } })
      end,
      desc = "Open buffer in new tab page",
      noremap = true,
      silent = true,
    },
  },
  {
    { mode = "v", ":", group = "Cmdline Tools" },
    -- SAVVY: If you want to start a substitute with selected text,
    -- then `<C-o>:` is not enough, it just opens which-key window;
    -- you need to press another character now, e.g., `<C-o>:<Space>`.
    mode = { "n", "i" },
    { mode = "v", "::", desc = "Start :cmdline with Selection" },
    -- These three bindings are FileType-specific.
    -- - Note the double-colon; if only one, doesn't print.
    -- - CXREF:
    --   ~/.kit/nvim/landonb/dubs_edit_juice/plugin/dubs_edit_juice.vim @ 1723
    { mode = "v", ":?", desc = "::help Selection (vim,lua,rst,md,txt)" },
    { mode = "v", ':"', desc = "::echom Selection (vim,lua,rst,md,txt)" },
    { mode = "v", ":>", desc = "::call Selection (vim,lua,rst,md,txt)" },
    { mode = "v", ":L", desc = "Start :lua command with Selection" },
  },
  {
    mode = { "n", "i" },
    { mode = { "n" }, "<LocalLeader>dD", group = "DiffTogglers" },
    { mode = { "n" }, "<LocalLeader>dDl", desc = "DiffToggle Left" },
    { mode = { "n" }, "<LocalLeader>dDc", desc = "DiffToggle Center" },
    { mode = { "n" }, "<LocalLeader>dDr", desc = "DiffToggle Right" },
  },
  {
    mode = { "n", "i" },
    -- FIXME:/2025-03-03: Revive this feature so it works with Tree-sitter...
    --   (and find a different key sequence so <F10> can be used for IDE controls).
    --
    --  { mode = { "n" }, "<F10>", desc = "Show :highlight of word under cursor" },
    {
      mode = { "i" },
      alt_keys.lookup("B"),
      desc = alt_keys.AltKeyDesc("Highlight word under cursor (sticky)", "<M-S-B>"),
    },
  },
})

-- TRYNG/2025-03-09: Replace LazyVim indent/dedent vmap with only the xmap.
-- - REFER:
--    -- better indenting
--    map("v", "<", "<gv")
--    map("v", ">", ">gv")
-- - CXREF:
--    ~/.local/share/nvim_lazyb/lazy/LazyVim/lua/lazyvim/config/keymaps.lua
-- - BECUZ: In Select mode, rather than replacing selected text,
--   ">" and "<" indent/dedent instead.
--   - The xmap behavior is more respectful of how Select mode should behave
--     (which is that non-special keys are inserted literally).
vim.keymap.del("v", "<")
vim.keymap.del("v", ">")
-- Without the desc's, which-keys shows: "Indent left", "Indent right".
map("x", "<", "<gv", { desc = "Indent Selection" })
map("x", ">", ">gv", { desc = "Dedent Selection" })

-- Remove word under cursor is at <Alt-d> but I don't use much/ever,
-- and I would perhaps prefer <Alt-w> (mnemonic: word) but <M-w> is
-- top-level Insert mode maps for Normal mode <C-w> commands.
-- - SAVVY: Note that <cmd> causes cursor to shift leftward one:
--     map({ "n", "i" }, alt_keys.lookup("d"), "<cmd>normal diwi<CR>", {
--       desc = alt_keys.AltKeyDesc("Remove word under cursor", "<M-d>"),
--     })
--   Even if you do "<cmd>normal diwil<CR>" the cursor is one column
--   left of where you'd expect it — it's left of the start of the
--   word that was deleted.
--   - Fortunately rhs Lua function works perfectly.
map({ "n", "i" }, alt_keys.lookup("d"), function()
  vim.cmd.normal([[diw]])
  vim.cmd([[startinsert]])
end, { desc = alt_keys.AltKeyDesc("Remove word under cursor", "<M-d>") })

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

-- FIXME: Use snippets instead.
-- - SAVVY: Completion borks these iabbrev's.
--   - ,u doesn't work at all.
--   - 3t only works if followed by <space> (or <C-o>),
--     but 3t doesn't work if followed by <CR>.
--
-- USYNC: See also the vim-async-map approach (which times-out
-- between keypresses, if user is typing slowing, unlike iabbrev).
--
-- if not lazy_profile["vim-async-map"] then
vim.cmd(
  "iabbrev <expr> 3t '################<C-CR>' . strftime('%Y-%m-%d %H:%M') . '<C-CR>################<C-CR>'"
)
-- end

vim.cmd(
  "iabbrev <expr> 3t<CR> '################<CR>' . strftime('%Y-%m-%d %H:%M') . '<CR>################<CR>'"
)

-- REFER/2025-02-07: Some nifty abbreviation ideas:
-- https://www.reddit.com/r/neovim/comments/16mijcz/anyone_here_use_iabbrev/
-- - One user uses comma leader beause "I will never type comma
--   without space in normal text or code."
-- DUNNO/2025-03-03: Like `,t` abbrev, doesn't work in nvim-lazyb (LavyVim)...??
vim.cmd("inoreabbrev <expr> ,u system('uuidgen')->trim()->tolower()")

-- HSTRY/2025-02-10: Not sure why I haven't abbrev'd this 'til now.
vim.cmd("cnoreabbrev TM TabMessage")

wk.add({
  mode = { "n", "i" },
  "<LocalLeader>dM",
  "<cmd>TabMessage messages<CR>",
  desc = ":TabMessage messages",
})

-- -----------------------------------------------------------------
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

wk.add({
  mode = { "n", "i" },
  "<F2>",
  function()
    require("util.buffer-delights.mru-buffer").Switch_MRU_Safe()
  end,
  desc = "Open MRU (Alternative) Buffer",
})

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

-- Vertical-split shortcut
-- - An oldie from vim-buffer-delights that I never used/forgot about.
-- - vv to generate new vertical split
--   https://www.bugsnag.com/blog/tmux-and-vim
-- - Default `vv` enters Visual mode, then goes back to Normal mode.
--
--  wk.add({ mode = { "n" }, "vv", "<cmd>wincmd v<CR>", desc = "Open MRU (Alternative) Buffer" })

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

wk.add({
  mode = { "n", "i" },
  { "<LocalLeader>d1", "<cmd>1wincmd w<CR>", desc = "Window #1 jumper" },
  { "<LocalLeader>d2", "<cmd>2wincmd w<CR>", desc = "Window #2 jumper" },
  { "<LocalLeader>d3", "<cmd>3wincmd w<CR>", desc = "Window #3 jumper" },
  { "<LocalLeader>d4", "<cmd>4wincmd w<CR>", desc = "Window #4 jumper" },
  { "<LocalLeader>d5", "<cmd>5wincmd w<CR>", desc = "Window #5 jumper" },
  { "<LocalLeader>d6", "<cmd>6wincmd w<CR>", desc = "Window #6 jumper" },
  { "<LocalLeader>d7", "<cmd>7wincmd w<CR>", desc = "Window #7 jumper" },
  { "<LocalLeader>d8", "<cmd>8wincmd w<CR>", desc = "Window #8 jumper" },
  { "<LocalLeader>d9", "<cmd>9wincmd w<CR>", desc = "Window #9 jumper" },
})

-- -----------------------------------------------------------------
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

-- CXREF: LazyVim configures j/k/<Up>/<Down> to be visual-line friendly,
--   e.g., <Up> or `k` when wrap enabled moves cursor up a visual line
--   (and it doesn't skip visual lines to go to previous logical line).
--     ~/.local/share/nvim_lazyb/lazy/LazyVim/lua/lazyvim/config/keymaps.lua
-- CXREF: The dubs_toggle_textwrap plugin maps those 4 as well as <Home>/<End>.
--     ~/.kit/nvim/landonb/dubs_toggle_textwrap/autoload/toggle_textwrap/wrapnav.vim
-- SAVVY: LazyVim maps Normal and Visual modes, but not Insert or Select.
-- - BWARE: This means that Normal mode <Up>/<Down> moves by the visual line,
--   but Insert mode <Up>/<Down> moves by the logical line... which is either
--   an oversight, though probably not, seems like maybe some people like the
--   disparate behaviors?

-- MAYBE: Try <cmd> so cursor doesn't turn into block cursor momentarily.

-- stylua: ignore
map(
  { "n", "x" },
  "<Home>",
  "&wrap == 1 ? 'g0' : '0'",
  { desc = "Home", expr = true, silent = true }
)
map(
  { "i" },
  "<Home>",
  "&wrap == 1 ? '<C-O>g0' : '<C-O>0'",
  { desc = "Home", expr = true, silent = true }
)
-- CXREF: See mswin.lua for smap <Home>:
-- ~/.kit/nvim/landonb/nvim-lazyb/lua/util/mswin.lua

-- stylua: ignore
map(
  { "n", "x" },
  "<End>",
  "&wrap == 1 ? 'g$' : '$'",
  { desc = "End", expr = true, silent = true }
)
-- BWARE: When wrap enabled, g$ used, which does not set curswant very large.
-- - If you want <Up>/<Down> to always go to line's end, and wrap is enabled,
--   you can <C-o>$ manually and then <Up>/<Down> (or you can disable &wrap).
map(
  { "i" },
  "<End>",
  "&wrap == 1 ? '<C-O>g$' : '<C-O>$'",
  { desc = "End", expr = true, silent = true }
)
-- CXREF: See mswin.lua for smap <End>:
-- ~/.kit/nvim/landonb/nvim-lazyb/lua/util/mswin.lua

-- -----------------------------------------------------------------
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

-- AVOID: (It's only slightly annoying): You can (barely) see the cursor change
-- to the Normal mode block cursor and back to the caret when you use <Down> and
-- <Up> in Insert mode defined by these 2 maps:
--   map({ "i" }, "<Down>", "&wrap == 1 ? '<C-O>gj' : '<C-O>j'",
--     { desc = "Down", expr = true, silent = true })
--   map( { "i" }, "<Up>", "&wrap == 1 ? '<C-O>gk' : '<C-O>k'",
--     { desc = "Up", expr = true, silent = true })
-- - Though note that |gj| and |j| behave similarly from Insert mode; they only differ
--   when you use a count (e.g., `5gj` moves 5 visual lines, and `5j` moves 5 logical).
--   - But you cannot specify a count from Insert mode (or can you?), e.g., using a map
--     like the LazyVim maps, "v:count == 0 ? '<C-O>gj' : '<C-O>j'", would always just
--     run the |gj| command
-- Given that, we could use <cmd> (or an inline Lua function()) to avoid changing to
-- Normal mode.
-- - And note we don't run `normal!` — `normal j` runs the LazyVim
--   `j` imap, which calls `gj`, and moves a single logical line.

-- BWARE: If you use <cmd>, the cursor ends up in penultimate position
-- when the column you're moving from is greater than the line width
-- you're moving to.
-- - E.g., consider the two lines with the cursor marked by "|":
--     foo bar baz|
--     foo bar
-- - If you press <Down> and map rhs is "<Cmd>normal j<CR>",
--   then cursor ends up in wrong position:
--     foo bar baz
--     foo ba|r
-- - WRONG: So not this (add adding 'l' doesn't help; you'd need to
--   stopinsert() and then vim.schedule() startinsert! instead):
--     map({ "i" }, "<Down>", "<cmd>normal j<CR>", { desc = "Down", silent = true })
--     map({ "i" }, "<Up>", "<cmd>normal k<CR>", { desc = "Up", silent = true })

-- FEATR: Use <cmd> or function() to avoid cursor mode change "blip".
-- - Note we need to know the column of the starting line, and not the one
--   we're moving from. E.g., consider these lines:
--     foo bar baz|
--     foo
--     foo bar
--   If you press <Down> twice, the cursor should end up at the end of line 3:
--     foo bar baz
--     foo
--     foo bar|
--   Vim implements this using curswant from getcurpos().
-- BECUZ: Note that this simple implementation works, but it "blips":
--   map({ "i" }, "<Down>", "&wrap == 1 ? '<C-O>gj' : '<C-O>j'",
--     { desc = "Down", expr = true, silent = true })
--   map( { "i" }, "<Up>", "&wrap == 1 ? '<C-O>gk' : '<C-O>k'",
--     { desc = "Up", expr = true, silent = true })
-- - That is, you'll see a cursor artifact:
--   - You can see the cursor quickly change from a caret
--     to a block and back to a caret as you <Up> and <Down>...
-- - So we'll bake our own, much more complicated solution, just so
--   we can avoid the (annoying to me) visual artifact.
--   - Though the visual artifact still happens when curswant is
--     greater than the line length, but that's because we need a
--     startinsert! kludge to fix the cursor position *after* nvim
--     changes back to Insert mode... (what a messy situation, ha!).
-- INERT: This almost works! But if lines wrap, curswant increases
-- when you |j| between two visible lines for the same logical line.
-- - And then if you |j| to another logical line, you might move
--   cursor to the end of the line because curswant was increased.
-- - But this doesn't happen with the basic maps (but then you see
--   the cursor icon artifacts...).
-- - E.g., consider the logical line split across two visible lines:
--     foo bar
--     baz bat
--   If cursor is after "foo":
--     foo| bar
--     baz bat
--   Then getcurpos() reports [0, 1, 4, 0, 4].
--   If you move cursor down one visible line
--     foo bar
--     baz| bat
--   Then getcurpos() reports [0, 1, 12, 0, 15].
--   - And if you move cursor down again, you'll see
--     curswant revert: [0, 2, 1, 0, 4]
--   So it seems like (Neo)vim is tracking at least *two* curswant values,
--   the sticky one, and then one for the current visible line... which
--   means our apprach here doesn't work well with wrapped lines.
--   - C'est dommage! (I should've given up on this fcn. a while ago,
--     but I kept getting closer; and I falsely believed I'd have it
--     figured out soon enough... alas, no!)
--
-- INERT: This *almost* works, but has issues with wrapped lines
-- because curswant varies for different visual lines for the same
-- logical line. And I don't see an obvious solution other than tracking
-- curswant across callbacks (and, what, resetting curswant on <Left>,
-- <Right>, |h|, |l|, |$|, etc.?).
--
--   function M.move_cursor(dir)
--     local curpos = vim.fn.getcurpos()
--     local curswant = curpos[5]
--     if vim.o.wrap then
--       vim.cmd("normal! g" .. dir)
--     else
--       vim.cmd("normal! " .. dir)
--     end
--     local final_pos = vim.fn.getpos(".")
--     -- fixme: Only do this if only last visible line of logical line.
--     -- - I think you could getpos(), then |j| and compare getpos()
--     --   to see if the line number is different or not.
--     --   - Then only startinsert! if line below is a different line.
--     vim.cmd("normal! gj")
--     local after_pos = vim.fn.getpos(".")
--     -- print("final: " .. vim.inspect(final_pos) .. " / after: " .. vim.inspect(after_pos))
--     if final_pos[2] ~= after_pos[2] or final_pos[3] ~= after_pos[3] then
--       vim.cmd("normal! gk")
--       -- print("k: " .. vim.inspect(vim.fn.getpos(".")) .. " / curswant: " .. curswant)
--       if final_pos[2] ~= after_pos[2] and vim.fn.col("$") <= curswant then
--         vim.cmd.stopinsert()
--         vim.schedule(function()
--           vim.cmd("startinsert!")
--           -- REFER: Use cursor() or winrestview() to restore curswant (and not setpos()).
--           -- - DUNNO: If we set { curswant = curswant } it increases by 1.
--           -- print("curswant: " .. vim.inspect(curswant))
--           vim.fn.winrestview({ curswant = curswant - 1 })
--         end)
--       end
--     end
--   end
--   -- stylua: ignore
--   map({ "i" }, "<Down>", function() M.move_cursor("j") end, { desc = "Down", silent = true })
--   -- stylua: ignore
--   map({ "i" }, "<Up>", function() M.move_cursor("k") end, { desc = "Up", silent = true })

-- CXREF: See LazyVim <Down>/<Up> maps:
--   map({ "n", "x" }, "j", "v:count == 0 ? 'gj' : 'j'",
--     { desc = "Down", expr = true, silent = true })
--   map({ "n", "x" }, "<Down>", "v:count == 0 ? 'gj' : 'j'",
--     { desc = "Down", expr = true, silent = true })
--   map({ "n", "x" }, "k", "v:count == 0 ? 'gk' : 'k'",
--     { desc = "Up", expr = true, silent = true })
--   map({ "n", "x" }, "<Up>", "v:count == 0 ? 'gk' : 'k'",
--     { desc = "Up", expr = true, silent = true })
-- ~/.local/share/nvim_lazyb/lazy/LazyVim/lua/lazyvim/config/keymaps.lua  @ 7
--
-- - SAVVY: Normally, Select mode <Down>/<Up> extends the selection,
--   unless |keymodel| includes "stopsel", in which case it clears
--   the selection and returns to Insert mode. (But not in Visual mode;
--   <Down>/<Up> still extends a Visual mode selection.)
--   - However, using "stopsel" breaks snippets, where <Tab>bing inserts
--     the raw snippet text, then adds a new line consisting of a
--     single underscore, and it doesn't start "Snippet" mode.
--   - KLUGE: So instead of using "stopsel", we'll recreate the
--     behavior using stopsel-equivalent smap bindings.
--   - CXREF: See those smap bindings in mswin.lua:
--     ~/.kit/nvim/landonb/nvim-lazyb/lua/util/mswin.lua

map(
  { "i" },
  "<Down>",
  "&wrap == 1 ? '<C-O>gj' : '<C-O>j'",
  { desc = "Down", expr = true, silent = true }
)
-- CXREF: See mswin.lua for smap <Down>:
-- ~/.kit/nvim/landonb/nvim-lazyb/lua/util/mswin.lua

map(
  { "i" },
  "<Up>",
  "&wrap == 1 ? '<C-O>gk' : '<C-O>k'",
  { desc = "Up", expr = true, silent = true }
)
-- CXREF: See mswin.lua for smap <Up>:
-- ~/.kit/nvim/landonb/nvim-lazyb/lua/util/mswin.lua

-- For parity with nvim-depoxy.
Snacks.toggle.option("wrap", { name = "Wrap" }):map("<localleader>dw")

-- -----------------------------------------------------------------
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

-- As noted re: LazyVim <Down>/<Up> xmap bindings (see previous §),
-- <Down>/<Up> extend a Visual selection, rather than deselecting and
-- moving the cursor.
-- - Here we do the same for Visual selection <Left>/<Right>.
-- - These also work with <Ctrl-Q> (<Ctrl-V>) blockwise select.
-- - Note that you still need to hold <Shift> to extend Select selection
--   (which you can still do to extend Visual selection, but it's no
--   longer necessary).

wk.add({
  mode = { "x" },
  icon = "󰩭",
  { "<Left>", "<cmd>normal h<CR>", desc = "Extend Selection Leftward", silent = true },
  { "<Right>", "<cmd>normal l<CR>", desc = "Extend Selection Rightward", silent = true },
  -- Change LazyVim desc's.
  { "<Up>", desc = "Extend Selection Upward", silent = true },
  { "<Down>", desc = "Extend Selection Downward", silent = true },
})

-- -----------------------------------------------------------------
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

-- Supplant \qq to close Project window, so that it's not restored
-- on \ql Restore Last Session (because it's restored as a normal
-- buffer and not as an interactive Project buffer).
-- - Note that hooking VimLeave is too late to close Project (it'll
--   have been saved to the current session).
map("n", "<leader>qq", function()
  -- Close dubs_project_tray window.
  if vim.g.proj_running then
    vim.api.nvim_buf_delete(vim.g.proj_running, {})
    vim.g.proj_running = nil
  end

  -- Close vim-fugitive windows (which also don't reload properly).
  pcall(function()
    vim.fn["git_fugitive_window_cleanup#close_git_windows"]()
  end)

  vim.cmd("qa")
end, { desc = "Quit All", noremap = true })

-- SAVVY: Neovide adds a single keymap, <Cmd-Q> quit. In all the modes.
-- - CXREF: *Quit when Command+Q is pressed on macOS*
--   ~/.kit/rust/neovide/lua/init.lua @ 43
--   - DUNNO: Neovide doesn't `== 1`, but 0 is truthy. IDGI.
--     - E.g., run this — :lua if 0 then print("0!") end
--     - FIXME- Test Debian behavior.
-- - MAYBE: We could disable <Cmd-Q>, but there's also something to be said for
--   maintaining conventional macOS keybindings, such as <Cmd-Q>, <Cmd-M>, and
--   <Cmd-H>. (Though I don't care about <Cmd-W> or <Cmd-N>; and per mswin.lua
--   you'll see that while I wire conventional Cut, Copy, Paste, Select All,
--   Redo, and Undo, I use their Linux/Windows <Ctrl> bindings, not <Cmd>. Ha.)
-- - Note that Neovide includes an lmap |mapmode-l| |language-mapping|:
--     { "n", "i", "c", "v", "o", "t", "l" }
--   - But which-key rejects it: "WARNING Invalid mode `l`".
if vim.fn.has("macunix") == 1 then
  wk.add({ mode = { "n", "i", "c", "v", "o", "t" }, "<D-q>", desc = "Quit Neovide" })
end

-- -----------------------------------------------------------------
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

-- HSTRY/2024-12-21: Was <LocalLeader>dc, but made a little
-- more cumbersome to signal it's a little-more "destructive".
-- - And now I wonder if \dq save-all-quit should be \dQ...
--
-- CXREF:
-- ~/.kit/nvim/vim-scripts/start/bbye/plugin/bbye.vim
--
-- CALSO: <LocalLeader>dC | <Alt-f>c — the same.
wk.add({
  mode = { "n", "i" },
  "<LocalLeader>dC",
  -- HSTRY/2025-03-27: Previously just a simple delete buffer:
  --   "<cmd>Bdelete<CR>",
  function()
    require("util.buffer-delights").close_floats_or_delete_buffer()
  end,
  noremap = true,
  desc = "Close Floatwin(s) or Delete Buffer",
  icon = "󰆴",
})

-- Save all buffers, close all buffers, and quit — so next
-- instance starts with a fresh session.
-- - CXREF: You could do same with <M-f>l <M-f>e <M-f>x:
--   ~/.kit/nvim/landonb/nvim-lazyb/lua/config/keymaps/alt-menu.lua
map({ "n", "i" }, "<LocalLeader>dQ", function()
  vim.cmd([[wa]])
  vim.cmd([[only]])
  vim.cmd([[enew]])
  vim.cmd([[BufOnly]])
  vim.cmd([[qa]])
end, { desc = "Write All, Close All, Quit", noremap = true })

-- -----------------------------------------------------------------
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

-- So you don't have to leave Insert mode to add spells.
-- - nvim-lazyb doesn't set |spellfile|, so defaults to
--   ~/.config/$NVIM_APPNAME/spell/.{encoding}.add, e.g.,
--     ~/.config/nvim_lazyb/spell/spell/en.utf-8.add
-- SAVVY: A normal "normal" is a no-op from Insert mode:
--   wk.add({ mode = { "n", "i" }, "<LocalLeader>zg", "<cmd>normal zg<cr>" })
-- - But works if you normal! to inhibit mappings (tho unclear why,
--   esp. because you can <C-O> from Insert mode and run `normal zg`).
wk.add({
  mode = { "n", "i" },
  "<LocalLeader>zg",
  "<cmd>normal! zg<cr>",
  desc = "Add Good Word to &spellfile",
  icon = "",
})

-- -----------------------------------------------------------------
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

-- CALSO: Delete current line: <M-S-Del> or <LocalLeader>dd
wk.add({
  mode = { "n", "i" },
  "<LocalLeader>dd",
  "<cmd>normal! dd<cr>",
  desc = "Delete Line",
  icon = "󰛲",
})

-- -----------------------------------------------------------------
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

-- CXREF:
-- ~/.local/share/nvim_lazyb/lazy/LazyVim/lua/lazyvim/config/keymaps.lua @ 64
--
-- REFER: https://github.com/mhinz/vim-galore#saner-behavior-of-n-and-n
-- - The idea is to always search forward on n, or backwards on N.
--   - N searches in opposite direction of latest / or ? search.
--   - [v:searchforward] is 1 after forward search, 0 after backward.
-- - In the maps below, [v:searchforward] is an array lookup, and the
--   'Nn' or 'nN' string is the array, hahahaha, how clever!
-- - Then the zv just ensures the cursor line is not folded.
-- - Oh, also, I never use |?| search. Does anyone? Anyway, I never
--   experience the directional issue because I only ever forward search
--   (and if I want to search backward, I can start a search without
--   moving (e.g., <Shift-F1>) and then I'd |N| or <Shift-F3> to match
--   backwards).
--
-- We also add 'zz' to n and N to center matches — these complement the
-- non-centering matches, <F3>/<S-F3>, from blinky-search.
-- - Note we don't center when used as a selection or motion operator.
--   - Also note this omap inserts 'zz' when used in Insert mode:
--       map("o", "n", "'Nn'[v:searchforward].'zz'")
--     E.g., if you run `i<C-O>dn` from Normal mode, it will delete
--     forward word but then insert "zz".
--   - Also this map extends the selection but doesn't center (though
--     I'm unsure what happens to the zz, it's not inserted, either):
--       map("x", "n", "'Nn'[v:searchforward].'zz'")

map("n", "n", "'Nn'[v:searchforward].'zvzz'", { expr = true, desc = "Next Search Result" })
map("x", "n", "'Nn'[v:searchforward]", { expr = true, desc = "Next Search Result" })
map("o", "n", "'Nn'[v:searchforward]", { expr = true, desc = "Next Search Result" })
map("n", "N", "'nN'[v:searchforward].'zvzz'", { expr = true, desc = "Prev Search Result" })
map("x", "N", "'nN'[v:searchforward]", { expr = true, desc = "Prev Search Result" })
map("o", "N", "'nN'[v:searchforward]", { expr = true, desc = "Prev Search Result" })

-- -----------------------------------------------------------------
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

-- REFER: Note that command line completion is not like blink.cmp
-- completion (though you could run both in the cmdline).
-- - Use <Tab>/<Shift-Tab> to next/prev completion menu entries.
-- - Use <PageDown>/<PageUp> to jump by the page-full.
-- - Avoid <Down>/<Up>, which are (still) wired to history newer/
--   older, even when the wildmode| completion menu is showing.
-- - Avoid <Ctrl-D>/<Ctrl-U> which are not like <PageDown>/<PageUp>.
--   - <Ctrl-D> is more like <Ctrl-Space> and shows completion
--     if not showing (or does nothing if completion is showing).
--   - <Ctrl-U> is like i_CTRL-U and deletes the line backwards.
--
-- SPIKE: Can you map <Down>/<Up>, and inject <Tab>/<Shift-Tab>
-- when |wildmode| menu is showing, otherwise fallback <Down>/<Up>?

-- Map Command mode <Shift-Ctrl-W> like Insert mode.
-- - Use <C-u>, not our delete_back_line(), which acts on the buffer,
--   not the cmdline:
--     require("util.edit-juice.delete-backward").delete_back_line()
map({ "c" }, ctrl_keys.lookup("W"), "<c-u>", { desc = "Delete Back Line (C-S-W)" })

-- -----------------------------------------------------------------
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

-- SPIKE: LazyVim maps `gr` which shadows some LSP built-ins; do I care?
--   n gr *@<Lua 1119:
--     ~/.local/share/nvim_lazyb/lazy/LazyVim/lua/lazyvim/plugins/extras/editor/snacks_picker.lua:143>
--       References
if false then
  wk.add({
    mode = { "n" },
    -- REFER: |lsp-defaults| incl. |grr| |i_CTRL-S| etc.
    { "grn", desc = "vim.lsp.buf.rename()" },
    { "gra", desc = "vim.lsp.buf.code_actions()", mode = { "n", "x" } },
    { "grr", desc = "vim.lsp.buf.references()" },
    { "gri", desc = "vim.lsp.buf.implementation()" },
    { "grO", desc = "vim.lsp.buf.document_symbol()" },
    -- Obviously, we repurpose <Ctrl-S>
    --  { "<c-s>", desc = "vim.lsp.buf.signature_help()", mode = { "s" } },
  })
end

-- REFER: |gq| and |gw| commands both format via motion.
-- - E.g., `gqq` and `gww` both reformat the current line.
-- - The difference is that |gw| commands restore the cursor position.
-- DUNNO: These reformat commands don't always work, at least not in this file.
-- - E.g., pick any line and change its indent, then try `gqq` or `gww` to fix it.
-- - It works for lines atop this file, but at and after the first function def:
--     function M.inspectFn(obj)
--   they don't work.
-- - Fortunately, formatting on <Ctrl-S> save works.
-- ISOFF: Unless we want to define all the motion keys, we cannot set the group.
-- - Specifically, which-key doesn't show the |q| group when you press |g|.
--   - Nor does which-key show the |gq| group if we define only the group here,
--     but it will if we also define at least one final command, e.g., |gqq|.
--   - But then it *only* shows the one final command in the motion popup
--     (or whatever we define here), whereas if we omit the group and the
--     command desc's, after pressing |gq|, which-key shows the normal motion
--     key legend.
-- - So it's a trade-off. Either:
--   - Don't show the |q| option in the |g| legend, but do show the full motion
--     legend after pressing |gq|. (I.e., |q| is a "hidden" option.)
--   - Or, do show the |q| option in the |g| menu, but then we have to (re)define
--     all the motion key desc's we want to show in the motion legend.
-- DUNNO: While |gq| is missing from the |g| which-key popup, |gw| is not!
-- - And I don't see any map for it, either, e.g., `nmap gww` says not-found.
--   - So how does which-key know to show the |gw| option (and not |gq|)?
if false then
  wk.add({
    mode = { "n" },
    { "gq", group = "Format lines via {motion}" },
    { "gqq", desc = "Format the current line" },
    -- INERT: Add all the possible "gq*" commands and enable this wk.add.
    -- - See comment above re: ISOFF.
  })
end

-- -----------------------------------------------------------------
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

-- An `imap <C-j>` that Joins, and that positions the cursor
-- after what was the first line.
-- - REFER: |i_CTRL-J| is same an <NL>, "Begin new line."
-- - CALSO: |i_CTRL-M|, same as <CR>, "Begin new line."
--   - <Ctrl-m> behaves the same as <Ctrl-j>.
--   - So nothing really lost with this map; and it saves
--     you a trip to Normal mode (or a tedious delete seq.).
vim.keymap.set({ "i" }, "<C-j>", "<C-o>J", { desc = "Join" })

-- -----------------------------------------------------------------
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

-- Just a friendly built-in command reminder.
wk.add({
  mode = { "v" },
  "<C-g>",
  desc = "Visual/Select mode toggle",
})

-- -----------------------------------------------------------------
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

-- CXREF: Optional user config:
-- ~/.config/nvim_lazyb/lua/config/keymaps-client.lua
pcall(function()
  require("config.keymaps-client").setup()
end)

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

return M
