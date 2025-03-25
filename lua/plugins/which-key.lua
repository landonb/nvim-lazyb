-- vim:tw=0:ts=2:sw=2:et:ai:ft=lua
-- Author: Landon Bouma <https://tallybark.com/>
-- Project: https://github.com/landonb/nvim-lazyb#🧸

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

-- SAVVY: To see Insert mode maps in which-key, press <Ctrl-r> to bring
-- up the registers window, then press <BS>.

-- BWARE: Unless you find better bindings then <C-D> and <C-U>, avoid
-- those maps in all modes so they work in the which-key window (which
-- can be summoned in Normal, Insert, Visual, and Select modes and
-- uses <C-U>/<C-D> maps from each mode to scroll up/down the keys list).
--
-- BUGGN: Note that Neovim's enhanced <C-u> blocks which-key:
-- - Neovim --noplugin `imap <C-u>` reports:
--     i  <C-U>       * <C-G>u<C-U>
--                      :help i_CTRL-U-default
-- - But which-key Insert mode <C-u> won't work unless you unmap it:
--     iunmap <C-u>
-- - BWARE: But if you `iunmap <C-U>`, then the <C-U> is not undoable!
--   - E.g., run `iunmap <C-U>`, enter insert mode, type a line,
--     press <C-U> to delete the line, then <Esc>, and press `u`
--     to undo, but your deletion won't undo!
--   - So we'll leave the built-in <C-U>.
--   - CPYST: If you want to scroll the Insert mode which-key window
--     upwards, you can remove and restore the map manually (or just
--     restart Neovim, 'natch):
--       iunmap <C-u>
--       inoremap <C-u> <C-G>u<C-U>
-- - REFER: CTRL-G u — close undo sequence, start new change |i_CTRL-G_u|
--
-- INERT: There might be a way to devise a <Ctrl-U> map that works with
-- which-key. E.g., check state, and fallback built-in <C-u> if which-key
-- is active. But not a high priority, or any sort of priority; fudge it.

-- FIXME- BUGGN: Cannot run register command via <C-O> from Insert mode — `<C-O>"`
-- - LATER: PR this. / CXREF: See fix:
--   ~/.local/share/nvim_lazyb/lazy/which-key.nvim/lua/which-key/state.lua
--
-- - UCASE: I cannot specify register via <C-O> command.
--   - E.g., while testing a `let @/ = ` pattern, I could
--     run <C-O>dn from Insert mode, but I could not run
--     <C-O>"_dn — which-key would appear instead, after
--     typing `"`, and then after `_`, it would literally
--     insert `"_`.

return {
  {
    "folke/which-key.nvim",
    -- event = "VeryLazy",
    build = require("util").lazy_build_fork("which-key.nvim"),
    opts_extend = { "spec" },
    opts = {
      -- preset = "helix",
      -- defaults = {},
      -- REFER: Search Nerd Fonts:
      -- https://www.nerdfonts.com/cheat-sheet
      spec = {
        {
          mode = { "n", "v" },
          { "<Leader>", group = "LazyVim", icon = { icon = "💤" } },
          { "<LocalLeader>", group = "lazyb", icon = { icon = "󰗣", color = "yellow" } },
          { "<LocalLeader>d", group = "dubs", icon = { icon = "", color = "green" } }, -- 󰗣
          -- CXREF: Just a few vim-fugitive commands... not totally sold on this prefix...
          -- ~/.kit/nvim/landonb/nvim-lazyb/lua/plugins/embrace-vim.lua @ 544
          { "<LocalLeader>f", group = "fugitive", icon = { icon = "" } }, -- color = "#918868"
          { "<LocalLeader>o", group = "web open", icon = { icon = "󰖟", color = "blue" } },
          { "_", group = "buffers", icon = { icon = "" } },
          { "<M-f>", group = "files/buffers", icon = { icon = "" } },
          { "<M-w>", group = "windows", icon = { icon = "" } },
          -- BUGGN: Where's the "Plug" entry coming from? Is there a way
          -- to show its submenu? We can at least name it, ha.
          { "<Plug>", group = "phooey", icon = { icon = "󱃟" } },
        },

        -- REFER: https://github.com/folke/which-key.nvim/issues/946
        { "<c-w>c", desc = "Close the current window" },
      },
      -- keys = {
      --   scroll_down = "<c-d>", -- binding to scroll down inside the popup
      --   scroll_up = "<c-u>", -- binding to scroll up inside the popup
      -- },
    },
    keys = {
      {
        "<LocalLeader>?",
        function()
          require("which-key").show({ loop = true })
        end,
        desc = "Hydra Mode (nvim-lazyb)",
      },
      -- {
      --   "<leader>?",
      --   function()
      --     require("which-key").show({ global = false })
      --   end,
      --   desc = "Buffer Keymaps (which-key)",
      -- },
      -- {
      --   "<c-w><space>",
      --   function()
      --     require("which-key").show({ keys = "<c-w>", loop = true })
      --   end,
      --   desc = "Window Hydra Mode (which-key)",
      -- },
    },
  },
}
