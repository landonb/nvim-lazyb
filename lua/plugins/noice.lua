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

      views = {
        split = {
          -- "Override the default split view to always enter the split when it opens."
          -- - SAVVY: After 'enter', use <Shift-Ctrl-\> to return to previous window.
          -- - FTREQ: Re-enter :mess window on :mess if already open.
          --   - Currently, :mess does not re-enter :mess window if already
          --     open (but buffer doesn't update either until you run :mess).
          --  - MAYBE: Set filetype and redo :mess cmd (which you can't,
          --    can you? So maybe make :Mess command or create a map).
          --  - FTREQ: It'd be nice if `:mess clear` also closed it.
          --    - MAYBE: Maybe this is :Mess! or something, clear and close...
          --  - FTREQ: Scroll Nui split window to bottom on :mess.
          -- - MAYBE: Should <Shift-Alt-2> also close signature window?
          --   - In the least, <Ctrl-K> should close it if remains open...
          --     - Except I introduced issue keeping it open, e.g., if you
          --       move cursor to another window, signature window does not
          --       close — but it does in LazyVim (`faf`) so obvi. my fault.
          -- - FIXME: When closing Noice :mess window, return to previous window.
          --   - MAYBE: Add prev-window to all window-close maps.
          --
          -- Move cursor to new Noice split when you run :mess.
          -- - As mentioned above, doesn't re-enter if already open.
          enter = true,

          buf_options = {
            -- FIXME- PR Noice to allow this. (This relies on my fork until then.)
            -- - BWARE: Don't set `modifiable = false` or Noice opens-closes
            --   :messages fast and prints "Buffer is not 'modifiable'".
            modifiable = true,

            -- Set a custom filetype so we can identify the :mess window.
            -- - TRACK: Are there other Noice commands that'll use the
            --   same &filetype? (So far I haven't seen anything.)
            filetype = "noice_messages",
          },
        },
      },

      -- CXREF: Following commented options are subset of noice defaults:
      -- ~/.local/share/nvim_lazyb/lazy/noice.nvim/lua/noice/config/init.lua @ 116
      lsp = {
        --  -- override = {
        --  --   -- "override the default lsp markdown formatter with Noice"
        --  --   ["vim.lsp.util.convert_input_to_markdown_lines"] = false,
        --  --   -- "override the lsp markdown formatter with Noice"
        --  --   ["vim.lsp.util.stylize_markdown"] = false,
        --  --   -- "override cmp documentation with Noice (needs the other options to work)"
        --  --   ["cmp.entry.get_documentation"] = false,
        --  -- },
        signature = {
          --  enabled = true,
          auto_open = {
            --  enabled = true,
            --  -- "Automatically show signature help when typing a trigger
            --  --  character from the LSP."
            --  -- - Note that blink.cmp has a comparable option:
            --  --     opts.completion.trigger.show_on_insert_on_trigger_character = true
            --  --   but in LazyVim, Noice handles signatureHelp, which you
            --  --   can enable/disable here:
            --  --     Noice.Config.options.lsp.signature.auto_open.trigger
            --  -- REFER: See LSP spec and search Noice for signatureHelp:
            --  --   textDocument/signatureHelp
            --  trigger = true,
            --  -- "Will open signature help when jumping to Luasnip insert nodes"
            --  luasnip = true,
            --  -- "Will open when jumping to placeholders in snippets
            --  -- (Neovim builtin snippets)"
            --  snipppets = true,
            --  -- "Debounce lsp signature help request by 50ms"
            --  throttle = 50,
          },
          --  -- "when nil, use defaults from documentation"
          --  view = nil,
          ---@type NoiceViewOptions
          opts = {
            buf_options = { filetype = "noice_signature" },
          },
        },
        --  -- "defaults for hover and signature help"
        --  documentation = {
        --    view = "hover",
        --    ---@type NoiceViewOptions
        --    opts = {
        --      lang = "markdown",
        --      replace = true,
        --      render = "plain",
        --      format = { "{message}" },
        --      win_options = { concealcursor = "n", conceallevel = 3 },
        --    },
        --  },
      },
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
          local winids = require("util.windows").close_windows_by_ft({ filetype = "noice_messages" })
          if #winids == 0 then
            -- SAVVY: Note the window won't open if there are no :messages.
            vim.cmd.messages()
          end
        end,
        noremap = true,
        silent = true,
        desc = alt_keys.AltKeyDesc("Show/Hide Noice Splits (:messages)", "<M-@>"),
      },
      {
        mode = { "n", "i" },
        "<S-D-2>",
        function()
          vim.cmd("messages clear")
          local winids = require("util.windows").close_windows_by_ft({ filetype = "noice_messages" })
        end,
        noremap = true,
        silent = true,
        desc = alt_keys.AltKeyDesc("`:mess clear` and Hide Noice Splits", "<D-@>"),
      },
    },
  },
}
