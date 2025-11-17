-- vim:tw=0:ts=2:sw=2:et:ai:ft=lua
-- Author: Landon Bouma <https://tallybark.com/>
-- Project: https://github.com/landonb/nvim-lazyb#🧸

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

-- REFER:
--   :Org help
--   :help orgmode.txt
-- https://nvim-orgmode.github.io/
-- https://github.com/nvim-orgmode/orgmode/blob/master/docs/index.org#getting-started
--
-- WIRED:
--   Open agenda prompt: <Leader>oa
--   Open capture prompt: <Leader>oc
--   In any orgmode buffer press g? for help
-- https://github.com/nvim-orgmode/orgmode/blob/master/docs/index.org#globals-and-commands

return {
  {
    -- https://github.com/nvim-orgmode/orgmode
    -- ~/.local/share/nvim_lazyb/lazy/orgmode
    "nvim-orgmode/orgmode",
    event = "VeryLazy",
    ft = { "org" },
    config = function()
      -- Setup orgmode
      require("orgmode").setup({
        org_agenda_files = "~/.orgfiles/**/*",
        org_default_notes_file = "~/.orgfiles/refile.org",
      })

      -- NOTE- If you are using nvim-treesitter with option:
      --   ensure_installed = "all"
      -- then add ~org~ to ignore_install, e.g.:
      --
      --   require('nvim-treesitter.configs').setup({
      --     ensure_installed = 'all',
      --     ignore_install = { 'org' },
      --   })
    end,
  },
}
