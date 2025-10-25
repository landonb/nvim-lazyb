-- vim:tw=0:ts=2:sw=2:et:ai:ft=lua
-- Author: Landon Bouma <https://tallybark.com/>
-- Project: https://github.com/landonb/nvim-lazyb#🧸

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

-- DEVEL: After making changes to this file, source it
-- and nil'ify package.loaded[], then call setup. E.g.:
--
--   luafile %
--   package.loaded['util.mswin'] = nil
--   lua require('util.mswin').setup()
--
-- - REFER: The author's Neovim config defines a special <F9> map to
--   source the current Lua file and to clear it from package.loaded[]:
--
--     https://github.com/landonb/nvim-lazyb/blob/XXXX/lua/config/keymaps.lua
-- FIXME: Update prev. link once published.

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

---@class lazyb.util.mswin
local M = {}

local ctrl_keys = require("util.ctrl2pua-keys")

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

-- DEVEL: Leave these enabled.
-- - Run Neovim with --noplugin or --clean to demo without kludges.
-- - These are essentially used just to demarcate the kludge code.
M.cut_kludge_enable = true
M.copy_kludge_enable = true
M.paste_kludge_enable = true

-- DEVEL: Enable clipboard kludges trace.
-- - REFER: Per |lua-vararg|, Neovim uses '...' for the vararg expr.
--   - Whereas Lua docs show that 'arg' is the vararg variable.
--     - *Variable Number of Arguments*
--       https://www.lua.org/pil/5.2.html
M.clip_kludge_trace = false
function M.ktrace(...)
  if M.clip_kludge_trace then
    print(...)
  end
end

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

-- FTREQ: Spin this module off to its own plugin.
-- - Check other modules for related functionality to include.
--   - Incl. dubs_edit_juice: <M-S-Left|Right>, <C-S-PageUp|PageDown>,
--     maybe <C-BS>, <C-Del>, etc.
--     - Maybe also: <C-Left|Right> <C-M-Left|Right>
--   - Incl. alt_select_motion.vim: <C-S-Left|Right>
--   - Incl. util/shifted.lua.
-- - Exclude the <C-e> map, which depends on external PUA injection.
-- - Open Neovim Issues re:
--   - 1.) When &selection=exclusive, snippet <Tab> selects one
--     less than the placeholder, such that typing to replace the
--     placeholder leaves the last placeholder character.
--   - 2.) When &keymodel includes "stopsel", selecting snippet
--     from completion menu inserts raw snippet, a newline, and
--     an underscore, and doesn't enter "Snippet mode" (what I
--     call it; I'm not sure if it's technically another mode,
--     other than you can check |vim.snippet.active()|).
--     - FIXME- Look for open issues, and open if none found.
--       - MAYBE: Publish mswin.nvim and link from new Issue.
-- FTREQ: Move superfluous comments to commit message and replace
-- with commit ref, then use plugin command to show commit message
-- in popup (like you see git-blame in popup via :Gitsigns blame_line).

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

-- THANX: After reading |nvim_paste()| help, I found usage ideas
-- from GH (re: how to call vim.api.nvim_paste from map rhs):
--   https://github.com/HUAHUAI23/nvim64/blob/64fe13b5329d/runtime/lua/start42.lua#L13
-- - BEGET: https://github.com/search?q=vim.api.nvim_paste&type=code
-- - HSTRY: Vim's mswin.vim uses paste#Paste() (that we thankfully don't have to port):
--   ${VIMRUNTIME:-/opt/homebrew/Cellar/neovim/HEAD-228fe50_1/share/nvim/runtime}/autoload/paste.vim
-- - CALSO: nvim_put (like nvim_paste, but not dot-repeatable).

