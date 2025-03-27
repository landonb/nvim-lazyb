-- vim:tw=0:ts=2:sw=2:et:ai:ft=lua
-- Author: Landon Bouma <https://tallybark.com/>
-- Project: https://github.com/landonb/nvim-lazyb#🧸

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

-- CXREF:
-- ~/.local/share/nvim_lazyb/lazy/LazyVim/lua/lazyvim/plugins/util.lua @ 38

return {
  {
    "folke/persistence.nvim",

    -- REFER: LazyVim <Leader>q bindings: <L>qs | <L>qS | <L>ql | <L>qd
    --   cd ~/.local/share/nvim_lazyb/lazy
    --   rg "leader>q"
    -- REFER: nvim-lazyb: <L>qD (Snacks Dashboard) | <L>qw (Persistence Write)
    keys = {
      -- USAGE: Persistence names the Session file using the active
      -- window's working directory (via vim.fn.getcwd()).
      -- - REFER: Session files are saved under ~/.local/state:
      --     lo ~/.local/state/nvim_lazyb/sessions/
      {
        "<leader>qw",
        function()
          require("persistence").save()
        end,
        desc = "Write Session",
        -- Too bad keys{} doesn't support icon (and I don't feel like wk.add).
        --   -- PERSon In STeamy Room
        --   -- ----   -  --
        --   icon = "🧖",
      },
    },
  },
}
