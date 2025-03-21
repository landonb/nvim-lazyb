-- vim:tw=0:ts=2:sw=2:et:ai:ft=lua
-- Author: Landon Bouma <https://tallybark.com/>
-- Project: https://github.com/landonb/nvim-lazyb#🧸

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

---@class lazyb.util.mswin
local M = {}

local map = vim.keymap.set

local ctrl_keys = require("util.ctrl2pua-keys")

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

-- DEVEL: After making changes to this file, press <F9> to source
-- it and to nil'ify package.loaded[]. Then call setup:
--
--   lua require('util.mswin').setup()

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

-- FTREQ: Spin this module off to its own plugin.
-- - Check other modules for related functionality to include.
--   - Incl. dubs_edit_juice: <M-S-Left|Right>, <C-S-PageUp|PageDown>,
--     maybe <C-BS>, <C-Del>, etc.
--     - Maybe also: <C-Left|Right> <C-M-Left|Right>
--   - Incl. alt_select_motion.vim: <C-S-Left|Right>
-- - Exclude the <C-e> map, which depends on external PUA injection.
-- - Open Neovim Issues re:
--   - 1.) When &selection=exclusive, snippet <Tab> selects one
--     less than the placeholder, such that typing to replace the
--     placeholder leaves the last placeholder character.
--   - 2.) When &keymodel includes "stopsel", selecting snippet
--     from completion menu inserts raw snippet, a newline, and
--     an underscore, and doesn't enter "Snippet mode" (what I
--     call it; I'm not sure if it's technically another mode,
--     or how Neovim handles it internally).
--     - FIXME- Look for open issue, and open if none found.
--       - MAYBE: Publish mswin.nvim and link from new Issue.
-- FTREQ: Move superfluous comments to git-commit and replace
-- with commit ref, then use plugin command to show commit
-- message in popup (like you see git-blame in popup via
-- :Gitsigns blame_line).

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

-- THANX: After reading vim.api.nvim_paste help, I found usage ideas
-- from GH (re: how to call from map rhs):
--   https://github.com/HUAHUAI23/nvim64/blob/64fe13b5329d/runtime/lua/start42.lua#L13
-- - BEGET: https://github.com/search?q=vim.api.nvim_paste&type=code
-- - HSTRY: Vim's mswin.vim uses paste#Paste() (that we thankfully don't have to port):
--   ${VIMRUNTIME:-/opt/homebrew/Cellar/neovim/HEAD-228fe50_1/share/nvim/runtime}/autoload/paste.vim
-- - CALSO: nvim_put (like nvim_paste, but not dot-repeatable).

-- OPTIN: Set `reselect_after_paste = "visual"` to reselect what was pasted,
-- when in Visual mode (not Select mode). (Which is somewhat interesting
-- behavior, but I'm not sure there's a compelling reason to enable it.)
--  M.reselect_after_paste = "visual"
M.reselect_after_paste = ""

-- SAVVY: We pass in the mode via separate xmap and smap bindings (because
-- if called via vmap, mode(1) is "v" or "V", and never "s", because Vim
-- switches to Visual mode before running the map rhs).

-- SAVVY: I don't think you can blockwise-paste from @+ system clipboard.
-- - In Vim, paste#Paste() sets virtualedit="all", e.g., equivalent to this:
--     local orig_ve = vim.o.virtualedit
--     vim.o.virtualedit = "all"
--     ...
--     vim.api.nvim_paste(content, also_break_nls, paste_in_single_call)
--     vim.o.virtualedit = orig_ve
--   But that doesn't make blockwise paste from @+ work in Neovim.
-- - REFER: Default &virtualedit= (empty). / CXREF: LazyVim sets to "block":
--     ~/.local/share/nvim_lazyb/lazy/LazyVim/lua/lazyvim/config/options.lua @ 109
-- - DTAIL: While I didn't find documentation that @+ and @* do not support
--   blockwise text, I confirmed empirically. Start Neovim via --noplugin, e.g.,:
--     neovide -- --listen "/tmp/nvim.socket-${DEPOXY_GVIM_NOPLUGIN:-🙅}" --noplugin &
--   Then test:
--   - Press <Ctrl-V> (or <Ctrl-Q>) to start blockwise select.
--     - Select a block of text (e.g., llllljjj to select 5 chars wide and 4 rows of text).
--     - Then yank it to the unnamed register: ""y
--   - Press <Ctrl-V> and select another block.
--     - Then yank it to a clipboard register: "+y or "*y
--   - Now check the reg type:
--       echo getregtype('"') -- ^V5
--       echo getregtype('+') -- V
--       echo getregtype('*') -- V
--   - You'll see that the clipboard registers report "V", for linewise text,
--     whereas the unnamed register reports, e.g., "\<C-V>5", for blockwise-visual
--     text (where "\<C-V>" is the ^V control character, and "5" is the block width).
--   In any case, the |getregtype| output makes it seem like this is by design.
--
-- - SAVVY/TL_DR: You cannot <C-V> blockwise text.
--   - To paste blockwise, use |y| and |p| and not the + or * registers.

