-- vim:tw=0:ts=2:sw=2:et:ai:ft=lua
-- Author: Landon Bouma <https://tallybark.com/>
-- Project: https://github.com/landonb/nvim-lazyb#🧸

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

-- CXREF:
-- ~/.local/share/nvim_lazyb/lazy/LazyVim/lua/lazyvim/plugins/coding.lua

return {
  -- auto pairs
  {
    "echasnovski/mini.pairs",
    opts = {
      -- Disable command line autopairing (which LazyVim enables).
      modes = { insert = true, command = false, terminal = false },
    },
  },
}
