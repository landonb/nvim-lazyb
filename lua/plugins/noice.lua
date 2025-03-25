-- vim:tw=0:ts=2:sw=2:et:ai:ft=lua
-- Author: Landon Bouma <https://tallybark.com/>
-- Project: https://github.com/landonb/nvim-lazyb#🧸

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

-- CALSO: Noice handles the LSP progress messages you see in the
-- bottom right on the editor sometimes.
-- - It looks similar to the screenshot on this plugin's readme:
--  - *Extensible UI for Neovim notifications and LSP progress messages.*
--    https://github.com/j-hui/fidget.nvim
--  - Also: *feat: integrate with Noice + use as cmdline UI?*
--    https://github.com/j-hui/fidget.nvim/issues/210

-- USAGE: Show Noice history in bottom scratch:
--
--   lua require('noice').cmd()
--
-- See also `:Noice <Tab>`

-- SPIKE: Peruse Ecovim for settings ideas:
-- https://github.com/ecosse3/nvim/blob/master/lua/plugins/noice.lua

local alt_keys = require("util.alt2meta-keys")

return {
  -- CXREF:
  -- ~/.local/share/nvim/lazy/LazyVim/lua/lazyvim/plugins/ui.lua @ 193
  {
    "folke/noice.nvim",
    event = "VeryLazy",

    -- FIXME: Open PR for buf_options.modifiable :messages split.
    -- - Use LazyVim/starter `faf` branch to add barest config to copy to PR.
    build = require("util").lazy_build_fork("noice.nvim", "main"),

    opts = {
      routes = {
        {
          filter = {
            event = "msg_show",
            any = {
              -- CXREF: LazyVim defines just the first three rules:
              --   ~/.local/share/nvim_lazyb/lazy/LazyVim/lua/lazyvim/plugins/ui.lua
              -- REFER: A discussion of additional rules:
              -- - *Reducing the noise from neovim messages*:
              --   https://github.com/folke/noice.nvim/discussions/908#discussioncomment-10583586

              -- E.g.,:
              --   "~/.vim/pack/embrace-vim/start/....vim" 233L, 6289B written
              --   "command_line_clock.vim" 528L, 20386B written
              -- - ALTLY: { find = '^"[^"]\+" \d\+L, \d\+B written$' },
              { find = "%d+L, %d+B" },

              -- E.g.:
              --   1 change; before #15  1 second ago
              --   1 more line; after #3  5 seconds ago
              --   1 line less; before #33  1 second ago
              -- - ALTLY:
              --   { find = "^\d\+ \(change\?|more lines\?|lines\? less\); before #\d\+ \d\+ seconds\? ago$" },
              { find = "; after #%d+" },
              { find = "; before #%d+" },

              -- Additional rules nvim-lazyb adds.
              { find = "%d fewer lines" },
              { find = "%d more lines" },
              { find = '%d lines? yanked into "' },
              -- E.g., "3 lines <ed 1 time"
              { find = "%d lines? [<>]ed %d times?" },

              -- SPIKE: Why don't these rules work? (Perhaps because they're
              -- displayed on startup before this config is loaded?)
              -- E.g., "W325: Ignoring swapfile from Nvim process 1648"
              { find = "^W325: Ignoring swapfile from Nvim process " },
              { find = "W325: Ignoring swapfile from Nvim process " },
            },
          },
          view = "mini",
        },
      },

      -- TASTE: The presets each default false. Uncomment to test alt. behaviors.
      ---@type NoicePresets
      presets = {
        --  -- "use a classic bottom cmdline for search"
        --  bottom_search = true,
        --  -- "position the cmdline and popupmenu together"
        --  command_palette = true,
        --  -- "long messages will be sent to a split"
        --  long_message_to_split = true,
        --  -- "enables an input dialog for inc-rename.nvim"
        --  inc_rename = true,
        --  -- "add a border to hover docs and signature help"
        --  lsp_doc_border = true,
        --  -- "send the output of a command you executed in the cmdline to a split"
        --  cmdline_output_to_split = true,
      },

      -- TASTE: The white border around the cmdline float makes it easier to find.
      -- - Uncomment the following to see it without.
      -- - CXREF:
      --   https://github.com/folke/noice.nvim/wiki/Configuration-Recipes#clean-cmdline_popup
      --
      --  views = {
      --    cmdline_popup = {
      --      border = {
      --        style = "none",
      --        padding = { 2, 3 },
      --      },
      --      filter_options = {},
      --      win_options = {
      --        winhighlight = "NormalFloat:NormalFloat,FloatBorder:FloatBorder",
      --      },
      --    },
      --  },

    },

    keys = {
      -- INERT/FTREQ: Clear `:Noice history` (aka `:Noice`).
      -- - This might be the only approach:
      --     lua require("noice.message.manager")._history = {}
      --   - REFER: @folke says won't fix:
      --     https://github.com/folke/noice.nvim/issues/731
      -- - INERT: I use <Leader>n to view notifications (<Leader>n shows
      --   a subset of what :Noice shows), and lately I haven't been
      --   bothered by it not being cleared (unlike :messages, which I
      --   often `:mess clear`, especially when I'm debugging).

      -- USAGE: Toggle Noice split window used to show :messages
      --        w/ <Shift-Alt-2> aka <Alt-@>.
      {
        mode = { "n", "i" },
        -- BNDNG: <Shift-Alt-2> aka <Shift-Alt-@> aka <M-@> aka <€>
        -- REFER: nvim-depoxy <M-@> is toggle :netrw (we don't want).
        alt_keys.lookup("@"),
        function()
          local winids = require("util.windows").close_windows_by_ft({ filetype = "noice" })
          if #winids == 0 then
            -- SAVVY: Note the window won't open if there are no :messages.
            vim.cmd.messages()
          end
        end,
        noremap = true,
        silent = true,
        desc = alt_keys.AltKeyDesc("Show/Hide Noice Splits (:messages)", "<M-@>"),
      },
    },
  },
}
