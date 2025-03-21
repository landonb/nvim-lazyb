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
              { find = "%d+L, %d+B" },
              { find = "; after #%d+" },
              { find = "; before #%d+" },
              -- CXREF: *Reducing the noise from neovim messages*
              -- https://github.com/folke/noice.nvim/discussions/908#discussioncomment-10583586
              -- CXREF:
              -- ~/.kit/nvim/embrace-vim/start/vim-command-line-clock/autoload/embrace/command_line_clock.vim @ 533
              { find = "%d fewer lines" },
              { find = "%d more lines" },
              -- { find = "written" },
              { find = '%d lines? yanked into "' },
              -- E.g., "3 lines <ed 1 time"
              { find = "%d lines? [<>]ed %d times?" },
              -- SPIKE: Why don't these work?
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
      -- FEATR: Close noice overflow window (whatever it's called; when you,
      -- e.g., :mess and Noice opens a Scratch buffer window at the bottom).
      --
      -- FTREQ: Toggle Noice window.
      -- FIXME: FTREQ: Clear Noice history (:mess clear does not).
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
