-- vim:tw=0:ts=2:sw=2:et:ai:ft=lua
-- Author: Landon Bouma <https://tallybark.com/>
-- Project: https://github.com/landonb/nvim-lazyb#🧸

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

-- REFER:
-- https://github.com/stevearc/conform.nvim

-- CXREF: LazyVim formats on save via BufWritePre:
-- ~/.local/share/nvim_lazyb/lazy/LazyVim/lua/lazyvim/util/format.lua @ 162
-- - CALSO: You can also call conform directly:
--     require("conform").format({ bufnr = args.buf })
-- - CALSO: There's also the LSP "primitive":
--     vim.lsp.buf.format()

-- REFER: |'formatexpr'| |'formatoptions'| |'formatprg'|

---@class lazyb.plugins.conform-nvim
local M = {}

local ctrl_keys = require("util.ctrl2pua-keys")

M.save_noformat = function()
  -- Toggle the LazyVim autoformat enabler.
  -- - See also vim.g.autoformat.
  local buf = vim.api.nvim_get_current_buf()
  local baf = vim.b[buf].autoformat
  vim.b[buf].autoformat = false

  vim.cmd.update()

  vim.b[buf].autoformat = baf
end

return {
  {
    "stevearc/conform.nvim",
    -- Merged from LazyVim:
    --   dependencies = { "mason.nvim" },
    opts = {
      formatters_by_ft = {
        -- *** The LazyVim defaults, copied for reference.
        --
        lua = { "stylua" },
        fish = { "fish_indent" },
        sh = { "shfmt" },
        --
        -- *** And here's what we add.
        --
        -- Don't format OMR config files, which use ft=bash for syntax
        -- highlighting (but are themselves not Bash files, they just
        -- contain a lot of it, and can be likewise syntax highlighted).
        bash = function(bufnr)
          local bufname = vim.api.nvim_buf_get_name(bufnr)
          local basename = vim.fs.basename(bufname)
          -- Convention: I name OMR config files with an optional
          -- dot or underscore prefix, followed by "mrconfig",
          -- ending in an optional postfix.
          -- REFER: |string.find| |lua-pattern| |lua-patterns|
          if not basename:find("^.?mrconfig") then
            return { "shfmt" }
          else
            return {}
          end
        end,

        --
        -- *** From conform.nvim/README
        --
        -- Run Python formatters sequentially.
        -- - LATER: Verify this order matches projects'.
        python = { "isort", "black" },
        -- You can customize some of the format options
        -- for the filetype (:help conform.format)
        rust = { "rustfmt", lsp_format = "fallback" },
        -- Conform will run the first available formatter
        javascript = {
          "prettierd",
          "prettier",
          stop_after_first = true,
        },

        -- MAYBE: Consider additional formatters:
        --
        -- -- Use the "*" filetype to run formatters on all filetypes.
        -- ["*"] = { "codespell" },
        --
        -- -- Use the "_" filetype to run formatters on filetypes that don't
        -- -- have other formatters configured.
        -- ["_"] = { "trim_whitespace" },
      },
      formatters = {
        -- SAVVY: Here's how you configure shfmt herein,
        -- but it's more flexible if you use .editorconfig.
        --   shfmt = {
        --     -- --indent Indent: 0 for tabs (default),
        --     --                  >0 for number of spaces
        --     --   (though unnecessary if .editorconfig exists)
        --     -- --binary-next-line Binary ops like && and |
        --     --   may start a line
        --     -- --case-indent Switch cases will be indented
        --     -- --space-redirects Redirect operators
        --     --   will be followed by a space
        --     -- --keep-padding Keep column alignment paddings
        --     --   DUNNO: What's an example of this rule?
        --     prepend_args = { "-i", "2", "-bn", "-ci", "-sr", "-kp" },
        --   },
      },
      -- REFER: Debugging hints:
      -- https://github.com/stevearc/conform.nvim/blob/master/doc/debugging.md#testing-the-formatter
      -- USAGE: Increase log verbosity (run :ConformInfo, then `gf` the log path).
      --  log_level = vim.log.levels.DEBUG,
      --  log_level = vim.log.levels.TRACE, -- logs entire input and output
    },

    -- SAVVY: TIL: Just confirming: The config() fcn.
    -- runs after LazyVim merges its opts{} with the
    -- opts{} from our spec (above). So config() has
    -- the complete opts.
    -- (Though note we don't want to set config()
    -- here, which overrides LazyVim's; if you
    -- ever want to replace LazyVim's config()
    -- function, you have to replicate it (though
    -- I've wondered why there's not a config()
    -- hook for client specs...).)
    --
    --   config = function(_, opts)
    --     print("conform: config: " .. vim.inspect(opts))
    --     return opts
    --   end,

    keys = {
      -- BNDNG: <Shift-Ctrl-S> aka <> save without formatting.
      {
        mode = { "n", "i" },
        ctrl_keys.lookup("S"),
        M.save_noformat,
        noremap = true,
        silent = true,
        desc = "Save File w/o Formatting",
      },
      -- Unusable (Unreachable) binding but that shows up in which-key.
      {
        mode = { "n", "i" },
        "<C-S-S>",
        M.save_noformat,
        noremap = true,
        silent = true,
        desc = "Save File w/o Formatting",
      },
    },
  },
}
