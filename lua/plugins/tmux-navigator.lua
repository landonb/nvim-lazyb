-- vim:tw=0:ts=2:sw=2:et:ai:ft=lua
-- Author: Landon Bouma <https://tallybark.com/>
-- Project: https://github.com/landonb/nvim-lazyb#🧸

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

-- BEGET: Migrated from nvim-depoxy:
-- ~/.kit/nvim/embrace-vim/start/vim-buffer-delights/plugin/create-window-navigation-mappings.vim
-- CALSO: https://github.com/numToStr/Navigator.nvim

local alt_keys = require("util.alt2meta-keys")

local ctrl_keys = require("util.ctrl2pua-keys")

return {
  {
    dir = "~/.kit/nvim/landonb/vim-tmux-navigator",
    event = "VeryLazy",

    init = function()
      vim.g.tmux_navigator_no_mappings = 1
    end,

    -- Note lazy.nvim supports keys = {}, but that doesn't support nesting, e.g.,
    -- each map needs to specify its own mode = {}.
    -- - The lazy.nvim keys feature is useful for lazy-loading, except this
    --   plugin uses the "VeryLazy" event, so using keys wouldn't affect loading.
    config = function()
      require("which-key").add({
        mode = { "n", "i" },

        -- <Ctrl-Cmd-Left|Up|Down|Right> navigation.
        -- - By default, Normal <C-D-Left|Right> jumps WORDS; in Insert mode, words.
        { "<C-D-Left>", "<cmd>:TmuxNavigateLeft<CR>", desc = "Go to Left Window" },
        { "<C-D-Up>", "<cmd>:TmuxNavigateUp<CR>", desc = "Go to Upper Window" },
        { "<C-D-Down>", "<cmd>:TmuxNavigateDown<CR>", desc = "Go to Lower Window" },
        { "<C-D-Right>", "<cmd>:TmuxNavigateRight<CR>", desc = "Go to Right Window" },

        -- Numpad navigation.
        -- - `:h keycodes` says <k0>..<k9>, but that doesn't work for me with
        --   the Alt-key modifier. E.g., <k4> or <C-k4> works, but not <M-k4>.
        { "<M-4>", "<cmd>:TmuxNavigateLeft<CR>", desc = "Go to Left Window" },
        { "<M-8>", "<cmd>:TmuxNavigateUp<CR>", desc = "Go to Upper Window" },
        { "<M-2>", "<cmd>:TmuxNavigateDown<CR>", desc = "Go to Lower Window" },
        { "<M-6>", "<cmd>:TmuxNavigateRight<CR>", desc = "Go to Right Window" },

        -- Use Alt-\ to toggle focus between current pane and previously-focused pane.
        -- (Many other developers might have this wired to Ctrl-\.)
        -- - I've seen this mapped to <Ctrl-\> in some other devs' configs.
        -- - CALSO: This is similar to author's <F2> for MRU buffer (same window).
        -- - Aside: Pressing <D-\> inserts literal <D-Bslash>.
        --  { "<C-\\>", "<cmd>:TmuxNavigateLast<CR>", desc = "Go to Last Window" },
        -- FTREQ: None of the PUA bindings appear in which-key.
        -- - I'm pretty sure this would be a which-key feature.
        -- BNDNG: <Shift-Ctrl-\> aka <Ctrl-|> aka 
        {
          ctrl_keys.lookup("|"),
          "<cmd>:TmuxNavigateLast<CR>",
          desc = "Go to MRU Window (C-S-\\)",
        },

        -- Ctrl-Shift-Up/-Down cycle focus counter-clockwise/closewise around panes.
        -- - CALSO: Same as `:wincmd W`, unless tmux running.
        { "<C-S-Up>", "<cmd>:TmuxNavigatePrevious<CR>", desc = "Go to Prev Window" },
        -- - CALSO: Same as `:wincmd w`, unless tmux running.
        { "<C-S-Down>", "<cmd>:TmuxNavigateNext<CR>", desc = "Go to Next Window" },

        -- Sorta related: Tabpage navigation.
        { "<M-S-Down>", "<cmd>:tabn<CR>", desc = "Go to Next Tab Page" },
        { "<M-S-Up>", "<cmd>:tabN<CR>", desc = "Go to Prev Tab Page" },

        -- 2025-03-08: I've been thinking...
        {
          alt_keys.alt_w .. "<Left>",
          "<cmd>:TmuxNavigateLeft<CR>",
          desc = alt_keys.AltKeyDesc("Go to Left Window", "<M-w>←"),
        },
        {
          alt_keys.alt_w .. "<Up>",
          "<cmd>:TmuxNavigateUp<CR>",
          desc = alt_keys.AltKeyDesc("Go to Upper Window", "<M-w>↑"),
        },
        {
          alt_keys.alt_w .. "<Down>",
          "<cmd>:TmuxNavigateDown<CR>",
          desc = alt_keys.AltKeyDesc("Go to Lower Window", "<M-w>↓"),
        },
        {
          alt_keys.alt_w .. "<Right>",
          "<cmd>:TmuxNavigateRight<CR>",
          desc = alt_keys.AltKeyDesc("Go to Right Window", "<M-w>→"),
        },
      })
    end,
  },
}
