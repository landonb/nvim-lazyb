-- vim:tw=0:ts=2:sw=2:et:ai:ft=lua
-- Author: Landon Bouma <https://tallybark.com/>
-- Project: https://github.com/landonb/nvim-lazyb#🧸

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

-- CXREF:
-- ~/.local/share/nvim_lazyb/lazy/LazyVim/lua/lazyvim/plugins/coding.lua @ 67

return {
  {
    "folke/lazydev.nvim",
    -- ft = "lua",
    -- cmd = "LazyDev",
    opts_XXX = {
      library = {
        { path = "${3rd}/luv/library", words = { "vim%.uv" } },
        { path = "LazyVim", words = { "LazyVim" } },
        { path = "snacks.nvim", words = { "Snacks" } },
        { path = "lazy.nvim", words = { "LazyVim" } },
        -- Library paths can be absoluteq
        "~/projects/my-awesome-lib",
      },
    },
  },
}