-- OPTIN: Set `reselect_after_paste = "visual"` to reselect what was
-- pasted in Visual mode (it's not wired for Select mode).
-- - While this is somewhat interesting behavior, I'm not sure there's
--   a compelling reason to enable it.
--
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
--   - Now check the register types:
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
-- - "Loosely" because it very much deviates as well, but I've documented
--   the differences.
function M.setup()
  -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
  -- *** SELECT BEHAVIOR

  -- Per mswin.vim: "Set 'selection', 'selectmode', 'mousemodel'
  -- and 'keymodel' for MS-Windows."
  -- - BWARE: Except watch out for |'keymodel'| — don't include
  --   "stopsel" or it'll break snippets (such that selecting a
  --   snippet inserts the raw snippet, a newline, and an underscore,
  --   and it won't let you <Tab> between snippet stops).
  --   - In lieu of "stopsel", we'll wire smap bindings to
  --     stop selecting (see bottom of util/shifted.lua).
  -- - BWARE: And watch out for |'selection'| set to "exclusive"
  --   or it'll impair snippets (<Tab>bing to a snippet stop
  --   selects the snippet, but then typing to replace the
  --   placeholder leaves its last character).
  --   - In lieu of setting |'selection'| globally, we'll set it
  --     on demand for the Shifted special key smap bindings.
  --     - Note you'll need to set on demand for the completion
  --       bindings (e.g., in author's nvim-lazyb config, see
  --       the blink.cmp spec).

  -- ISOFF: See *BWARE* above re: "exclusive" impairs snippets.
  if false then
    -- Default: &selection=inclusive
    --
    -- SAVVY:
    -- - When &selection=inclusive, if you <Shift-Down> and <BS> to delete
    --   a line, it also deletes the first character from the second line.
    -- - When &selection=inclusive, if you <Shift-End> to select to the
    --   end of a line, then <BS> deletes the selection and also the
    --   trailing newline (so it joins the next line to the current line).
    --
    -- AHINT: If you see a block cursor, the character thereunder
    -- *is part of the selection*:
    -- - When &selection=inclusive, you'll see a block cursor at
    --   the end of the selection.
    -- - When &selection=exclusive, you'll see a caret at the end.
    --
    -- ISOFF: Setting selection=exclusive impairs snippet mode — after
    -- vim.snippet.jump (e.g., using <Tab>), which selects the next
    -- placeholder text, and then typing to replace the placeholder,
    -- it leaves the final character.
    -- - So we'll set "exclusive" on demand in the shifted smap commands
    --   (see util/shifted.lua).
    -- - And we'll set "inclusive" on demand from the completion maps
    --   (e.g., on <Tab>; if using nvim-lazyb, see plugins/blink-cmp.lua).
    -- - ALERT: Note this means that |selection| will vary when used
    --   otherwise, such as during a Visual mode selection, depending
    --   on the last on-demand setting.
    --   - ALTHO: However, you probably can't really make a Select mode
    --     selection that's *not* "exclusive" — the shifted-special key
    --     maps (in util/shifted.lua) change to "exclusive" mode, and
    --     the <2-LeftMouse> maps also change to "exclusive" mode.
    --     - As far as I know, the only way to make an "inclusive"
    --       Select mode selection is to `set selection=inclusive`,
    --       then use `v` to make a Visual mode selection, and then
    --       press <Ctrl-g> to toggle over to Select mode.
    --     - I.e., in normal practice, whenever you make a Select mode
    --       selection, the selection mode will be "exclusive".
    --   - MAYBE/FTREQ: Watch for end of completion or snippet mode and
    --     set selection=exclusive. (Which isn't trivial to do, I don't
    --     think; i.e., there is no ModeChanged event for snippets.
    --     Though we could check vim.snippet.active(), either via
    --     polling, or after other events.)
    --     - Alternatively, if user prefers "inclusive", we could
    --       monitor end of Select mode instead, and change from
    --       "exclusive" back to "inclusive".
    --     - Though note that currently the selection mode will
    --       only vary when user make a Visual selection...
    --       - MAYBE/FTREQ: In which case, maybe we need to set
    --         'selection' deliberately when 'v' or 'V' is used.
    --         - Then instead of changing selection *after* Select
    --           mode or Snippet mode, we change selection *before*
    --           changing to Select, Visual or Snippet mode (which
    --           we already do for Select and modes, so the only
    --           missing piece is Visual mode; and then we don't
    --           have to kludge a solution for monitoring Snippet
    --           mode).
    --         - LOPRI: This seems a little low priority for me,
    --           because most Visual mode motions work the same
    --           regardless of 'selection' mode (e.g., `ve` works
    --           the same; although `vj` (or `v<Down>`) behaves
    --           differently).
    vim.o.selection = "exclusive"
  end

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

  -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
  -- *** EMULATE "startsel,stopsel"

  -- BUGGN: Adding "stopsel" to |keymodel| breaks completion.
  --
  -- - E.g., if you type "vim.tbl_contains<Tab>", nvim inserts:
  --
  --     vim.tbl_contains(t, value, opts?)
  --     _
  --
  --   I.e., the raw completion item is inserted on the first line,
  --   an underscore is inserted on the second line, and Neovim does
  --   not start snippet mode.
  --
  -- - Without "stopsel", you can start selection with <Shift>+special,
  --   e.g., <Shift-Right>, but then releasing <Shift> and pressing just
  --   <Right> or <Left> modifies the selection (extends or contracts it),
  --   as opposed to stopping the selection (which is what "stopsel" does).
  --
  --   - Though note <Up> or <Down> will stop the selection, at least
  --     in LazyVim or nvim-lazyb, because of the custom maps (that react
  --     according to &wrap).
  --
  -- - Default: &keymodel=
  -- - mswin.vim:
  --     vim.o.keymodel = "startsel,stopsel"
  --
  -- Because "stopsel" breaks snippets, omit it. We'll emulate its
  -- behavior using smap bindings, defined in util/shifted.lua.
  vim.o.keymodel = "startsel"

  -- Define special and shifted-special smap commands.
  require("util.shifted")

  -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
  -- *** NEWLINE ALLOWANCE

  -- From mswin.vim: "backspace and cursor keys wrap to previous/next line".

  -- Default: &backspace=indent,eol,start (i.e., our setting is the same).
  vim.o.backspace = "indent,eol,start"

  -- Allow <Left>/<Right> to change to prev/next line in Normal and Visual
  -- modes ("<" and ">") and in Insert and Replace modes ("[" and "]").
  -- - Note that Neovim help suggests not enabling for "h" and "l" keys
  --   (though I'm not sure why, perhaps to avoid unexpected behavior?
  --   also I'm sure some nvim-lazyb commands expect "h" and "l" to stop
  --   at SOL/EOL).
  -- - Default: &whichwrap=b,s
  vim.opt.whichwrap:append({ ["<"] = true, [">"] = true, ["["] = true, ["]"] = true })

  -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
  -- *** CUT

  -- From mswin.vim: "backspace in Visual mode deletes selection".
  -- - ISOFF: Don't set vmap <BS> because it conflicts with nvim-treesitter
  --   xmap <BS> aka M.node_decremental():
  --   - "Shrink selection to previous named node"
  --     ~/.local/share/nvim/lazy/nvim-treesitter/lua/nvim-treesitter/incremental_selection.lua @ 127
  -- - SAVVY: By default, <BS> is same as <h> and reduces selection by rightmost character.
  -- If we did enable this feature, this would be the simplest implementation:
  --   vnoremap <BS> d
  -- - ALTLY: Better yet, instead of "cut", make vmap <BS> a true delete.
  --   - Note the x, d, c, and s commands copy to the unnamed register,
  --     and if you set clipboard=unnamedplus, they also copy to the
  --     system clipboard. Which makes mswin.vim's `vnoremap <BS> d`
  --     behave like cut, not delete. This would make it like delete:
  --   vnoremap <BS> "_d

  -- From mswin.vim: "CTRL-X and SHIFT-Del are Cut".
  vim.keymap.set({ "v" }, "<C-x>", '"+x', { silent = true, noremap = true, desc = "Clipboard Cut" })
  -- MAYBE: Should we omit <S-Del>?
  -- - I've never used it, but maybe it's muscle memory for some Windows users?
  -- - By default, <Shift-Delete> does nothing to Select/Visual selection.
  --   - So there's no harm adding this map.
  --   - Though we don't add the corresponding <C-Insert> (copy) or <S-Insert>
  --     (paste) maps (mainly because this author doesn't have an <Insert> key
  --     on their keyboard).
  -- stylua: ignore
  vim.keymap.set({ "v" }, "<S-Del>", '"+x', { silent = true, noremap = true, desc = "Clipboard Cut" })

  -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
  -- *** COPY (See below for Insert Mode Copy Kludge)

  -- From mswin.vim: "CTRL-C and CTRL-Insert are Copy".
  -- - But we'll skip <C-Insert>, which I doubt (m)any people use.

  -- If you *didn't* want to keep the selection active, it's simpler:
  --   snoremap <silent> <C-c> <C-O>"+y
  --   xnoremap <silent> <C-c> "+y
  -- but we'll keep the selection active, which is how mswin.vim works,
  -- and how <Ctrl-C> behaves in most apps.

  vim.keymap.set(
    { "s" },
    "<C-c>",
    -- C-g toggles btw. Select and Visual modes, "+y yanks, gv reselects.
    [[<C-g>"+ygv<C-g>]],
    { silent = true, noremap = true, desc = "Clipboard Copy" }
  )

  vim.keymap.set({ "x" }, "<C-c>", function()
    vim.cmd([[normal "+y]])
    vim.cmd("normal `[v`]")
    local content = vim.fn.getreg("+")
    if vim.o.selection == "exclusive" and not string.match(content, "\n$") then
      vim.cmd("normal l")
    end
  end, { silent = true, noremap = true, desc = "Clipboard Copy" })

  -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
  -- *** PASTE (See below for Insert Mode Paste Kludge)

  -- REFER: |g| vs. |gP|: the latter "leaves the cursor just after the new text."
  -- - TRACK: (Oddly?) This map does not exhibit the same issue as Insert mode
  --   paste, which sometimes runs before the double-click selection is made,
  --   where you'll see a literal `"+gP` inserted. (See imap <C-c> kludge below.)
  vim.keymap.set({ "n" }, "<C-v>", '"+gP', { silent = true, desc = "Clipboard Paste" })

  -- Paste to command line (mswin.vim maps both <C-V> and <S-Insert>).
  -- - SAVVY: Ha, if { silent = true }, when you paste to command line, you won't see
  --   anything right away, but it'll appear when you press another key after pasting.
  vim.keymap.set({ "c" }, "<C-v>", "<C-r>+", { desc = "Clipboard Paste" })

  -- SAVVY: See comment above re: you cannot blockwise-paste
  -- from @+ or @* Selection registers (aka system clipboard).
  -- - This was supported in Vim. Per mswin.vim:
  --   "Pasting blockwise and linewise selections is not possible in Insert
  --    and Visual mode without the +virtualedit feature. They are pasted as
  --    if they were characterwise instead."
  -- - Except that &virtualedit has no effect in Neovim, because
  --   getregtype("+") always reports that the system clipboard register is
  --   linewise ("V") and never blockwise ("<C-v>{width}") (see `getregtype`
  --   examples above).
  -- Also from mswin.vim:
  -- - "Uses the paste.vim autoload script."
  -- - "Use CTRL-G u to have CTRL-Z only undo the paste."
  --   exe 'inoremap <script> <C-V> <C-G>u' . paste#paste_cmd['i']
  --   exe 'vnoremap <script> <C-V> '       . paste#paste_cmd['v']
  -- REFER: |i_CTRL-\_CTRL-O| "like CTRL-O but don't move the cursor."

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

  -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
  -- *** COPY KLUDGE (INSERT MODE)

  -- BUGGN: If you double-click-and-<Ctrl-C> too fast from Insert mode,
  -- Neovim leaves Insert mode instead of copying, and *then* it makes the
  -- selection, albeit one character less than expected.
  -- - The Ctrl-C is processed while the editor is still in Insert mode,
  --   because (I assume) Neovim is waiting for |'mousetime'| to see if a
  --   third mouse click is forthcoming.
  --   - And |i_CTRL-C| is wired to "Quit insert mode, go back to Normal
  --     mode", which is why the mode change.
  -- - Note that when I double-click-drag (e.g., to select two words),
  --   I cannot reproduce this issue. It's only what I double-click-copy
  --   a single word that I can trigger the Insert mode <C-c> map instead
  --   of the Select mode <C-c> map.
  --   - Even if I extend &mousetime, e.g., to 2000 msec., I cannot
  --     reproduce the issue. So perhaps holding the second click or the
  --     dragging forces Neovim to change to Select (or Visual) mode before
  --     the imap runs?

  -- Copy kludge state.
  M.copy_pending = false
  M.kludge_2clicks = false

  if M.copy_kludge_enable then
    -- If user double-click-copies too fast, this Insert mode map
    -- runs after <2-LeftMouse> event, but before ModeChanged to "s".
    vim.keymap.set({ "i" }, "<C-c>", function()
      if M.kludge_2clicks then
        M.ktrace("COPY 2click")
        -- Wait for ModeChanged ("s") to copy the selection, because this
        -- runs before the selection is made.
        M.copy_pending = true
        -- We also need to exit Insert mode or the selection will be
        -- broken, such that the statusline shows Insert mode, even
        -- though a selection is visually active.
        -- - It messes up other keys, too. E.g., while user sees INSERT
        --   indicated in statusline but also sees an active selection,
        --   if they then press <Down> (which should stop the selection),
        --   "gj" is inserted instead (from the <Down> map).
        -- - Or, user sees INSERT indicated in statusline, but then <Esc>
        --   goes to Select mode.
        -- So, so very strange... or at least this wasn't an intuitive sol'n.
        vim.cmd("stopinsert")
      else
        M.ktrace("COPY 1click")
        -- Emulate built-in |i_CTRL-C|:
        -- - "Quit insert mode, go back to Normal mode."
        -- - "Do not check for abbreviations."
        -- - "Does not trigger the |InsertLeave| autocommand."
        -- Note that `stopinsert` triggers InsertLeave, unlike built-in i_CTRL-C.
        -- - Fortunately, we can use a return `expr` to trigger built-in behavior.
        return "<C-c>"
      end
    end, {
      -- SAVVY: If not using 'expr', the eventual selection will be
      -- contracted by one character (and then the copy kludge would
      -- have to `l` to extend the selection before copying it).
      expr = true,
      silent = true,
      noremap = true,
      desc = "Clipboard Copy (2fast4doubleclick)",
    })

    -- DEVEL: Uncomment if you want to verify that the `return <C-c>`
    -- above does not trigger InsertLeave.
    --
    --   vim.api.nvim_create_autocmd("InsertLeave", {
    --     group = require("util").augroup("copy_kludge"),
    --     callback = function()
    --       M.ktrace("InsertLeave")
    --     end,
    --   })
  end

  -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
  -- *** PASTE KLUDGE (INSERT MODE)

  -- BUGGN: If you double-click-and-paste too fast, Neovim runs the
  -- Insert mode paste map, not the Select map.
  -- - E.g., consider a "simple" Insert map like this:
  --     vim.keymap.set("i", "<C-v>", '<C-g>u<c-\\><c-o>"+gP',
  --       { silent = true, noremap = true, desc = "Clipboard Paste" }
  --     )
  --   Usually, double-click and <Ctrl-V> paste works fine.
  --   - But, if you hit <Ctrl-V> quickly enough after double-clicking,
  --     instead of pasting, it inserts the literal command — "+gP
  -- - This happens because Neovim is still waiting for the second click
  --   and remains in Insert mode. I.e., normally, double-click then
  --   paste runs the Select mode map. But not if you're too fast.

  -- Paste kludge state.
  M.paste_pending = false
  M.kludge_lastcol = false
  M.kludge_2clicks = false

  -- Leave this true. (I wrote an earlier algorithm that behaved retroactively,
  -- and would cleanup the mess afterwards, i.e., it would run the normal imap
  -- paste command, but then if "+gP was inserted instead, the ModeChanged event
  -- would remove it and redo the paste. But then I discovered that 2-LeftMouse
  -- happens *before* the imap, which greatly simplifies the kludge, and makes
  -- it less kludgy. (Phew!)
  -- - But I'm keeping the old approach for posterity, or at least in history —
  --   LATER: feel free to replace the old code with a Git SHA ref. later.)
  M.paste_kludge_preactive = true

  if M.paste_kludge_enable then
    if M.paste_kludge_preactive then
      -- This is the less kludgy approach: avoid the faulty paste if a
      -- <2-LeftMouse> precedes the imap.
      -- - See the 'else' block for an alternative, reactive approach.

      vim.keymap.set({ "i" }, "<C-v>", function()
        if M.kludge_2clicks then
          M.ktrace("PASTE 2click")
          -- Wait for ModeChanged ("s") to paste.
          M.paste_pending = true
          -- Whether to later call `startinsert` or `startinsert!`.
          M.record_lastcol()
          -- We also need to exit Insert mode, for the same reasons documented
          -- above for the <Ctrl-C> kludge.
          vim.cmd("stopinsert")
        else
          M.ktrace("PASTE 1click")
          -- REFER: |i_CTRL-G_U| will "close undo sequence, start new change".
          -- - From mswin.vim: "Use CTRL-G u to have CTRL-Z only undo the paste."
          -- REFER: |i_CTRL-\_CTRL-O| is "like CTRL-O but don't move the cursor."
          -- - Where |CTRL-O|	will "execute one command, return to Insert mode".
          return '<C-g>u<c-\\><c-o>"+gP'
        end
      end, {
        expr = true,
        silent = true,
        noremap = true,
        desc = "Clipboard Paste (2fast4doubleclick)",
      })
    else
      -- This was my original approach: Permit the faulty paste, then
      -- cleanup. But that was before I realized the <2-LeftMouse>
      -- arrives before the imap. (I'll say it again, Phew!)

      -- TIMED: 500 msec. is too short. (I haven't checked 501-749 msec.)
      -- - It should be at least |'mousetime'| (500 msec.).
      M.paste_kludge_delay = 750

      M.paste_kludge_reset = function()
        M.ktrace("RESET KLUDGE PASTE")
        M.paste_pending = false
        M.kludge_lastcol = false
        M.kludge_2clicks = false
      end

      vim.keymap.set("i", "<C-v>", function()
        M.paste_pending = true
        vim.defer_fn(function()
          if M.paste_pending then
            -- The user has not double-clicked, so nothing to kludge.
            M.ktrace("DEFER-PASTE: Not kludging: mode:", vim.fn.mode())
            M.paste_kludge_reset()
          else
            -- The user double-clicked, so we already reset state.
            M.ktrace("DEFER-PASTE: After kludge: mode:", vim.fn.mode())
          end
        end, M.paste_kludge_delay)
        -- REFER: Start new undo seq. w/ <C-g>u; don't move cursor w/ <C-\><C-o>.
        return '<C-g>u<c-\\><c-o>"+gP'
      end, { expr = true, silent = true, noremap = true, desc = "Clipboard Paste" })

      vim.keymap.set({ "i" }, "<LeftMouse>", function()
        M.ktrace("<LeftMouse>")
        -- So that paste then double-click-to-select doesn't run kludge.
        M.paste_kludge_reset()
        return "<LeftMouse>"
      end, {
        expr = true,
        noremap = true,
        silent = true,
        desc = "Copy Kludge — Single Click",
      })
    end
  end

  -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
  -- *** CUT KLUDGE (INSERT MODE)

  -- Fix Double-Click-<Ctrl-X>-Cut-Too-Fast.
  -- - For all the same reasons documented above.

  -- Cut kludge state.
  M.cut_pending = false
  M.kludge_lastcol = false
  M.kludge_2clicks = false

  -- Similar to imap <C-c> above: Check if user double-clicked,
  -- because this map runs *after* the <2-LeftMouse> but before
  -- ModeChanged.
  if M.cut_kludge_enable then
    vim.keymap.set({ "i" }, "<C-x>", function()
      if M.kludge_2clicks then
        M.ktrace("CUT 2click")
        M.cut_pending = true
        -- Check if user cutting final word from line.
        -- - Fortunately, the reported cursor position is from
        --   the end of the selection-to-be. (R U Surprised?)
        M.record_lastcol()
        vim.cmd("stopinsert")
      else
        M.ktrace("CUT 1click")
        -- REFER: |i_CTRL-X| *insert_expand* "CTRL-X enters a sub-mode
        -- where several commands can be used. Most of these commands
        -- do keyword completion; see |ins-completion|."
        -- - E.g., try <C-x><C-l> to see completion menu of whole lines
        --   from current buffer.
        return "<C-x>"
      end
    end, {
      -- SAVVY: Similar to using `expr` for <Ctrl-C> and <Ctrl-V> kludges,
      -- if not using `expr`, eventual selection would be contracted by its
      -- rightmost character (and ModeChanged command would need to `l` it
      -- back in).
      expr = true,
      silent = true,
      noremap = true,
      desc = "Clipboard Cut (2fast4doubleclick)",
    })
  end

  -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
  -- *** SHARED KLUDGE WIRING (On Double-click, and ModeChanged)

  -- TRYME: Cut/Copy/Paste from the end of the next line to verify x
  -- that the kludges support wide chars: "여보세요" 👋 foo b ar x
  -- (which is "hello" in Korean).

  if M.copy_kludge_enable or M.paste_kludge_enable or M.cut_kludge_enable then
    -- The double-click-and-cut/copy/paste-too-fast kludges *can* work without
    -- monitoring the |2-LeftMouse| event, but then they're extra kludgy.
    -- - Fortunately, this event fires just before imap, so each imap kludge
    --   cam check if a double-click preceded it, and then they can defer
    --   the cut/copy/paste until the |ModeChanged| event.
    -- - REFER: See |'mousetime'|, which defaults to 500 msec.
    -- - REFER: Note that Neovim triggers two click events when you
    --   double-click — |LeftMouse| and then |2-LeftMouse| (just FYI).
    --   - *Mouse double-click triggers a click*
    --     https://github.com/neovim/neovim/issues/22610
    -- - Note the cut/copy/paste race condition doesn't appear to affect
    --   Normal mode; see util/shifted.lua for Normal mode 2-LeftMouse
    --   that sets selection="exclusive".
    vim.keymap.set({ "i" }, "<2-LeftMouse>", function()
      M.ktrace("<2LeftMouse>")
      M.kludge_2clicks = true
      -- We don't need to change &selection, but it follows the behavior
      -- of the shift-selection maps (see util/shifted.lua).
      vim.o.selection = "exclusive"
      -- Note that double-clicking inside a buffer window will always change
      -- to either Visual or Select mode — but that double-clicking the sign
      -- column or the status line doesn't cause a mode change.
      vim.defer_fn(function()
        M.ktrace("RESET <2LeftMouse>")
        M.kludge_2clicks = false
      end, vim.o.mousetime)
      return "<2-LeftMouse>"
    end, {
      expr = true,
      noremap = true,
      silent = true,
      -- Aka, the Double-Clickboard Kludges.
      desc = "Double-Click Cut-Copy-Paste Kludge",
    })

    -- After cut or paste kludge runs their vim.cmd() command, the
    -- statusline shows NORMAL mode, and the user sees a block
    -- cursor, but then moving the cursor returns to Insert mode.
    -- - Note that a 0-msec. vim.defer_fn(function() ... end, 0) also
    --   works. But it doesn't work if we don't run `startinsert`
    --   without deferring. (Though an alternative approach might
    --   be to call `nvim_win_set_cursor`, as done in M.v_paste.)
    function M.record_lastcol()
      local i_curswant = 5
      local curpos = vim.fn.getcursorcharpos()
      M.ktrace("KLUDGE: mode:", vim.fn.mode(), "/ curpos:", vim.inspect(curpos))
      if curpos[i_curswant] >= vim.fn.virtcol("$") then
        M.kludge_lastcol = true
      end
    end

    function M.restartinsert()
      vim.schedule(function()
        M.ktrace("restartinsert: kludge_lastcol:", M.kludge_lastcol)
        if M.kludge_lastcol then
          -- So that cursor positioned at EOL, and not penultimate column.
          vim.cmd("startinsert!")
          M.kludge_lastcol = false
        else
          vim.cmd("startinsert")
        end
      end)
    end

    -- (Finally!) Perform the kludge on ModeChanged.
    vim.api.nvim_create_autocmd("ModeChanged", {
      group = require("util").augroup("clipboard_kludge"),
      callback = function()
        local mode = vim.fn.mode()
        -- stylua: ignore
        M.ktrace("ModeChanged:", mode, "/ M.kludge_2clicks:", M.kludge_2clicks,
          "/ M.cut_pending:", M.cut_pending, "/ M.copy_pending:", M.copy_pending,
          "/ M.paste_pending:", M.paste_pending)
        if mode == "s" and M.kludge_2clicks then
          if M.cut_pending then
            M.ktrace("CUT KLUDGE: kludge_lastcol:", M.kludge_lastcol)
            -- SAVVY: If the `imap <C-x>` is not an <expr> map, the
            -- selection is contracted and made one shy of what the
            -- user double-clicked, and we'd need to `l` to extend it:
            --   vim.cmd([[execute "normal! \<C-g>l\"+d"]])
            vim.cmd([[execute "normal! \<C-g>\"+d"]])
            M.restartinsert()
          elseif M.copy_pending then
            M.ktrace("COPY KLUDGE")
            -- SAVVY: This only works correctly if the <C-c> imap calls :stopinsert.
            -- - Note you'd need to extend the selection rightward one character
            --   if the <C-c> imap wasn't an 'expr' map (using `l`; I think because
            --   a non-`expr` imap causes a mode change?):
            --     vim.cmd([[execute "normal! \<C-g>l\"+ygv\<C-g>"]])
            vim.cmd([[execute "normal! \<C-g>\"+ygv\<C-g>"]])
            -- At this point, what was double-clicked is selected, and statusline
            -- shows SELECT mode, but if cursor moved, exits immediately to Normal
            -- mode. Fortunately (kludgefully), `startinsert` solves it (leaves
            -- Select mode active, and moving the cursor returns to Insert mode,
            -- as expected).
            -- - ALTHO: But after this, note that shift-selecting down will
            --   select to the end of the current line only and will include
            --   the newline, unlike normal behavior, which selects to the
            --   same character position on the following line. Similarly,
            --   shift-selecting up now selects to start of the line above,
            --   and not to the same character position on the line above as
            --   the beginning character position of the selection.
            vim.cmd("startinsert")
          elseif M.paste_pending then
            if M.paste_kludge_preactive then
              M.ktrace("PASTE KLUDGE")
              vim.cmd([[execute "normal! \<C-g>\"+gP"]])
              M.restartinsert()
            else
              -- Defer, otherwise the normal! sequence is inserted literally.
              -- - LATER: Remove this (disabled) block and replace with Git SHA ref.
              vim.defer_fn(function()
                if M.kludge_lastcol then
                  M.ktrace("Mode 's' DEFER is last col")
                  vim.cmd([[execute 'normal! $xxxx"+gp$']])
                  vim.cmd("startinsert!")
                  M.kludge_lastcol = false
                else
                  M.ktrace("Mode 's' DEFER not last col")
                  vim.cmd([[execute 'normal! 4dh"+gP']])
                end
                -- DEVEL: Increase delay to see "+gP inserted, then fixed,
                -- e.g., if you try 200 msec. you'll see the kludge play out.
              end, 0)
            end
          end
        end
        -- Reset state except for M.kludge_lastcol, which is needed by the
        -- M.restartinsert() vim.schedule() callback.
        M.cut_pending = false
        M.copy_pending = false
        M.paste_pending = false
        M.kludge_2clicks = false
      end,
    })
  end

  -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
  -- *** COMMENTED BUT INADVISABLE: NEOVIDE SUGGESTED PASTE MAPS

  -- REFER: Note that Neovide suggests some paste maps, but they're
  -- unsatisfactory for me.
  -- - CXREF: ~/.kit/nvim/neovide/website/docs/faq.md @ 5
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

  -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
  -- *** COMMENTED BUT INAPPLICABLE: ALT. PASTE MAPS

  -- Orig. mswin.vim: "CTRL-V and SHIFT-Insert are Paste"
  -- - But skip <S-Insert> (akin to <S-Del> and <C-Insert>).

  -- ISOFF: Because author would often accidentally press <Insert>, I got
  -- rid of it — I remapped <Insert> on my keyboard to <Delete> (also <Insert>
  -- changes to that weird replace mode that I've never found it necessary
  -- to use).
  -- - Also this module focuses on typical <C-X>/<C-C>/<C-V> cut/copy/paste,
  --   and not the atypical MS Windows <S-Del>/<C-Insert>/<S-Insert> maps
  --   (though it nonetheless wires <S-Del>, because that binding not wired
  --   by default, so doesn't "cost" anything).
  -- - But we don't port these two maps from mswin.vim (mostly because author
  --   doesn't have an <Insert> key, and I don't want to test/support these):
  --     imap <S-Insert> <C-V>
  --     vmap <S-Insert> <C-V>

  -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
  -- *** COMMENTED BUT INAPPLICABLE: DISABLE AUTOSELECT

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
  -- *** START BLOCKWISE-VISUAL MODE

  -- "Use CTRL-Q to do what CTRL-V used to do"
  -- - Default: |CTRL-V| |blockwise-visual| "Start Visual mode blockwise."
  -- - Note that Normal mode <C-Q> already starts blockwise select in
  --   `nvim --noplugin` instance (though I didn't find it documented.)
  -- - Orig. Vim implementation:
  --     noremap <C-Q> <C-V>
  -- - Orig. Lua conversion:
  --     vim.keymap.set(
  --       { "n", "v", "o" },
  --       "<C-q>",
  --       "<C-v>",
  --       { silent = true, noremap = true, desc = "Start Visual mode blockwise" }
  --     )
  -- - Now with "exclusive" selection mode:
  vim.keymap.set({ "n", "v", "o" }, "<C-q>", function()
    vim.o.selection = "exclusive"
    return "<C-v>"
  end, {
    expr = true,
    noremap = true,
    silent = true,
    desc = "Start Visual mode Blockwise Exclusive",
  })

  -- REFER: See util/shifted.lua for similar `v` and `V` re-maps.

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
