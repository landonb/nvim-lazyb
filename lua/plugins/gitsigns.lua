-- vim:tw=0:ts=2:sw=2:et:ai:ft=lua
-- Author: Landon Bouma <https://tallybark.com/>
-- Project: https://github.com/landonb/nvim-lazyb#🧸

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

-- CXREF:
-- ~/.local/share/nvim_lazyb/lazy/LazyVim/lua/lazyvim/plugins/editor.lua @ 120

return {
  {
    "lewis6991/gitsigns.nvim",

    keys = {
      -- UCASE: Show blame in popup, handy for copying the commit SHA.
      -- - SAVVY: If you use the SHA for git-fixup, consider instead git-absorb.
      {
        mode = { "n", "i" },
        "<LocalLeader>db",
        "<cmd>Gitsigns blame_line<CR>",
        noremap = true,
        silent = true,
        desc = "Git Blame Line Popup",
      },
    },
  },
}
