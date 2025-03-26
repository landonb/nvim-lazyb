-- vim:tw=0:ts=2:sw=2:et:ai:ft=lua
-- Author: Landon Bouma <https://tallybark.com/>
-- Project: https://github.com/landonb/nvim-lazyb#🧸

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

-- SAVVY: Skipped, at least for now:
--   - ✓ all language plugins (e.g., ansible-vim)
--   - ✓ dubs_appearance (ported what we need)
--   - ? dubs_ftype_mess (ongoing; I'll need to pull some/most of this)
--   - ✓ dubs_mescaline (replaced by lualine)
--   - ✓ dubs_quickfix_wrap (nice qf window toggle)
--   - ✓ dubs_style_guard (added just the ColorColumn toggle)
--   - ✓ dubs_toggle_textwrap (ported to keymaps.lua)
--   - ✓ vim-mkspell-when-stale (builds spell/en.utf-8.add.spl)
--   - ✗ vim-netrw-cfg-split-explorer (don't need)
--   - ? vim-netrw-link-resolve
--   - ✗ vim-ovm-easyescape-kj-jk (leaving off, at least for now)
--   - ? vim-select-mode-stopped-down
--   - L vim-surround
--   - L vim-unimpaired
--   - depoxy-vim...
--   - embrace-vim...

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

local alt_keys = require("util.alt2meta-keys")

local wk = require("which-key")

return {
  --
  -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

  {
    dir = "~/.kit/nvim/landonb/vim-select-mode-stopped-down",
    -- PFORM: This plugin feels performant in Neovim, unlike in
    -- Vim, where I recall it feeling not as quick-footed. Phew!
    -- - So we'll enable it always, rather than making opt-in.
    event = "VeryLazy",

    config = function()
      wk.add({
        mode = { "n", "i", "v" },
        icon = "󰩭",
        { "<C-S-Left>", desc = "Extend Selection By Word Reverse" },
        { "<C-S-Right>", desc = "Extend Selection By Word Forward" },
      })
    end,
  },

  -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

  {
    dir = "~/.kit/nvim/landonb/vim-title-bar-time-of-day",
    lazy = false,

    config = function()
      vim.fn["embrace#titlebar#Setup"]({
        titlebar_disable = false,
        clock_rate = 2500,
      })
    end,
  },

  -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

  -- USAGE: :Bdelete, for <Alt-f>c and <LocalLeader>dC
  {
    dir = "~/.kit/nvim/vim-scripts/start/bbye",
    event = "VeryLazy",
  },

  -- USAGE: :BufOnly, for <Alt-f>e, <Alt-f>q and <LocalLeader>dQ
  {
    dir = "~/.kit/nvim/vim-scripts/start/BufOnly.vim",
    event = "VeryLazy",
  },

  -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

  -- USAGE: See edit-juice <M-!>/<T-!> maps.
  {
    dir = "~/.kit/nvim/landonb/vim-classic-taglist",
    keys = {
      -- MAYBE: Find a more buried key sequence (for this rarely/never used command).
      { mode = { "n", "i" }, "<M-!>", "<cmd>TlistToggle<CR>", desc = "Toggle vim-classic-taglist" },
      { mode = { "n", "i" }, "⁄", "<cmd>TlistToggle<CR>", desc = "Toggle vim-classic-taglist" },
    },
  },

  -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

  -- USAGE: <LocalLeader>dh and <LocalLeader>dH
  -- - Though really you can easily live without this.
  -- - Note that dubs_html_entities temporarily disables Noice.
  --   Otherwise <LocalLeader>dH prompts for a character, but it
  --   won't appear to be prompting because Noice. But then you
  --   type a character, and its HTML rep. will be inserted.
  {
    dir = "~/.kit/nvim/landonb/dubs_html_entities",
    event = "VeryLazy",
    config = function()
      wk.add({
        mode = { "n" },
        icon = "",
        { "<LocalLeader>dh" },
        { "<LocalLeader>dH" },
      })
    end,
    keys = {
      -- ALTLY:
      -- { mode = "n", "<LocalLeader>dh", "<Plug>DubsHtmlEntities_ToggleLookup", silent = true },
      {
        -- Meh, works from Insert mode, but don't need it.
        --   mode = { "n", "i" },
        mode = { "n" },
        "<LocalLeader>dh",
        [[<cmd>exec "normal \<Plug>DubsHtmlEntities_ToggleLookup"<CR>]],
        silent = true,
        desc = "HTML Entities Lookup",
      },
      -- The following maps don't work.
      -- - If you :Noice disable, you'll see the message:
      --     "Sorry, the HTML entity for '^[' was not found!"
      --   But if :Noice is enabled — even though the plugin temporarilty
      --   disables Noice — you won't see any message.
      --     {
      --       mode = { "n", "i" },
      --       "<LocalLeader>dH",
      --       [[<cmd>exec "normal \<Plug>DubsHtmlEntities_QuickLookup"<CR>]],
      --       --silent = true,
      --       desc = "HTML Entities Prompt",
      --     },
      -- - You'll see this message if you disable Noice:
      --     HTML Entity Translator >> Please enter a character:
      --     Sorry, the HTML entity for '^[' was not found!
      --   for this imap, with an rhs that works from nvim-depoxy
      --   (which doesn't use Noice, among other things):
      --     {
      --       mode = "i",
      --       "<LocalLeader>dH",
      --       "<C-O><Plug>DubsHtmlEntities_QuickLookup<Esc>",
      --       silent = true,
      --     },
      {
        mode = "n",
        "<LocalLeader>dH",
        "<Plug>DubsHtmlEntities_QuickLookup",
        silent = true,
        desc = "HTML Entities Prompt",
      },
    },
  },

  -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

  -- FIXME: ONGNG: Keep pulling feature from dubs_ftype_mess.
  {
    dir = "~/.kit/nvim/landonb/dubs_ftype_mess",
    lazy = true,
  },

  -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

  {
    dir = "~/.kit/nvim/landonb/dubs_quickfix_wrap",
    -- Use VeryLazy and not lazy=false so the which-key icons load.
    event = "VeryLazy",
    config = function()
      wk.add({
        { mode = { "n", "i" }, alt_keys.lookup("#"), icon = "󱂬" },
        { mode = { "n" }, "<LocalLeader>SQ", icon = "󰬲" },
      })
    end,
    keys = {
      {
        mode = { "n", "i" },
        -- BNDNG: <Shift-Alt-3> aka <Shift-Alt-#> aka <M-#> aka <‹>
        alt_keys.lookup("#"),
        [[<cmd>QFix(0)<CR>]],
        silent = true,
        desc = alt_keys.AltKeyDesc("Show/Hide Quickfix", "M-#"),
      },
      -- BWARE: This is not the best multi-file search-replace tool.
      -- - You might want to try grug-far instead,
      --   in LazyVim at <Leader>sr
      -- - Or even `sed` from the terminal.
      -- BWARE: This opens each QF result in a window and then acts
      -- on every buffer. Which is both klunky and slow.
      {
        mode = { "n" },
        "<LocalLeader>SQ",
        [["sy:call QuickfixSubstituteAll("<C-r>s", "")<Left><Left>]],
        silent = true,
        desc = "Buffer and Qf Substitute All",
      },
      -- COPYD: Inspired by:
      -- https://github.com/ecosse3/nvim/blob/master/lua/config/keymappings.lua

      -- ISOFF: Neovim 0.11 adds [q and ]q prev/next (inspired by vim-fugitive).
      -- - Also [Q ]Q first/last quickfix item.
      --
      -- -- Navigate Quickfix results
      -- {
      --   mode = { "n", "i" },
      --   "<LocalLeader>,",
      --   ":cp<CR>",
      --   silent = true,
      --   desc = "Quickfix open prev",
      -- },
      -- {
      --   mode = { "n", "i" },
      --   "<LocalLeader>.",
      --   ":cn<CR>",
      --   silent = true,
      --   desc = "Quickfix open next",
      -- },

      -- Toggle quicklist
      -- - CALSO: <Shift-Alt-3> :QFix(0)
      {
        mode = "n",
        "<leader>uq",
        -- "<cmd>lua require('utils').toggle_quicklist()<CR>",
        -- - COPYD:
        --   https://github.com/ecosse3/nvim/blob/master/lua/utils/init.lua
        -- M.toggle_quicklist = function()
        function()
          if vim.fn.empty(vim.fn.filter(vim.fn.getwininfo(), "v:val.quickfix")) == 1 then
            vim.cmd("copen")
          else
            vim.cmd("cclose")
          end
        end,
        silent = true,
        desc = "Toggle Quickfix",
      },
    },
  },

  -- Opens item under cursor in the previously focused window when you
  -- <CR> or <2-LeftMouse> (double-click) on Quickfix item (among lots
  -- of other features, but that's the one I care about).
  -- - Default LazyVim behavior seems to use previously focused window,
  --   so QFEnter may be unnecessary.
  {
    dir = "~/.kit/nvim/landonb/QFEnter",
    -- ISOFF/2025-03-09: Probably don't need.
    lazy = true,
  },

  -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

  -- In Neovim &modeline is on by default; in Vim, it's off.
  -- - ✓ Works: The &modeline feature parses &redrawtime (rdt), which
  --     is probably rarely used in a modeline, but which affects syntax
  --     parsing. It's something the author specifies in their larger
  --     *.rst files to ensure syntax highlighting works (even if it
  --     takes an extra second or two to open a ~10k line rst file; but
  --     I'm addicted to my vim-reST-highdefs plugin that adds a lot of
  --     value to my reST files).
  -- - ✓ Basic: AFAIK, LazyVim doesn't add additional modeline behavior,
  --     but rather just lets Neovim do what it does by default.
  -- - ✗ Limited: The built-in modeline parser only checks the first and
  --     final 5 lines of a file.
  --     - The dubs_style_guard plugin lets you choose choose separate values
  --       for how many head lines to check, and how many tail lines to check.
  --     - The author sneaks a modeline into their Unicode lookup where GitHub
  --       won't see it (six lines from the bottom!) to trick GH into rendering
  --       the document as txt, and so that (Neo)vim renders it as reStructured-
  --       Text (because it's not valid reST, but looks good in an editor, and
  --       doesn't look good rendered as HTML).
  --       - REFER: https://github.com/DepoXy/emoji-lookup#🙄
  -- - ✗ Bonuses: The dubs_style_guard adds a few style toggles, so you can
  --     cycle through different whitespace styles (useful for a new buffer
  --     without a modeline or an .editorconfig file, etc., though admittedly
  --     not a feature I ever use anymore); and so you can cycle through a few
  --     different ColorColumn highlights (admittedly a feature I used to rely
  --     on, but now with wider monitors and auto-formatting tools, not a song
  --     I need on my stranded-on-a-desert-island playlist).
  --
  -- TL_DR: I don't care too much about this plugin, except for that one modeline
  -- in the emoji-lookup... though if I remove the ft=rst from the modeline and
  -- leave the rdt=19999, then I shouldn't need this plugin, should I...
  -- - ISOFF/2025-03-10: Let's try without the modeline feature, but with the
  --   ColorColumn toggle (though, as noted above, not something I really care
  --   all that much about anymore...).
  {
    dir = "~/.kit/nvim/landonb/dubs_style_guard",
    -- lazy = true,
    event = "VeryLazy",

    init = function()
      vim.g.loaded_dubs_style_guard_plugin = true
      -- USAGE: Set false to enable the modeline feature, too.
      -- - When true, enables only the ColorColumn toggles.
      vim.g.dubs_style_guard_col_col_only = true
    end,

    config = function()
      -- Not that we can't have both, but no need for the built-in one.
      if not vim.g.dubs_style_guard_col_col_only then
        vim.o.modeline = false

        require("which-key").add({
          mode = { "n", "i" },
          { "<LocalLeader>de", desc = "Cycle through Style Profiles" },
          { "<LocalLeader>dE", desc = "Reset Style (Check modeline, etc.)" },
        })
      else
        -- MAYBE: Adjust the single-column ColorColumn highlight, which
        -- is barely noticeable in the catppuccin-mocha colorscheme.
        local key_sequence_cycle = "<LocalLeader>dr"
        local key_sequence_reset = "<LocalLeader>dR"
        local default_line_style = "highlight_violators"
        -- stylua: ignore
        vim.fn["embrace#col_col_cycle#Enable"](
          key_sequence_cycle,
          key_sequence_reset,
          default_line_style
        )
      end

      require("which-key").add({
        { "<LocalLeader>dr", desc = "Cycle through ColorColumn styles", icon = "󰖶" },
        { "<LocalLeader>dR", desc = "Reset ColorColumn style", icon = "󰖶" },
      })
    end,
  },

  -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

  -- Includes, e.g., `imap <Up> gk` so <Up> is visual lines, not logical.
  -- - ISOFF: See our slightly-improved Lua implementations:
  --   ~/.kit/nvim/landonb/nvim-lazyb/lua/config/keymaps.lua
  --
  --   {
  --     dir = "~/.kit/nvim/landonb/dubs_toggle_textwrap",
  --     lazy = true,
  --
  --     config = function()
  --       require("which-key").add({
  --         -- CALSO: LazyVim binds simialr to <Leader>uw
  --         { "<LocalLeader>dw", desc = "Toggle Text Wrap" },
  --       })
  --     end,
  --   },

  -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

  {
    dir = "~/.kit/nvim/embrace-vim/start/vim-async-map",
    -- MAYBE/2025-03-09: I might enable this for improved Insert mode '3t'
    -- abbrev, and for Insert mode 'gf', but that's pretty low priority.
    lazy = true,
  },

  {
    dir = "~/.kit/nvim/landonb/vim-ovm-easyescape-kj-jk",
    lazy = true,
    dependencies = {
      { dir = "~/.kit/nvim/embrace-vim/start/vim-async-map" },
    },
  },

  -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

  -- Meh, this plugin is completely unnecessary. But works in Noice...
  {
    dir = "~/.kit/nvim/embrace-vim/start/vim-better-file-changed-prompt",
    -- ISOFF/2025-03-09: Because Noice, probably don't want this.
    lazy = true,
  },

  -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

  -- Much of vim-buffer-delights has been ported to nvim-lazyb Lua.
  -- - Just a few pieces remain...

  -- SAVVY: Not ported: CreateLogWindow, AppendScratch, etc.,
  -- which was a debugging construct I've used, but probably-
  -- mostly unnecessary (it lets you live-log to a scratch
  -- buffer window).

  -- MAYBE: Add async-map imap gF and wire that kooky gf
  --   nnoremap gF :call g:embrace#windows#open_file_adjacent()<CR>
  --   vnoremap gF y:call g:embrace#windows#open_file_adjacent('<C-r>"')<CR>
  --   nnoremap gf gF

  {
    dir = "~/.kit/nvim/embrace-vim/start/vim-buffer-delights",
    event = "VeryLazy",
    init = function()
      vim.g.vim_buffer_delights_disable = true
    end,
    config = function()
      -- FIXME/FTREQ: Port scratch.vim to Lua.
      -- - For now, a shim file to `source` the Vimscript.
      require("util.buffer-delights.scratch-buffer")
    end,
    keys = {
      -- ALTLY: See also LazyVim features:
      -- - <Leader>. — Toggle Scratch Buffer [in floating window]
      -- - <Leader>S — Select Scratch Buffer
      {
        mode = { "n", "i" },
        "<LocalLeader>dN",
        "<cmd>call g:embrace#scratch#CreateScratchWindow()<CR>",
        noremap = true,
        silent = true,
        desc = "Create Scratch Window",
      },
      {
        mode = { "n", "i" },
        "<LocalLeader>dG",
        function()
          require("util.windows").close_windows_by_ft({ filetype = "help" })
        end,
        noremap = true,
        silent = true,
        desc = "Close Help Window",
      },
    },
  },

  -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

  -- ISOFF/2025-03-09: Neovide doesn't provide window resize fcn'ality
  -- like gVim or MacVim provides.
  --
  --   {
  --     dir = "~/.kit/nvim/embrace-vim/start/vim-fullscreen-toggle",
  --     lazy = true,
  --   },

  -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

  -- Enable |gf| to resolve Bash shell variables with ${alternative:-values}.
  {
    dir = "~/.kit/nvim/embrace-vim/start/vim-goto-file-sh",
    event = "VeryLazy",
  },

  -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

  {
    dir = "~/.kit/nvim/landonb/vim-mkspell-when-stale",
    event = "VeryLazy",
  },

  -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

  -- USAGE: See (private) \p/\P and \<M-p>/\<M-P> maps.
  -- Adds <Esc> to :netrw, which is normal-buffer- and vim-buffer-ring-aware MRU.
  -- - Sets g:netrw_list_hide and g:netrw_banner.
  -- - Avoids opening :netrw in window showing special buffer.
  {
    dir = "~/.kit/nvim/embrace-vim/start/vim-netrw-explore-map",
    event = "VeryLazy",
  },

  -- This plugin sets literally 4 netrw options, but we only
  -- use netrw for the \p/\P menus that vim-netrw-explore-map
  -- handles (and that plugin sets the options it needs).
  --
  --   {
  --     dir = "~/.kit/nvim/landonb/vim-netrw-cfg-split-explorer",
  --     lazy = true,
  --   },

  -- LATER: Run without this and see if you need it.
  -- - ATEST: Interestingly, I opened this project's .gitignore
  --   file, and nvim opened the symlink target, .git/info/exclude.
  --   I then opened the target of .git/info/exclude,
  --     ~/.depoxy/ambers/home/.kit/nvim/landonb/nvim-lazyb/_git/info/exclude
  --   and nvim focused the .git/info/exclude buffer.
  --   - The point of this plugin is to use the canonical (realpath)
  --     path for the buffer, to avoid swapfile warnings/issues.
  --     ... but I bet either Neovim or LazyVim is smart enough
  --     to avoid this problem.
  --   - Note this plugin only affects files opened from netrw,
  --     which means would only matter to files opened from \p/\P
  --     maps (vim-netrw-explore-map).
  -- - DUNNO: I thought LazyVim solved this, but I opened a symlink
  --   and its canonoical path was not followed. Then I opened the
  --   canonical path, and no warning. Edited the symlink, saved,
  --   but not reflected in the canonical buffer until :edit or
  --   BufEnter (e.g., <Ctrl-^> once <Ctrl-^> twice).
  {
    dir = "~/.kit/nvim/landonb/vim-netrw-link-resolve",
    lazy = true,
  },

  -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

  {
    dir = "~/.kit/nvim/embrace-vim/start/vim-webopen",
    event = "VeryLazy",
    config = function()
      -- If you'd like each URL to open in a new browser tab in an
      -- existing window instead of always opening in a new window,
      -- set g:vim_webopen_use_tab nonzero:
      --
      --   let g:vim_webopen_use_tab = 1
      --
      --
      -- If you'd like Chrome to use most recent user profile, and not 'Default',
      -- set g:vim_webopen_mru_profile nonzero:
      --
      --   let g:vim_webopen_mru_profile = 1
      vim.g.vim_webopen_maps = {
        open = {
          nmap = { "<LocalLeader>T", "gW" },
          imap = "<LocalLeader>T",
          vmap = "<LocalLeader>T",
        },
        define = "<LocalLeader>D",
        search = "<LocalLeader>W",
        incognito = { nmap = "g!" },
        github = "<LocalLeader>og",
      }
      -- CXREF:
      -- ~/.kit/nvim/embrace-vim/start/vim-webopen/autoload/embrace/webopen.vim
      vim.fn["embrace#webopen#CreateMaps"]()

      wk.add({
        mode = { "n", "i", "v" },
        icon = "󰖟",
        { "<LocalLeader>T" },
        { mode = { "n" }, "gW" },
        { "<LocalLeader>D" },
        { "<LocalLeader>W" },
        { mode = { "n" }, "g!" },
        { "<LocalLeader>og" },
      })
    end,
  },

  -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

  -- ISOFF: I've ported vim-depoxy to LazyVim Lua config and specs
  -- (well, in some places I just :source files from vim-depoxy, so you
  -- can't get rid of vim-depoxy, at least not yet; but we don't need to
  -- register it with lazy.nvim, and its repo is managed by the OMR config).
  --
  --   {
  --     dir = "~/.kit/nvim/DepoXy/start/vim-depoxy",
  --     lazy = true,
  --   },

  -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

  -- REFER: See |editorconfig| — Neovim loads .editorconfig files from current
  -- and parent directories after running ftplugins/ and FileType autocommands.
  --
  -- - You can disable via: vim.g.editorconfig = false
  --   - Or per-buffer via: vim.b.editorconfig = false
  --
  -- - See |editorconfig-properties| for list of supported properties.
  --
  --   {
  --     dir = "~/.kit/nvim/editorconfig/start/editorconfig-vim",
  --     event = "VeryLazy",
  --   },

  -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

  -- https://github.com/glacambre/firenvim/
  -- https://chromewebstore.google.com/detail/firenvim/egpjdkipkomnmjhjmdamaniclmdlobbo?pli=1
  -- https://addons.mozilla.org/en-US/firefox/addon/firenvim/
  {
    -- "glacambre/firenvim",
    dir = "~/.kit/nvim/glacambre/firenvim",
    lazy = true,

    build = ":call firenvim#install(0)",
  },

  -- ***

  {
    dir = "~/.kit/nvim/jamessan/start/vim-gnupg",
    lazy = true,
  },

  -- ***

  {
    dir = "~/.kit/nvim/vim-scripts/start/ZoomWin",
    lazy = true,
  },

  -- ***

  -- https://github.com/tpope/vim-abolish
  {
    dir = "~/.kit/nvim/tpope/start/vim-abolish",
    lazy = true,
  },

  -- https://github.com/tpope/vim-fugitive
  {
    dir = "~/.kit/nvim/tpope/start/vim-fugitive",
    -- Load on VeryLazy so which-key icons are applied
    -- (vs. waiting to load when keys{} command used).
    event = "VeryLazy",

    init = function()
      -- TRACK/2025-03-24: Now inhibiting default maps.
      -- - Keep an eye out for anything you use that's missing.
      vim.g.fugitive_no_maps = true
    end,

    config = function()
      -- FIXME: Localize this file.

      -- Load autoload# fcn: git_fugitive_window_cleanup#close_git_windows()
      -- - CXREF:
      --   ~/.kit/nvim/DepoXy/start/vim-depoxy/autoload/git_fugitive_window_cleanup.vim
      pcall(function()
        vim.cmd(
          "source "
            .. vim.env.HOME
            .. "/.kit/nvim/DepoXy/start/vim-depoxy/autoload/git_fugitive_window_cleanup.vim"
        )
      end)

      -- USYNC: Add icons to keys{}, defined after.
      wk.add({
        mode = { "n" },
        { "<Leader>g" .. alt_keys.lookup("c"), icon = "󰅖" },
        { "<Leader>g" .. alt_keys.lookup("b"), icon = "" },
      })
    end,

    keys = {
      {
        -- ASIDE: In nvim-depoxy at <Leader>fc |\fc| (mode = { "n", "i" }).
        mode = { "n" },
        "<Leader>g" .. alt_keys.lookup("c"),
        function()
          vim.fn["git_fugitive_window_cleanup#close_git_windows"]()
        end,
        noremap = true,
        silent = true,
        -- desc = "Close Fugitive Windows",
        desc = alt_keys.AltKeyDesc("Close Fugitive Windows", "M-c"),
      },
      {
        -- ASIDE: In nvim-depoxy at <Leader>fb |\fb| (mode = { "n", "i" }).
        mode = { "n" },
        -- BNDNG: <Leader>g<M-b> aka <Leader>g∫
        "<Leader>g" .. alt_keys.lookup("b"),
        "<cmd>Git blame<CR>",
        noremap = true,
        silent = true,
        desc = alt_keys.AltKeyDesc("Fugitive Blame", "M-b"),
      },
    },

    -- COPYD: https://github.com/NormalNvim/NormalNvim/blob/main/lua/plugins/4-dev.lua#L108-L145
    --
    --  Git fugitive mergetool + [git commands]
    --  https://github.com/lewis6991/gitsigns.nvim
    --  PR needed: Setup keymappings to move quickly when using this feature.
    --
    --  We only want this plugin to use it as mergetool like "git mergetool".
    --  To enable this feature, add this  to your global .gitconfig:
    --
    --  [mergetool "fugitive"]
    --  	cmd = nvim -c \"Gvdiffsplit!\" \"$MERGED\"
    --  [merge]
    --  	tool = fugitive
    --  [mergetool]
    --  	keepBackup = false
    enabled = vim.fn.executable("git") == 1,
    -- SPIKE/2025-03-24: Is it though?
    dependencies = { "tpope/vim-rhubarb" },
    cmd = {
      "Gvdiffsplit",
      "Gdiffsplit",
      "Gedit",
      "Gsplit",
      "Gread",
      "Gwrite",
      "Ggrep",
      "GMove",
      "GRename",
      "GDelete",
      "GRemove",
      "GBrowse",
      "Git",
      "Gstatus",
    },
  },

  -- https://github.com/tpope/vim-repeat
  {
    dir = "~/.kit/nvim/tpope/start/vim-repeat",
    lazy = true,
  },

  -- https://github.com/tpope/vim-surround
  {
    dir = "~/.kit/nvim/landonb/vim-surround",
    lazy = true,

    dependencies = {
      { dir = "~/.kit/nvim/tpope/start/vim-repeat" },
    },
  },

  -- https://github.com/tpope/vim-unimpaired
  {
    dir = "~/.kit/nvim/landonb/vim-unimpaired",
    lazy = true,

    dependencies = {
      { dir = "~/.kit/nvim/tpope/start/vim-repeat" },
    },
  },
}
