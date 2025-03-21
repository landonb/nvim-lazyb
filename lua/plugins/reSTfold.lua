-- vim:tw=0:ts=2:sw=2:et:ai:ft=lua
-- Author: Landon Bouma <https://tallybark.com/>
-- Project: https://github.com/landonb/nvim-lazyb#🧸

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

local alt_keys = require("util.alt2meta-keys")

return {
  {
    dir = "~/.kit/nvim/landonb/vim-ovm-seven-of-spines",
    event = "VeryLazy",

    -- CXREF:
    -- ~/.kit/nvim/landonb/vim-ovm-seven-of-spines/plugin/vim_ovm_seven_of_spines.vim
    config = function()
      local wk = require("which-key")
      wk.add({
        mode = { "n", "i" },
        { "<C-->", desc = "Write Seven Dashes" },
      })
    end,
  },

  {
    dir = "~/.kit/nvim/landonb/vim-reSTfold",
    event = "VeryLazy",

    init = function()
      -- FIXME/2025-02-05 11:19: Will this improve performance?
      -- - You'll see 2 pages of `syn` items vs. over a dozen!
      --   - `syn` output fills 48 pages!!! (~70 line height).
      -- - Or maybe not, I had already been restricting it to
      --   just 3 items = ['bash', 'javascript', 'python']
      --     ~/.kit/nvim/landonb/dubs_ftype_mess/plugin/dubs_preloads.vim
      --   - `syn` output fills 8 pages (~70 line height).
      -- - When vim.g.rst_syntax_code_list is empty table:
      --   - `syn` output fills 3 pages (~70 line height).
      --
      -- let g:rst_syntax_code_list = {
      --     \ 'vim': ['vim'],
      --     \ 'java': ['java'],
      --     \ 'cpp': ['cpp', 'c++'],
      --     \ 'lisp': ['lisp'],
      --     \ 'php': ['php'],
      --     \ 'python': ['python'],
      --     \ 'perl': ['perl'],
      --     \ 'sh': ['sh'],
      --     \ }
      -- CXREF: /opt/homebrew/Cellar/neovim/0.10.3/share/nvim/runtime/syntax/rst.vim
      vim.g.rst_syntax_code_list = {}

      -- ***
      --
      -- USYNC: Config copied form vim-depoxy:
      -- ~/.kit/nvim/DepoXy/start/vim-depoxy/plugin/beautifold-config.vim

      -- My convention is that content starts one blank after the title,
      -- and a blank follows content, so that's a minimum 3 lines of content
      -- (which allows for a 5-line design fold, e.g., one `..` comment
      -- immediately following title header, then a blank line).
      -- Defaults: 2
      vim.g.restfold_weldable_min_content_lines = 3

      -- Configure reSTfold to use whitespace padding after short fold titles.
      --   https://github.com/landonb/vim-reSTfold
      -- Open a reST file and press <F5> to generate folds using this option.
      --
      vim.g.restfold_min_title_width = 93

      -- 2021-02-20: I have some files that use 8 PREFIXES, some with leading
      -- emoji, and some with 3 leading spaces, and don't always conform to
      -- the typical (for me) `FIXED/YYYY-MM-DD: reSTfold topic title` format.
      -- E.g., sometimes it's `DONT_FIX/YYYY-MM-DD: ...`.
      vim.g.restfold_weldable_max_lead_spaces = 3

      -- 2021-03-11: Disable Unicode design fold test, so that my old-style headers, e.g.,
      --     ┃ YYYY-MM-DD: FIVER: Foo ┃
      -- are pipe-prefixed like other open tasks.
      -- - So now if you don't want such titles pipe-prefixed,
      --   just ensure they have 2 or fewer lines of content,
      --   e.g., see judge design folds mostly by
      --     g:restfold_weldable_min_content_lines = 3
      vim.g.restfold_weldable_unicode_enable_all = 1
    end,

    keys = {
      {
        ft = "rst",
        mode = { "n", "i" },
        "<S-F5>",
        "<cmd>call ReSTFolderUpdateFolds(1)<CR>",
        silent = true,
        buffer = true,
        desc = "Reset reSTfolds (and Close All)",
      },
      {
        ft = "rst",
        mode = { "n", "i" },
        "<F5>",
        "<cmd>call ReSTFolderUpdateFolds(0)<CR>",
        silent = true,
        buffer = true,
        desc = "Update reSTfolds (and Close All But 1)",
      },
      -- LazyVim maps <M-j>/<M-k> to move line down/up.
      -- - We'll use similar seqs: <S-M-j>/<S-M-k>.
      -- - SAVVY: In which-key, you'll see 󰊄 icon, for rst &ft.
      --  - CXREF:
      --     ~/.local/share/nvim_lazyb/lazy/mini.icons/lua/mini/icons.lua
      {
        ft = "rst",
        mode = { "n" },
        -- BNDNG: <Shift-Alt-K>
        alt_keys.lookup("K"),
        "<cmd>silent call ReSTFolderMoveUp()<CR>",
        silent = true,
        buffer = true,
        desc = alt_keys.AltKeyDesc("Move reSTfold § Up", "<M-K>"),
      },
      {
        ft = "rst",
        mode = { "n" },
        -- BNDNG: <Shift-Alt-J>
        alt_keys.lookup("J"),
        "<cmd>silent call ReSTFolderMoveFoldDown()<CR>",
        silent = true,
        buffer = true,
        desc = alt_keys.AltKeyDesc("Move reSTfold § Down", "<M-J>"),
      },
    },

    -- CXREF:
    -- ~/.kit/nvim/landonb/vim-reSTfold/autoload/embrace/reSecTions.vim
    config = function()
      local wk = require("which-key")
      wk.add({
        mode = { "n" },
        icon = "",
        { "<LocalLeader>(", group = "Draw rst borders" },
        { "<LocalLeader>)", group = "Draw rst borders" },
        { "<LocalLeader>/", group = "Draw rst borders" },
        { "<LocalLeader><", group = "Draw rst borders" },
        { "<LocalLeader>>", group = "Draw rst borders" },
        { "<LocalLeader>[", group = "Draw rst borders" },
        { "<LocalLeader>{", group = "Draw rst borders" },
        { "<LocalLeader>}", group = "Draw rst borders" },
        { "<LocalLeader><LocalLeader>", group = "Draw rst borders" },
        { "<LocalLeader><LocalLeader>|", group = "Draw rst borders" },
        { "<LocalLeader><LocalLeader>|(", group = "Draw rst borders" },
        { "<LocalLeader><LocalLeader>|)", group = "Draw rst borders" },
        { "<LocalLeader><LocalLeader>|/", group = "Draw rst borders" },
        { "<LocalLeader><LocalLeader>|<", group = "Draw rst borders" },
        { "<LocalLeader><LocalLeader>|>", group = "Draw rst borders" },
        { "<LocalLeader><LocalLeader>|[", group = "Draw rst borders" },
        { "<LocalLeader><LocalLeader>|{", group = "Draw rst borders" },
        { "<LocalLeader><LocalLeader>|}", group = "Draw rst borders" },
        -- Add icons to the command maps.
        { "<LocalLeader>1" },
        { "<LocalLeader>!" },
        { "<LocalLeader>2" },
        { "<LocalLeader>@" },
        { "<LocalLeader>3" },
        { "<LocalLeader>#" },
        { "<LocalLeader>6" },
        { "<LocalLeader>^" },
        { "<LocalLeader>8" },
        { "<LocalLeader>*" },
        { "<LocalLeader>-" },
        { "<LocalLeader>_" },
        { "<LocalLeader>=" },
        { "<LocalLeader>+" },
      })
    end,
  },

  {
    dir = "~/.kit/nvim/landonb/vim-reST-highdefs",
    event = "VeryLazy",
  },

  {
    dir = "~/.kit/nvim/landonb/vim-reST-highfive",
    event = "VeryLazy",
  },

  {
    dir = "~/.kit/nvim/landonb/vim-reST-highline",
    event = "VeryLazy",
  },
}