function M.v_paste(mode)
  M.reposition_cursor_if_linewise_select(mode)
  local content = vim.fn.getreg("+")
  -- Per docs, "also break lines at CR and CRLF" (I think so paste
  -- also supports "\n\r" line-endings).
  local also_break_nls = true
  -- Use -1 to paste in single call, vs. calling nvim_paste mult. times.
  local paste_in_single_call = -1
  vim.api.nvim_paste(content, also_break_nls, paste_in_single_call)
  if M.reselect_after_paste == "visual" and mode == "x" then
    -- REFER: The `[ and `] marks ref. "previously changed or yanked text."
    -- Note this is not right-side inclusive, so we might 'l' afterwards.
    -- - THANX:
    --   https://stackoverflow.com/questions/4312664/is-there-a-vim-command-to-select-pasted-text
    vim.cmd("normal `[v`]")
    M.move_cursor_rightward_unless_in_leftmost_column(content)
  elseif (vim.fn.col(".") + 1) == vim.fn.col("$") then
    -- KLUGE: After paste, Neovim changes to Insert mode, and cursor is
    -- positioned one column left of the end of the paste.
    -- - Note that a simple vim.cmd("normal l") doesn't work when
    --   the cursor is at line's end.
    -- - Note that a kludgy-feeling startinsert! can work:
    --     vim.cmd.stopinsert()
    --     vim.schedule(function()
    --       vim.cmd("startinsert!")
    --     end)
    -- - But thankfully there's a better way:
    local cur_win = 0
    vim.api.nvim_win_set_cursor(cur_win, { vim.fn.line("."), vim.fn.col(".") + 1 })
  else
    M.move_cursor_rightward_unless_in_leftmost_column(content)
  end
end

-- When user triple-clicks to select linewise, the paste happens from
-- the same cursor position on the line after the selected lines.
-- - E.g., consider the following lines:
--     foo bar baz
--     bat cat hat
--   Now imagine user triple-clicks the middle of the first line
--   (where | is the cursor):
--     foo ba|r baz
--     bat cat hat
--   Now when user pastes, Vim deletes the selected line, but then
--   it leaves the cursor in the same column, i.e.:
--     bat ca|t hat
--   And the pasted text splits the second line!
-- So here we move the cursor to the beginning of the selection.
function M.reposition_cursor_if_linewise_select(mode)
  if mode == "S" then
    vim.fn.cursor(0, 1)
  end
end

-- Returns true if string being pasted would put cursor in first column.
-- - There's no need to check vim.fn.col("."). We can can just check for
--   trailing newline. (The vim.fn.col(".") reports "1" for both the first
--   and second col; and then you'd have to check anyway if what was pasted
--   ended with a newline or not to know where the cursor belongs).
function M.cursor_after_paste_in_leftmost_column(content)
  return string.match(content, "\n$")
end

-- Move cursor rightward one column if paste positions it incorrectly.
-- - SAVVY: I think this issue is related to using a lua function()
--   (or using "<cmd>...<CR>") as the map rhs.
--   - E.g., if you map <Down> using <cmd>:
--       imap <Down> <cmd>normal j<CR>
--     them sometimes the cursor ends up one column left of where you'd expect.
--     E.g., if you <End> and then <Down> from longer line to shorter line:
--       foo bar baz|
--       foo bar
--     The cursor ends up one left of the final column:
--       foo bar baz
--       foo ba|r
--     But that doesn't happen with a <C-O> map, e.g.,:
--       imap <Down> <C-o>j
--     Point being, I think there's some startinsert logic happening,
--     and when cursor is in final column in Normal mode, startinsert
--     puts cursor before final character (whereas startinsert! puts
--     cursor *after* final character).
--     - Though I'm not sure if we could similarly use <C-O> for paste
--       to avoid this shift-rightward kludge.
--     - Perhaps "<C-O>:lua require('util.mswin').v_paste('i')<CR>",
--       but I don't care enough to test (around) and find out.
function M.move_cursor_rightward_unless_in_leftmost_column(content)
  if not M.cursor_after_paste_in_leftmost_column(content) then
    vim.cmd("normal l")
  end
end

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

-- REFER: See |Select-mode| for how to switch between Select and Visual modes:
-- - In Select mode, <Ctrl-o> switches to Visual mode for one command.
-- - In Select mode, <Ctrl-g> switches to Visual mode.
-- - From Visual mode, <Ctrl-g> enters Select mode.

