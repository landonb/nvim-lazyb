-- vim:tw=0:ts=2:sw=2:et:ai:ft=lua
-- Author: Landon Bouma <https://tallybark.com/>
-- Project: https://github.com/landonb/nvim-lazyb#🧸

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

-- USAGE: <LocalLeader>g <LocalLeader>G <LocalLeader>C <F4> <S-F4> <M-F4>
--        <LocalLeader>dg <LocalLeader>dn <LocalLeader>dp <LocalLeader>dP

-- CXREF:
-- ~/.kit/nvim/landonb/dubs_grep_steady/plugin/dubs_grep_steady.vim
-- ~/.kit/nvim/landonb/dubs_grep_steady/autoload/embrace/grep_steady.vim

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

return {
  {
    dir = "~/.kit/nvim/landonb/dubs_grep_steady",
    event = "VeryLazy",

    config = function()
      local wk = require("which-key")
      wk.add({
        mode = { "n", "i", "v" },
        icon = "󰥩",
        { "<LocalLeader>g", desc = "Grep-Steady Prompt Term/Locat" },
        { "<LocalLeader>G", desc = "Grep-Steady Case-Sensitive" },
        { "<LocalLeader>C", desc = "Grep-Steady First Hits Only" },
        { "<F4>", desc = "Grep-Steady Word or Selection" },
        { "<S-F4>", desc = "Grep-Steady Prompt Location" },
        { "<M-F4>", desc = "Grep-Steady Prompt Word" },
        { "<LocalLeader>dg", desc = "Grep-Steady Toggle Multicase" },
        { "<LocalLeader>dn", desc = "Grep-Steady Toggle Col Numbs" },
        { "<LocalLeader>dp", desc = "Grep-Steady Reload Projects" },
        { "<LocalLeader>dP", desc = "Grep-Steady Edit Projects" },
      })
    end,
  },
}

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
