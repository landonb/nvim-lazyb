-- vim:tw=0:ts=2:sw=2:et:ai:ft=lua
-- Author: Landon Bouma <https://tallybark.com/>
-- Project: https://github.com/landonb/nvim-lazyb#🧸

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

-- REFER:
-- https://github.com/tpope/vim-fugitive

local alt_keys = require("util.alt2meta-keys")

local wk = require("which-key")

return {
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
      -- Load autoload# fcn: git_fugitive_window_cleanup#close_git_windows()
      -- - CXREF:
      --   ~/.kit/nvim/DepoXy/start/vim-depoxy/autoload/git_fugitive_window_cleanup.vim
      -- FIXME: Localize this file.
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
        -- BNDNG: <Leader>g<M-c> aka <Leader>gç
        "<Leader>g" .. alt_keys.lookup("c"),
        function()
          vim.fn["git_fugitive_window_cleanup#close_git_windows"]()
        end,
        noremap = true,
        silent = true,
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
    --  To enable this feature, add this to your global .gitconfig:
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
}