-- COPYD: The following fcn. is loosely transcribed from mswin.vim:
-- ${VIMRUNTIME:-/opt/homebrew/var/homebrew/linked/neovim/share/nvim/runtime}/scripts/mswin.vim
function M.setup()
  -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
  -- *** SELECT BEHAVIOR

  -- Default: &selection=inclusive
  -- - When &selection=inclusive, if you <Shift-Down> and <BS> to delete
  --   a line, it also deletes the first character from the second line.
  -- - When &selection=inclusive, if you <Shift-End> to select to the
  --   end of a line, then <BS> deletes the selection and also the
  --   trailing newline (so it join next line with current line).
  vim.o.selection = "exclusive"

  -- Set |selectmode| to choose when to start Select mode instead of Visual mode.
  -- Default: &selectmode=
  -- - mswin.vim starts select mode on 'mouse,key'.
  -- - I demoed just 'key', but my brain keeps thinking I'm in Select mode
  --   after I double-click or click-drag to make a selection. So incl. mouse.
  vim.o.selectmode = "mouse,key"

  -- The default right-click behavior moves the cursor to the position
  -- where the mouse was clicked, and then shows the popup menu (which
  -- you probably won't use), unless something is already selected and
  -- you right-click within the selection, then nothing happens.
  -- - The mswin.vim behavior sets mousemodel=popup, which doesn't move
  --   the cursor. Which doesn't quite feel right (not that anyone uses
  --   the popup menu (*right?*), so probably doesn't matter, but hey).
  --
  -- - Default: &mousemodel=popup_setpos
  -- - mswin.vim:
  --     vim.o.mousemodel = "popup"
  --

  -- Start selection on shifted motion character.
  -- Default: &keymodel=
  -- - <Shift-Left>/<Shift-Right> is built-in [count] words backward/forward.
  --   <Shift-Up>/<Shift-Down> is built-in scroll window [count] pages up/down.
  --   <Home>/<End>/<PageUp>/<PageDown> do nothing different with <Shift>.
  --   - All that said to say that enabling &keymodel doesn't make any
  --     important mappings unavailable (if you're gonna use arrow keys,
  --     you're probably fine using the other 4 motion keys, and, e.g.,
  --     <PageUp> is "easier" than <Shift-Up>, or at least just as easy,
  --     i.e., you're not losing any functionality).
  --     - Also, we'll wire <Ctrl-Left/Right> to work like they do in
  --       "most" other apps, i.e., same as built-in <Shift-Left/Right>
  --       (and we'll also wire <Alt-Left/Right> to jump to line beg/end).
  vim.o.keymodel = "startsel,stopsel"

  -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
  -- *** NEWLINE ALLOWANCE

  -- "backspace and cursor keys wrap to previous/next line"

  -- Default: &backspace=indent,eol,start
  vim.o.backspace = "indent,eol,start"

  -- Allow <Left>/<Right> to change to prev/next line in Normal and
  -- Visual modes ("<" and ">") and in Insert and Replace modes
  -- ("[" and "]"). Note nvim docs suggest not enabling for "h" and
  -- "l" keys (tho not sure why, perhaps to avoid unexpected behavior).
  -- Default: &whichwrap=b,s
  vim.opt.whichwrap:append({ ["<"] = true, [">"] = true, ["["] = true, ["]"] = true })

  -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
  -- *** CUT

  -- Orig. mswin.vim: "backspace in Visual mode deletes selection".
  -- - ISOFF: Don't set vmap <BS> because it conflicts with nvim-treesitter
  --   xmap <BS> aka M.node_decremental():
  --   - "Shrink selection to previous named node"
  --     ~/.local/share/nvim/lazy/nvim-treesitter/lua/nvim-treesitter/incremental_selection.lua @ 127
  -- - SAVVY: By default, <BS> is same as <h> and reduces selection by rightmost character.
  -- If we did enable this feature:
  -- - The simplest implementation:
  --   vnoremap <BS> d
  -- - ALTLY: Better yet, instead of "cut", make it a true delete.
  --   - Note the x, d, c, and s commands copy to the unnamed register,
  --     and if you set clipboard=unnamedplus, they also copy to the
  --     system clipboard. Which makes mswin.vim's `vnoremap <BS> d`
  --     behave like cut, not delete. This would make it like delete.
  --   vnoremap <BS> "_d

  -- Orig. mswin.vim: "CTRL-X and SHIFT-Del are Cut".
  vim.keymap.set({ "v" }, "<C-x>", '"+x', { silent = true, noremap = true, desc = "Clipboard Cut" })
  -- MAYBE: Should we omit <S-Del>?
  -- - I've never used it, but maybe it's muscle memory for some Windows users?
  -- - Be default, <Shift-Delete> does nothing to Select/Visual selection.
  --   - So there's no harm adding this map.
  -- stylua: ignore
  vim.keymap.set({ "v" }, "<S-Del>", '"+x', { silent = true, noremap = true, desc = "Clipboard Cut" })

  -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
  -- *** COPY

  -- Orig. mswin.vim: "CTRL-C and CTRL-Insert are Copy"
  -- - But skip <C-Insert>, which I doubt many people use (akin to <S-Del>).
  vim.keymap.set({ "v" }, "<C-c>", '"+y', {
    silent = true,
    noremap = true,
    desc = "Clipboard Copy",
  })
  -- ALTLY: If you wanted to keep the selection active in Visual mode,
  -- you could reselect it:
  --     vim.keymap.set({ "x" }, "<C-c>", function()
  --       vim.cmd([[normal "+y]])
  --       vim.cmd("normal `[v`]")
  --       local content = vim.fn.getreg("+")
  --       if not string.match(content, "\n$") then
  --         vim.cmd("normal l")
  --       end
  --     end, { silent = true, noremap = true, desc = "Clipboard Copy" })
  -- - In which case you'd need this smap with <Ctrl-g> calls to emulate the
  --   magic that (Neo)vim does around the vmap rhs in Select mode:
  --     vim.keymap.set(
  --       { "s" },
  --       "<C-c>",
  --       -- C-g toggles btw. Select and Visual modes, "+y yanks, gv reselects.
  --       [[<C-g>"+ygv<C-g>]],
  --       { silent = true, noremap = true, desc = "Clipboard Copy" }
  --     )

  -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
  -- *** PASTE

  -- Orig. mswin.vim: "CTRL-V and SHIFT-Insert are Paste"
  -- - But skip <S-Insert> (akin to <S-Del> and <C-Insert>).
  --
  -- REFER: Note that Neovide suggests similar maps, but they're
  -- unsatisfactory for me.
  -- - CXREF: ~/.kit/rust/neovide/website/docs/faq.md @ 5
  -- - COPYD: From faq.md; comments are mine except for the one noted.
  --
  --   if vim.g.neovide then
  --     -- Similar to our nmap below, but calls just |P|, whereas we
  --     -- call |gP|, which puts the cursor after what's pasted.
  --     -- - Using just |P|, the cursor is placed on the last
  --     --   character of what was pasted, rather than just after.
  --     --   - Which is weird, because if you paste twice in a row,
  --     --     it splits the first word you pasted! E.g., if you
  --     --     copy "abc" and paste-paste it, you'll get "ababcc".
  --     vim.keymap.set('n', '<D-v>', '"+P')
  --     -- Similar to previous nmap, with same paste-paste issue noted.
  --     vim.keymap.set('v', '<D-v>', '"+P')
  --     -- This cmap same as our cmap below, and "works perfect".
  --     vim.keymap.set('c', '<D-v>', '<C-R>+')
  --     -- This is just broken! Or at least it works from within a
  --     -- line, but not at the ends.
  --     -- - If cursor at start of line, this pastes *after* the
  --     --   first character (moves right one, then pastes).
  --     -- - If cursor at end of line, this just leaves Insert mode,
  --     --   and doesn't paste.
  --     -- - (And now I don't feel so bad about our complicated
  --     --    M.v_paste() fcn above! / Nor do I feel like all these
  --     --    comments are TMI or superfluous. Because if anyone asks,
  --     --    I can explain exactly why the faq.md maps are wrong...
  --     --    not that I plan to PR any changes, though. I think it'd
  --     --    be better to spin off this module to its own plugin...
  --     --    and then maybe to PR a link from the Neovide docs?)
  --     vim.keymap.set('i', '<D-v>', '<ESC>l"+Pli')
  --   end
  --   --
  --   -- DUNNO: The Neovide faq.md code block shows these nvim_set_keymap()
  --   -- calls after the if-neovide block, but not from an else block...
  --   -- I'd guess that's an error, and that these maps are meant for nvim,
  --   -- not Neovide.
  --   -- - Comment atop these maps says: "Allow clipboard copy paste in neovim".
  --   --
  --   -- REFER: mode="" — empty string for |:map|, i.e., nmap, vmap, xmap, omap
  --   -- - Compared to our nmap below, this pastes *after* the block cursor,
  --   --   which is what would happen if you hit |a| to enter Insert mode,
  --   --   and then pasted (so that the paste occurs after the block cursor).
  --   --   - But then you cannot paste to the start of the line from Normal mode!
  --   --   - I like our behaviour better, which behaves akin to pressing |i|
  --   --     and pasting *before* the cursor.
  --   --     - Though notice our behavior means you cannot paste to EOL from
  --   --       Normal mode. Which is fine, we can't have it both ways. But
  --   --       the Neovide approach is wonky if you copy a line and try to paste
  --   --       it before another line — if you paste from the first column,
  --   --       rather than move the current line down one and paste the
  --   --       copied line, it'll split the current line after the first
  --   --       character, and paste after that. (Also note the suggested
  --   --       if-vim.g.neovide nmap above pastes before the cursor, so the
  --   --       two nmaps from faq.md behave differently! (Seems like Neovide
  --   --       pays lip service to those who want <Ctrl-C>/<Ctrl-V> but they
  --   --       didn't actually verify the behavior. Though I'm not surprised,
  --   --       I don't know any Vimmers who care about <Ctrl-C>/<Ctrl-V> like
  --   --       I do!)
  --   vim.api.nvim_set_keymap('', '<D-v>', '+p<CR>', { noremap = true, silent = true})
  --   --
  --   -- REFER: mode="!" — for |:map!|, i.e., imap, cmap
  --   -- - This is same as our cmap below, but different than our imap,
  --   --   though the imap nonetheless appears to behave similarly.
  --   vim.api.nvim_set_keymap('!', '<D-v>', '<C-R>+', { noremap = true, silent = true})
  --   --
  --   -- MAYBE: Demo terminal mode and see if you want this tmap.
  --   vim.api.nvim_set_keymap('t', '<D-v>', '<C-R>+', { noremap = true, silent = true})
  --   --
  --   -- DUNNO: This map works in nvim, but not in Neovide (though faq.md does
  --   -- sorta suggest maybe vmap above for Neovide (though I don't get why
  --   -- the reselect_after_paste() calls all run after `if vim.g.neovide`
  --   -- and are not in an else block...)).
  --   -- - By default, selecting text and <D-v> replaces selection with
  --   --   literal "<D-v>". But in Neovide LazyVim, this vmap changes mode,
  --   --   from Select to Visual (and shows which-key). And pressing again
  --   --   after that has no effect. / In --noplugin Neovide, this map has
  --   --   no effect.
  --   vim.api.nvim_set_keymap('v', '<D-v>', '<C-R>+', { noremap = true, silent = true})

  -- REFER: |g| vs. |gP|: the latter "leaves the cursor just after the new text."
  vim.keymap.set({ "n" }, "<C-v>", '"+gP', { silent = true, desc = "Clipboard Paste" })

  -- Paste to command line (mswin.vim maps both <C-V> and <S-Insert>).
  -- - SAVVY: Ha, if { silent = true }, when you paste to command line, you won't see
  --   anything right away, but it'll appear when you press another key after paste.
  vim.keymap.set({ "c" }, "<C-v>", "<C-r>+", { desc = "Clipboard Paste" })

  -- SAVVY: See comment above re: you cannot blockwise-paste
  -- from @+ or @* Selection registers (aka system clipboard).
  -- - This was supported in Vim. Per mswin.vim:
  --   "Pasting blockwise and linewise selections is not possible in Insert
  --    and Visual mode without the +virtualedit feature. They are pasted as
  --    if they were characterwise instead."
  -- - Except that &virtualedit has no effect in Neovim, because
  --   getregtype('+') always reports that the system clipboard register
  --   is linewise ("V") and never blockwise ("<C-v>{width}").
  -- Also from orig. mswin.vim:
  -- - "Uses the paste.vim autoload script.""
  -- - "Use CTRL-G u to have CTRL-Z only undo the paste."
  --   exe 'inoremap <script> <C-V> <C-G>u' . paste#paste_cmd['i']
  --   exe 'vnoremap <script> <C-V> '       . paste#paste_cmd['v']
  -- REFER: |i_CTRL-\_CTRL-O| "like CTRL-O but don't move the cursor."
  -- stylua: ignore
  vim.keymap.set("i", "<C-v>", '<C-g>u<c-\\><c-o>"+gP',
    { silent = true, noremap = true, desc = "Clipboard Paste" }
  )
  -- Note we cannot combine these two maps (vim.keymap.set("v", ...))
  -- because vim.fn.mode() would always report "v" or "V".
  vim.keymap.set("s", "<C-v>", function()
    -- "s" or "S" (latter if you triple-click to select linewise).
    M.v_paste(vim.fn.mode(1))
  end, { silent = true, noremap = true, desc = "Clipboard Paste" })
  vim.keymap.set("x", "<C-v>", function()
    -- "v" or "V".
    M.v_paste(vim.fn.mode(1))
  end, { silent = true, noremap = true, desc = "Clipboard Paste" })

  -- ISOFF: Because author would often accidentally press <Insert>, I got
  -- rid of it — I remapped <Insert> on my keyboard to <Delete> (also <Insert>
  -- changes to that weird replace mode that I've never found it necessary
  -- to use).
  -- - Also this module only enables normal <C-X>/<C-C>/<C-V> cut/copy/paste,
  --   and not the alternative MS Windows <S-Del>/<C-Insert>/<S-Insert> maps.
  -- - So don't port these two maps from mswin.vim:
  --  imap <S-Insert> <C-V>
  --  vmap <S-Insert> <C-V>

  -- LATER: Maybe enable this in Neovim once implemented, if necessary.
  -- - REFER: |nvim-missing|:
  --   "These legacy Vim features are not yet implemented... 'guioptions'..."
  -- - REFER: Per mswin.vim: "For CTRL-V to work autoselect must be off."
  --   - "On Unix we have two selections, autoselect can be used."
  -- - On MacVim, |guioptions| defaults 'egmrLk'.
  --     set guioptions-=a
  -- - On Neovim, vim.o.guioptions is "".
  --   - So we could leave this enabled in Neovim, because no-op.
  --     But if Neovim implements |guioptions| and then something else
  --     breaks, we might be more confused than if Neovim implements
  --     |guioptions| and only paste breaks (because if the latter
  --     happens, we'll likely probe this file and find this comment).
  if vim.fn.has("nvim") == 0 and vim.fn.has("unix") == 0 then
    -- Unreachable code, because vim.fn.has("nvim") always == 1.
    vim.opt.guioptions:remove({ "a" })
  end

  -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
  -- *** BLOCKWISE-VISUAL

  -- "Use CTRL-Q to do what CTRL-V used to do"
  -- - Default: |CTRL-V| |blockwise-visual| "Start Visual mode blockwise."
  -- - Note that Normal mode <C-Q> already starts blockwise select in
  --   `nvim --noplugin` instance (though I didn't find it documented.)
  --  noremap <C-Q> <C-V>
  vim.keymap.set(
    { "n", "v", "o" },
    "<C-q>",
    "<C-v>",
    { silent = true, noremap = true, desc = "Start Visual mode blockwise" }
  )

  -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
  -- *** SAVE

  -- "Use CTRL-S for saving, also in Insert mode (<C-O> doesn't work well
  --  when using completions)."
  -- - REFER: |i_CTRL-S| is LSP-related in Neovim:
  --   - "CTRL-S is mapped in Insert mode to |vim.lsp.buf.signature_help()|"
  -- - ISOFF/CXREF: <C-S> maps defined by mapCtrlSSave():
  --   ~/.kit/nvim/landonb/nvim-lazyb/lua/config/keymaps.lua @ 181
  --  noremap <C-S> :update<CR>
  --  vnoremap <C-S> <C-C>:update<CR>
  --  inoremap <C-S> <Esc>:update<CR>gi

  -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
  -- *** UNDO

  -- "CTRL-Z is Undo; not in cmdline though"
  -- - Default: |CTRL-Z| |v_CTRL-Z| 'Suspend Nvim, like ":stop".'
  -- - REFER: Using empty string for mode (vim.keymap.set("", ...)) same as :map,
  --          i.e., { "n", "v", "o" }
  --   - Though doesn't work from visual/select or operator pending modes...
  --     - Not sure why original code uses noremap, and not nnorremap:
  --         noremap <C-Z> u
  --     - Which would be like this:
  --         vim.keymap.set({ "n", "v", "o" }, "<C-z>", "u",
  --           { silent = true, noremap = true, desc = "Undo" })
  -- ALTLY:
  --   vim.keymap.set({ "n" }, "<C-z>", "u", { silent = true, noremap = true, desc = "Undo" })
  --   vim.keymap.set({ "i" }, "<C-z>", "<C-o>u", { silent = true, noremap = true, desc = "Undo" })
  vim.keymap.set(
    { "n", "i" },
    "<C-z>",
    -- FTREQ: Can you restore cursor position better??
    -- - E.g., insert at EOL, then <Ctrl-Z>, and cursor goes penultimate.
    "<cmd>normal u<CR>",
    { silent = true, noremap = true, desc = "Undo" }
  )
  vim.keymap.set({ "v" }, "<C-z>", ":<C-u>u<CR>", { silent = true, noremap = true, desc = "Undo" })

  -- Ha, <Shift-Ctrl-Z> also backgrounds. Fortunately, we can <nop> it.
  -- - Insert mode <Shift-Ctrl-Z> enters ^Z character.
  vim.keymap.set({ "n" }, "<C-S-z>", "<nop>", { desc = "<nop>" })

  -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
  -- *** REDO

  -- "CTRL-Y is Redo (although not repeat); not in cmdline though"
  -- - Default Normal mode CTRL-Y: "Scroll window [count] lines upwards in the buffer."
  --   - Opposite Normal mode CTRL-E, scroll downwards.
  -- - Default i_CTRL-Y: "Insert the character which is above the cursor."
  --   - Opposite i_CTRL-E, "Insert the character which is below the cursor."
  -- - DUNNO: Similar to <C-z>, why does mswin.vim use noremap and not nnoremap?
  --     noremap <C-Y> <C-R>
  --     inoremap <C-Y> <C-O><C-R>
  --   - Similar to:
  --     vim.keymap.set({ "n", "v", "o" }, "<C-y>", "<C-r>",
  --       { silent = true, noremap = true, desc = "Redo" })
  vim.keymap.set({ "n" }, "<C-y>", "<C-r>", { silent = true, noremap = true, desc = "Redo" })

  -- CXREF: LazyVim adds blink.cmp <C-y> "select_and_accept" binding,
  -- which nvim-lazyb disables:
  --   ~/.kit/nvim/landonb/nvim-lazyb/lua/plugins/blink.cmp.lua
  -- - USAGE: Use <Tab> instead to select completion item.
  vim.keymap.set({ "i" }, "<C-y>", "<C-o><C-r>", { silent = true, noremap = true, desc = "Redo" })

  vim.keymap.set(
    { "v" },
    "<C-y>",
    ":<C-u>redo<CR>",
    { silent = true, noremap = true, desc = "Redo" }
  )

  -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
  -- *** SELECT ALL

  -- "Alt-Space is System menu"
  -- - ISOFF: In Neovide and MacVim, `:simalt ~<CR>` retorts:
  --     E319: Sorry, the command is not available in this version
  --   - We also don't care about application menus, do we.
  --  if has('gui')
  --    noremap <M-Space> :simalt ~<CR>
  --    inoremap <M-Space> <C-O>:simalt ~<CR>
  --    cnoremap <M-Space> <C-C>:simalt ~<CR>
  --  endif

  -- "CTRL-A is Select all"
  -- - Default: CTRL-A "Add [count] to the no. or alpha. char. at or after the cursor."
  --   - Opposite CTRL-X decrements (subtracts).
  -- - Default: i_CTRL-A "Insert previously inserted text."
  --   - SAVVY: Run `nvim --noplugin`, enter Insert mode, type something,
  --     press <Esc>, enter Insert mode again, and now <Ctrl-a> pastes the
  --     previous edit... a feature I've never used; seems like a specific
  --     copy-paste use case I'm not sure is worth remembering over just
  --     copy-paste... or using |q| and |Q| recording and replay.
  -- - SKIPD: mswin.vim defines cmap like nmap, but then <Ctrl-a> from the
  --   command line dismisses the command line and selects all text in the
  --   buffer, which seems weird (or just not that compelling a feature).
  vim.keymap.set(
    { "n", "v", "o" },
    "<C-a>",
    "gggH<C-O>G",
    { silent = true, noremap = true, desc = "Select all" }
  )
  vim.keymap.set(
    { "i" },
    "<C-a>",
    "<C-O>gg<C-O>gH<C-O>G",
    { silent = true, noremap = true, desc = "Select all" }
  )
  vim.keymap.set(
    { "s" },
    "<C-a>",
    "<C-C>gggH<C-O>G",
    { silent = true, noremap = true, desc = "Select all" }
  )
  vim.keymap.set(
    { "x" },
    "<C-a>",
    "<C-C>ggVG",
    { silent = true, noremap = true, desc = "Select all" }
  )

  -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
  -- *** NEXT/PREV WINDOW

  -- "CTRL-Tab is Next window"
  --  noremap <C-Tab> <C-W>w
  --  inoremap <C-Tab> <C-O><C-W>w
  --  cnoremap <C-Tab> <C-C><C-W>w
  --  onoremap <C-Tab> <C-C><C-W>w
  -- - Essentially this, which works:
  --     vim.keymap.set({ "n", "v", "o", "i", "c", "o" }, "<C-Tab>", "<C-W>w",
  --       { silent = true, noremap = true, desc = "Next tab window"})
  vim.keymap.set(
    { "n", "v" },
    "<C-Tab>",
    "<C-W>w",
    { silent = true, noremap = true, desc = "Next window" }
  )
  vim.keymap.set(
    { "i" },
    "<C-Tab>",
    "<C-o><C-w>w",
    { silent = true, noremap = true, desc = "Next window" }
  )

  -- Unsure why mswin.vim doesn't also map the reverse...
  -- - Oh, maybe because it's a <Shift-Ctrl> binding.
  --   - Though still works without using "magic" PUA char.
  --
  -- CTRL-Tab is Previous window
  -- - REFER: :h CTRL-W_W
  --  nnoremap <C-S-Tab> <C-W>W
  --  inoremap <C-S-Tab> <C-O><C-W>W
  vim.keymap.set(
    { "n", "v" },
    "<C-S-Tab>",
    "<C-w>W",
    { silent = true, noremap = true, desc = "Prev window" }
  )
  vim.keymap.set(
    { "i" },
    "<C-S-Tab>",
    "<C-o><C-w>W",
    { silent = true, noremap = true, desc = "Prev window" }
  )

  -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
  -- *** rejected mswin.vim features

  -- "CTRL-F4 is Close window"
  -- - Pressing this chord on an English keyboard is a stretch, IMO.
  --   And there are more intuitive bindings you could use, e.g.,
  --   <Alt-f>c, like classic File > Close.
  --
  -- vim.keymap.set({ "n", "v", "o", "i", "c", "o" }, "<C-F4>", "<C-W>c",
  --   { silent = true, noremap = true, desc = "Close window"})

  -- ISOFF: Neither :promptfind nor :promptrepl are implemented in Neovim.
  -- - In GUI Vims, they put up a Search and Search/Replace dialog,
  --   respectively (which author doesn't think they've ever used).
  --
  --  if has('gui')
  --    " "CTRL-F is the search dialog"
  --    noremap  <expr> <C-F> has("gui_running") ? ":promptfind\<CR>" : "/"
  --    inoremap <expr> <C-F> has("gui_running") ? "\<C-\>\<C-O>:promptfind\<CR>" : "\<C-\>\<C-O>/"
  --    cnoremap <expr> <C-F> has("gui_running") ? "\<C-\>\<C-C>:promptfind\<CR>" : "\<C-\>\<C-O>/"
  --    " "CTRL-H is the replace dialog, but in console,
  --    "  it might be backspace, so don't map it there"
  --    nnoremap <expr> <C-H> has("gui_running") ? ":promptrepl\<CR>" : "\<C-H>"
  --    inoremap <expr> <C-H> has("gui_running") ? "\<C-\>\<C-O>:promptrepl\<CR>" : "\<C-H>"
  --    cnoremap <expr> <C-H> has("gui_running") ? "\<C-\>\<C-C>:promptrepl\<CR>" : "\<C-H>"
  --  endif

  -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
  -- *** 1-LINE SCROLL (NUDGE) (not an mswin.vim change)

  -- LATER: Omit this from mswin.nvim spinoff.

  -- CXREF: See way-too-long comment re: <C-e>/<C-y> maps:
  --   ~/.kit/nvim/landonb/dubs_appearance/plugin/scroll_window_fix.vim
  --
  -- TL_DR: Because we changed Normal and Insert mode <Ctrl-y>, we broke
  -- parity with Normal and Insert mode <Ctrl-e>.
  -- - By default:
  --   - In Normal mode, C-e scrolls the window down by one line,
  --                 and C-y scrolls it up.
  --     In Insert mode, C-e mirrors characters from the line below, one char at a time;
  --                 and C-y similarly mirrors the line above.
  --
  -- But now, Normal mode <C-e> scrolls down, and there's no complementary scroll-up.
  -- Also now Insert mode <C-e> mirrors the line above, but there's nothing to mirror
  -- what's below.
  --
  -- This author has mever used the mirror feature, but I do sometimes scroll,
  -- so let's make Insert mode <C-e> behave like Normal mode <C-e>.
  -- - Also, let's add the complementary behavior, scroll down, at <Shift-Ctrl-e>,
  --   using the PUA kludge (which you'll need to inject into Neovim, e.g., using
  --   Hammerspoon config, alacritty.toml, etc.).

  -- Add scroll-down to Insert mode at Ctrl-e, to complement normal Ctrl-e,
  -- and acknowledging this masks the second half of the mirror neighbor line
  -- feature (that mswin.lua masks the other half of, <C-y>, above).
  vim.keymap.set(
    { "i" },
    "<C-e>",
    "<C-o><C-e>",
    { silent = true, noremap = true, desc = "Scroll Down 1 line" }
  )
  -- Do opposite at <Shift-Ctrl-E> (using PUA char. from Hammerspoon, Alacritty, etc.).
  -- REFER: Scroll 1 ll. up/down:
  -- - <Ctrl-Up>/<Ctrl-Down> (provided by dubs_edit_juice)
  -- - <Shift-Ctrl-E>/<Ctrl-e> (provided here)
  vim.keymap.set(
    { "n", "i" },
    ctrl_keys.lookup("E"),
    [[<Cmd>exec "normal! \<C-y>"<CR>]],
    { silent = true, noremap = true, desc = "Scroll Up 1 line (C-S-E)" }
  )
end

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

return M
