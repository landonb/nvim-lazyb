-- vim:tw=0:ts=2:sw=2:et:ai:ft=lua
-- Author: Landon Bouma <https://tallybark.com/>
-- Project: https://github.com/landonb/nvim-lazyb#🧸

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

-- dubs_after_darks is my old, high-contrast dark colorscheme, with
-- a truly black background color, and vibrant syntax coloring. I
-- created this colorscheme mostly because I'm often in a sunny
-- room, and I find that the more "beautiful" colorschemes, like
-- toykonight-moon and catppuccin-mocha, are often more difficult
-- to read clearly (e.g., in the more elegant colorschemes, you'll
-- often find that the Normal text highlight is not as white as
-- white, and the background is not as black as black, so the text
-- does not stand out as much, especially in a sunny room).
--
-- In any case, I do like the fancier colorschemes, especially as
-- a change to dubs_after_dark. But we'll make a few tweaks to give
-- them a little more contrast, so that text and window borders
-- stand out more.
--
-- USAGE: Use `Lazy reload {colorscheme}` to try the colorschemes
-- below, and not just `colorscheme {colorscheme}`, so that a few
-- color adjustments are made.
--
--   Lazy reload after-dark
--   Lazy reload catppuccin
--   Lazy reload tokyonight

local high_priority = 1000

return {
  {
    dir = "~/.kit/nvim/landonb/dubs_after_dark",
    name = "after-dark",
    lazy = true,
    priority = high_priority,

    config = function()
      vim.cmd([[colorscheme after-dark]])
      require("util.colorscheme").setup()
    end,
  },

  -- CXREF/2025-02-22: LazyVim includes default opts for catppuccin (I
  -- think catppuccin was default colorscheme before toykonight-moon):
  -- ~/.local/share/nvim/lazy/LazyVim/lua/lazyvim/plugins/colorscheme.lua
  {
    "catppuccin/nvim",
    name = "catppuccin",
    lazy = true,
    priority = high_priority,

    config = function()
      vim.cmd([[colorscheme catppuccin-mocha]])
      require("util.colorscheme").setup()
    end,
  },

  -- LazyVim includes this already. Here we add a config(), so you can
  -- `Lazy reload tokyonight.nvim` instead of `colorscheme tokyonight-moon`.
  {
    -- "folke/tokyonight.nvim",
    dir = "~/.kit/nvim/folke/tokyonight.nvim",
    name = "tokyonight",
    lazy = true,
    priority = high_priority,
    config = function()
      -- 'tokyonight' is abbrev. for 'tokyonight-moon'
      --    vim.cmd([[colorscheme tokyonight]])
      vim.cmd([[colorscheme tokyonight-moon]])
      --  Here's slighter darker version, night-night:
      --    vim.cmd([[colorscheme tokyonight-night]])
    end,
  },

  -- *** Just 'cause I have the config from elsewhere, lots more colorschemes...

  {
    "ellisonleao/gruvbox.nvim",
    lazy = true,
    priority = high_priority,
    config = function()
      vim.cmd([[colorscheme gruvbox]])
    end,
  },

  {
    -- "arcticicestudio/nord-vim",
    dir = "~/.kit/nvim/arcticicestudio/opt/nord-vim",
    lazy = true,
    priority = high_priority,
    config = function()
      vim.cmd([[colorscheme nord]])
    end,
  },

  {
    -- "flazz/vim-colorschemes",
    dir = "~/.kit/nvim/flazz/opt/vim-colorschemes",
    lazy = true,
    priority = high_priority,
    -- CXREF: This is a *collection* of colorschemes
    --   ~/.kit/nvim/flazz/start/vim-colorschemes/README.md
    -- - E.g., 'wombat', 'molokai', etc.
    --
    --   config = function()
    --     vim.cmd([[colorscheme wombat]])
    --   end,
  },

  {
    -- "nanotech/jellybeans.vim",
    dir = "~/.kit/nvim/nanotech/opt/jellybeans.vim",
    lazy = true,
    priority = high_priority,
    config = function()
      vim.cmd([[colorscheme jellybeans]])
    end,
  },

  {
    -- "tpope/vim-vividchalk",
    dir = "~/.kit/nvim/tpope/opt/vim-vividchalk",
    lazy = true,
    priority = high_priority,
    config = function()
      vim.cmd([[colorscheme vividchalk]])
    end,
  },

  -- https://github.com/JoosepAlviste/palenightfall.nvim
  -- BEGET: https://github.com/joosepalviste/dotfiles/
  --   *Thnks fr th Trsttr - Tiny text editing automations with Treesitter*
  --   https://www.youtube.com/watch?v=_m7amJZpQQ8
  {
    "JoosepAlviste/palenightfall.nvim",
    lazy = true,
    priority = high_priority,
    config = function()
      -- vim.cmd([[colorscheme palenightfall]])
      require("palenightfall").setup()
    end,
  },
}
