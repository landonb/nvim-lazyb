-- vim:tw=0:ts=2:sw=2:et:ai:ft=lua
-- Author: Landon Bouma <https://tallybark.com/>
-- Project: https://github.com/landonb/nvim-lazyb#🧸

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

---@class lazyb.config.keymaps.alt-menu
local M = {}
M.alt_f = ""
M.alt_w = ""

local map = vim.keymap.set

local alt_keys = require("util.alt2meta-keys")

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

-- FTREQ/MAYBE: ft-specific jumpers:
-- - <Alt-w>h moves cursor to :help window (ft=help)
-- - <Alt-w>n moves cursor to Noice window (ft=noice)
-- - <Alt-w>q moves cursor to Quickfix window (ft=qf)
-- - THOTS: Starting with winnr()+1, look for next matching ft.
--   Wrap around at end. Stop back at starting winnr().
--   - Remember starting window so running command twice acts
--     as toggle (that, or running command from target window
--     runs :CTRL-W_p instead).
--   - Use vim.nvim_tabpage_list_wins(0) as alt to while <= winnr("$")
--     - Could you pass through vim.tbl_filter or would that
--       not respect order? Could always sort...
--     - nvim_tabpage_list_wins(0) returns, e.g.,
--         { 5158, 1000, 1007, 5699, 5622, 5274, 5267, 5744, 5743, 5160, 5159 }
--       which matches my window order, per vim.api.nvim_get_current_win()
--       - So a tbl_filter might work.
--   - SERCH: winnr\(.\\$

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

-- Create useful key mappings inspired by :wincmd and the gVim menu bar
-- (as configured by $VIMRUNTIME/menu.vim, which still exists in Neovim).
-- - These are especially useful from Insert mode, if you want to avoid
--   escaping to normal mode for some commands (like splitting the window).

-- Builtin file menu entries:
--
--   Lazyb    GVim     GVim                        Vim
--    Maps     Chord    Menu                       rhs
--   ======   ======   =======================     ===
--
--            <M-f>o   &File.&Open               → :e
--                     &File.Open Tab...         → :tabnew
--   <M-f>o            (Open in New Tabpage)     → tabedit {bufname}
--                       ["o" as in "only", not "open"]
--            <M-f>t   &File.Spli&t-Open...      → :sp
--   <M-f>n   <M-f>n   &File.&New                → :enew
--   <M-f>c   <M-f>c   &File.&Close              → :Bdelete
--   <M-f>e   <M-f>e   &File.Clos&e All
--
--            <M-f>s   &File.&Save               → :w
--            <M-f>a   &File.Save &As...         → :sav
--                       [magic missing: the :browser file dialog!]
--   <M-f>l   <M-f>l   &File.Save A&ll           → :wa
--
--            <M-f>d   &File.Split &Diff With...
--            <M-f>b   &File.Split Patched &By...
--
--            <M-f>p   &File.&Print
--
--            <M-f>v   &File.Sa&ve-Exit           → :wqa
--   <M-f>x   <M-f>x   &File.E&xit                → :qa
--   <M-f>q            (Delete All Buffers and Quit)
--                       [Clear Session file]

-- Builtin window menu entries:
--
--   Lazyb    GVim     GVim                        Vim
--    Maps     Chord    Menu                       rhs
--   ======   ======   =======================     ===
--
--   <M-w>n   <M-w>n   &Window.&New              → ^Wn
--   <M-w>s   <M-w>s   &Window.New V-&Split      → ^Ws
--   <M-w>p   <M-w>p   &Window.S&plit            → ^Ws
--            <M-w>l   &Window.Sp&lit To #       → ^W^^
--   <M-w>v   <M-w>v   &Window.Split &Vertically → ^Wv
--            <M-w>x   &Window.Split File E&xplorer
--
--   <M-w>c   <M-w>c   &Window.&Close            → ^Wc
--   <M-w>o   <M-w>o   &Window.Close &Other(s)   → ^Wo
--
--            <M-w>t   &Window.Move &To          → >
--            <M-w>u   &Window.Rotate &Up        → ^WR
--            <M-w>d   &Window.Rotate &Down      → ^Wr
--
--            <M-w>e   &Window.&Equal Size       → ^W=
--            <M-w>m   &Window.&Max Height       → ^W_
--            <M-w>i   &Window.M&in Height       → ^W1_
--            <M-w>w   &Window.Max &Width        → ^W|
--            <M-w>h   &Window.Min Widt&h        → ^W1|

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

function M.CreateDubsVimMappings()
  -- With comments and comment-headers as found in
  --   modify_menu_items.vim

  -- <M-f>c — <C>lose file (and delete buffer)
  --
  -- - Note that an explict :Bdelete on bufhidden=delete file will
  --   error, e.g.:
  --     E516: No buffers were deleted: bdelete 30
  --   - So best to use bufhidden=wipe instead on
  --     those types of buffers.
  --
  -- - CXREF: Bdelete: ~/.kit/nvim/vim-scripts/start/bbye
  -- - CALSO: <LocalLeader>dC | <Alt-f>c — the same.
  map(
    { "n", "i" },
    alt_keys.alt_f .. "c",
    -- HSTRY/2025-03-27: Previously just a simple delete buffer:
    --   "<cmd>Bdelete<CR>",
    function()
      require("util.buffer-delights").close_floats_or_delete_buffer()
    end,
    {
      desc = alt_keys.AltKeyDesc("Close Floatwin(s) or Delete Buffer", "<M-f>c"),
      noremap = true,
      silent = true,
    }
  )

  -- <M-f>e — Cl<e>ar the buffer list
  --
  -- - CXREF: BufOnly: ~/.kit/nvim/vim-scripts/start/bbye
  map({ "n", "i" }, alt_keys.alt_f .. "e", function()
    -- Close floating window, if active, otherwise Neovim complains:
    --   E5601: Cannot close window, only floating window would remain
    local pickers = Snacks.picker.get({})
    if #pickers > 0 then
      Snacks.picker.actions.cancel(pickers[1])
    elseif vim.api.nvim_win_get_config(0).relative ~= "" then
      -- This would cause Snacks complaint re: WinEnter autocmd failure,
      -- albeit error says 'name' invalid but no such variable in any
      -- function indicated by the stacktrace (so I didn't figure it out,
      -- I just avoided it by adding the prior 'if' branch).
      local force = false
      vim.api.nvim_win_close(0, force)
    end
    -- If more than one window, logs message:
    --   Already only one window
    if vim.fn.winnr("$") > 1 then
      vim.cmd("only")
    end
    vim.cmd("enew")
    vim.cmd("BufOnly")
  end, { desc = alt_keys.AltKeyDesc("Delete All Buffers", "<M-f>e"), noremap = true, silent = true })

  -- <M-f>l — Save A<l>l
  map(
    { "n", "i" },
    alt_keys.alt_f .. "l",
    "<cmd>:wa<CR>",
    { desc = alt_keys.AltKeyDesc("Save All Buffers", "<M-f>l"), noremap = true, silent = true }
  )
end

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

-- Map some common, familiar Linux/Windows <Alt-F> menu commands you'd
-- find in most apps, incl. <Alt-f>n, <Alt-f>x, and <Alt-f>q, and other
-- <Alt-f> file-related maps.
function M.RecreateBuiltinMenuMappings_File()
  -- <M-f>n — <N>ew File
  --
  -- USAGE: Use global to choose enew behavior.
  -- - Author almost never creates a new file that they later save.
  -- - I generally use new files just to empty out the window.
  --   - So hide new buffers when they're unloaded from a window,
  --     so you don't end up with a bunch on [No Name] buffers.
  --   - This also forces you to deal with the buffer if you made
  --     changes to it (e.g., so you give it a path and save it,
  --     or do something else with your changes).
  -- - Note that we use :Bdelete to also cleanup buffers.
  --   - But Bdelete causes an error if bufhidden=delete, e.g.:
  --       E516: No buffers were deleted: bdelete 30
  --     Fortunately it works find if we use bufhidde=wipe.
  if vim.g.dubs_appearance_enew_no_wipe then
    map(
      { "n", "i" },
      alt_keys.alt_f .. "n",
      "<cmd>:enew<CR>",
      { desc = alt_keys.AltKeyDesc("New Buffer", "<M-f>n"), noremap = true, silent = true }
    )
  else
    map({ "n", "i" }, alt_keys.alt_f .. "n", function()
      vim.cmd("enew")
      vim.cmd("setlocal bufhidden=wipe")
    end, { desc = alt_keys.AltKeyDesc("New Buffer", "<M-f>n"), noremap = true, silent = true })
  end

  -- <M-f>a — Save <A>s...
  --
  -- ISOFF: This works in gVim and MacVim, which brings up a save dialog,
  -- but in Neovide, it emits as error:
  --     E471: Argument required
  --
  --  map({ "n", "i" }, alt_keys.alt_f .. "a", "<cmd>:bro sav<CR>",
  --    { desc = "Save As...", noremap = true, silent = true })

  -- <M-f>x — E<x>it
  map(
    { "n", "i" },
    alt_keys.alt_f .. "x",
    "<cmd>:qa<CR>",
    { desc = alt_keys.AltKeyDesc("Quit All", "<M-f>x"), noremap = true, silent = true }
  )

  -- <M-f>q — <Q>uit Neovim
  --
  -- Make up a combo close-quit (so Session.vim obliterated, per
  --   s:ManageSessionFile()):
  -- ~/.kit/nvim/landonb/dubs_appearance/plugin/session_file_boss.vim
  -- - (Or if that plugin not running, it still closes all files so
  --    that reopening Session on next Neovim instance opens no files.)
  map({ "n", "i" }, alt_keys.alt_f .. "q", function()
    vim.cmd("only")
    vim.cmd("enew")
    vim.cmd("BufOnly")
    vim.cmd("qa")
  end, {
    desc = alt_keys.AltKeyDesc("Delete All Buffers and Quit", "<M-f>q"),
    noremap = true,
    silent = true,
  })

  -- <M-f>o — <O>pen buffer in new tabpage
  --
  -- Sorta like <C-w>o "only", but without closing windows.
  --
  -- CALSO: <LocalLeader>dT (same feature)
  map(
    { "n", "i" },
    alt_keys.alt_f .. "o",
    "<cmd>exec 'tabedit ' .. expand('%')<CR>",
    { desc = alt_keys.AltKeyDesc("Open in New Tabpage", "<M-f>o"), noremap = true, silent = true }
  )
end

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

-- SAVVY: Mimic some <C-w>{char} commands at <M-w>{char} in normal and insert modes.
-- - Not any more convenient in normal mode, but obviates need to <Esc> or <C-o>
--   when in insert mode (where <C-w> in insert mode is delete back word).
function M.RecreateBuiltinMenuMappings_Window()
  -- <M-w>n — New horizo<n>tal split window
  --
  -- - I never use this map, I usually horizontal-split
  --   and open the same buffer. Or I vertical-split to
  --   open a new buffer.
  --
  -- ISOFF/2025-03-13: See <M-w>S instead.
  --
  --   map({ "n", "i" }, alt_keys.alt_w .. "n", function()
  --     vim.cmd("wincmd n")
  --   end, {
  --     desc = alt_keys.AltKeyDesc("New Buffer in New H Split", "<M-w>n"),
  --     noremap = true,
  --     silent = true,
  --   })

  -- <M-w>s — <S>plit [horizontally]
  map({ "n", "i" }, alt_keys.alt_w .. "s", function()
    vim.cmd("wincmd s")
  end, {
    desc = alt_keys.AltKeyDesc("Split Window Horizontal", "<M-w>p"),
    noremap = true,
    silent = true,
  })
  -- -- <M-w>p — S<p>lit [horizontally]
  -- -- LATER: Remove this eventually — This is old binding
  -- --        from before I changed <M-w>s to do this (and
  -- --        moved what was <M-w>s to <M-w>V).
  -- map({ "n", "i" }, alt_keys.alt_w .. "p", function()
  --   vim.cmd("wincmd s")
  -- end, {
  --   desc = alt_keys.AltKeyDesc("Split Window Horizontal", "<M-w>p"),
  --   noremap = true,
  --   silent = true,
  -- })

  -- <M-w>v — Split <V>ertically
  map(
    { "n", "i" },
    alt_keys.alt_w .. "v",
    function()
      vim.cmd("wincmd v")
    end,
    { desc = alt_keys.AltKeyDesc("Split Window Vertical", "<M-w>v"), noremap = true, silent = true }
  )

  -- <M-w>S — Open-new-buffer-in-new-horizontal-<S>plit
  --
  -- Splits Horizontally and loads empty buffer.
  map(
    { "n", "i" },
    alt_keys.alt_w .. "S",
    -- Like :wincmd n, but sets bufhidden=wipe.
    function()
      vim.cmd("wincmd s")
      -- If you uncomment the :wincmd p calls, opens new buffer
      -- above current window, and returns focus to old window.
      --  vim.cmd("wincmd p")
      vim.cmd("enew")
      vim.cmd("setlocal bufhidden=wipe")
      --  vim.cmd("wincmd p")
    end,
    { desc = alt_keys.AltKeyDesc("Vertical Split :enew", "<M-w>s"), noremap = true, silent = true }
  )

  -- <M-w>V — Open-new-buffer-in-new-<V>ertical-split
  --
  -- Splits Vertically and loads empty buffer.
  map(
    { "n", "i" },
    alt_keys.alt_w .. "V",
    function()
      vim.cmd("wincmd v")
      -- If you uncomment the :wincmd p calls, opens new buffer
      -- left of current window, and returns focus to old window.
      --  vim.cmd("wincmd p")
      vim.cmd("enew")
      vim.cmd("setlocal bufhidden=wipe")
      --  vim.cmd("wincmd p")
    end,
    { desc = alt_keys.AltKeyDesc("Vertical Split :enew", "<M-w>s"), noremap = true, silent = true }
  )

  -- <M-w>c — <C>lose window
  --
  -- - Close window is also mapped by mswin.vim to <C-F4>
  --   - Except that does nothing when author tries it
  --     in MacVim (but the map exists).
  --   /Applications/MacVim.app/Contents/Resources/vim/runtime/mswin.vim
  map({ "n", "i" }, alt_keys.alt_w .. "c", function()
    -- Silent, or trying to close last window evokes E444 error scolding.
    vim.cmd("silent! wincmd c")
  end, { desc = alt_keys.AltKeyDesc("Close Window", "<M-w>c"), noremap = true, silent = true })

  -- <M-w>o — Close <o>ther window(s) (aka 'make <o>nly window')
  map({ "n", "i" }, alt_keys.alt_w .. "o", function()
    vim.cmd("wincmd o")
  end, {
    desc = alt_keys.AltKeyDesc("Only Window (Close Others)", "<M-w>o"),
    noremap = true,
    silent = true,
  })

  -- <M-w>p — |CTRL-W_p|
  --
  -- "Go to previous (last accessed) window" aka MRU window.
  --
  -- (Probably won't use this, but I appreciate the parity.)
  --
  -- CALSO: <Ctrl-Shift-\> aka <Ctrl-|>
  map(
    { "n", "i" },
    alt_keys.alt_w .. "p",
    [[<cmd>exec "normal! \<C-w>p"<CR>]],
    { desc = "Go to Previous Window" }
  )
end

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

-- Some thougs re: builtin menu mappings found in:
--   vim/runtime/menu.vim
--
-- &File.xxx [I use some of these shortcuts frequently; will recreate]
-- &Edit.xxx [lots of items; none I care about]
-- &Tools.xxx [don't think I've ever used]
-- &Syntax.xxx [never used]
-- &Buffers.xxx [can't say I've used; lists all buffers so you can
--               select one to open; see Dubs |__| command for that,
--               or :Telescope buffers, etc.]
-- &Window.xxx [I use some of these shortcuts frequently; will remap]
-- &Plugin.xxx [if I hadn't just looked, wouldn't have known this existed]
-- &Help.xxx [I don't even check the version dialog this way, I use :ver]

function M.RecreateGVimMappings()
  M.RecreateBuiltinMenuMappings_File()
  M.RecreateBuiltinMenuMappings_Window()
end

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

function M.MimicUsefulGuiMenuShortcutKeyMappings()
  M.CreateDubsVimMappings()
  M.RecreateGVimMappings()
end

-- FIXME: Call setup() from caller instead?
M.MimicUsefulGuiMenuShortcutKeyMappings()

return M
