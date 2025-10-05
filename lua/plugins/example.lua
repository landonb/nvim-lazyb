-- USAGE: Uncomment to disable this spec
-- stylua: ignore
--if true then return {} end

-- every spec file under the "plugins" directory will be loaded automatically by lazy.nvim
--
-- In your plugin files, you can:
-- * add extra plugins
-- * disable/enabled LazyVim plugins
-- * override the configuration of LazyVim plugins

-- -----------------------------------------------------------------
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

-- FIXME/2025-03-04 14:59: Move everything from this file to new files,
-- then convert this file back to its LazyVim/starter state.
-- - Maybe also keymaps and options, you could use basic require()
--   and leave everything else close to the starter/ state.

-- -----------------------------------------------------------------
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

-- FIXME/2025-03-05 13:04: Add a few FIVERs to todo-comments, or
-- whatever is doing the highlighting.
-- - SPIKE: Also demo the <leader>st <leader>sT pickers.
--   - See also: :Todo* e.g., :TodoTelescope
-- WORDS: Add some/all of these: MAYBE: LOPRI: INERT: ALERT: BWARE:
-- - Could also consider SAVVY and REFER, although.... ugh, not.

-- -----------------------------------------------------------------
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

-- SPIKE: config() overrides previous config() def'n, e.g.,
-- from LazyVim spec, right? Is there some way to run code
-- via spec after plugin is loaded, without hooking config
-- (so that LazyVim config() runs, and we don't have to
-- duplicate it)?
-- - ALTLY: Run via keymaps.lua, or autocmds.lua, which are
--   each called on VeryLazy event... but what I want is
--   slightly different...
--
-- - REFER: *Executing code after setup without config*
--   https://github.com/folke/lazy.nvim/discussions/1909
-- - REFER: *feature: New after config function* [Closed as not planned]
--   https://github.com/folke/lazy.nvim/issues/1782#issuecomment-2637724602
-- - Aha! Run something like LazyVim event, and use User autocmd.
--
--   https://lazy.folke.io/usage#-user-events
--    LazyLoad: after loading a plugin. The data attribute will contain the plugin name.
--    VeryLazy: triggered after LazyDone and processing VimEnter auto commands
--
--     vim.api.nvim_create_autocmd('User', {
--       pattern = 'LazyLoad',
--       callback = function(event)
--         if event.data == 'the-plugin' or event.data == 'a-plugin' then
--           -- Triggered after loading each plugin. The data attribute will contain the plugin name.
--         end
--       end,
--     })
--
-- This also works but is not recommended (but it sorta looks
-- like what I thought I might be able to do — I assume it
-- runs the upstream spec's config()...):
--
--     { -- 🚨 This is an anti-pattern
--       'user/the-plugin',
--       opts = {},
--       config = function(plugin)
--         plugin.config = false ---@diagnostic disable-line: assign-type-mismatch
--         require('lazy.core.loader').config(plugin)
--         -- After plugin setup
--         -- ...
--       end
--     }
--
-- SPIKE: How would you use LazyLoad?
-- - I like the anti-pattern approach, because then I can put
--   the post-config code with the plugin spec...
--   - Otherwise... actually, if I could add a unique function
--     to the spec, does the LazyLoad event pass the plugin spec?
--     - Or is there a way to fetch the plugin spec?
--     - Because then I could make a new fcn. and call it if
--       it exists...

-- -----------------------------------------------------------------
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

-- SPIKE/2025-03-05: Is this how LazyVim/starter imports extras?
-- - Because it makes my lazy.nvim complain:
--
-- The order of your `lazy.nvim` imports is incorrect:
-- - `lazyvim.plugins` should be first
-- - followed by any `lazyvim.plugins.extras`
-- - and finally your own `plugins`
--
-- If you think you know what you're doing, you can disable this check with:
-- ```lua
-- vim.g.lazyvim_check_order = false
-- ```
if false then return {
  { import = "lazyvim.plugins.extras.lang.typescript" },
  { import = "lazyvim.plugins.extras.lang.json" },
}
end

-- -----------------------------------------------------------------
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

return {
  -- Configure LazyVim to load gruvbox
  {
    "LazyVim/LazyVim",
    opts = {
      -- colorscheme = "gruvbox",
      -- colorscheme = "default",
      colorscheme = "catppuccin-mocha",
    },
  },

  -- change trouble config
  {
    "folke/trouble.nvim",
    -- opts will be merged with the parent spec
    opts = { use_diagnostic_signs = true },
  },

  -- disable trouble
  -- { "folke/trouble.nvim", enabled = false },

  -- FIXME/2025-02-22 13:50: TRYME:
  -- use mini.starter instead of alpha
  -- { import = "lazyvim.plugins.extras.ui.mini-starter" },

  -- add jsonls and schemastore packages, and setup treesitter for json, json5 and jsonc
  -- FIXME: Presence causes order complaint:
  --  { import = "lazyvim.plugins.extras.lang.json" },

  -- add any tools you want to have installed below
  {
    "williamboman/mason.nvim",
    opts = {
      ensure_installed = {
        "stylua",
        "shellcheck",
        "shfmt",
        "flake8",
      },
    },
  },

  -- REFER:
  -- https://github.com/lewis6991/gitsigns.nvim#-keymaps
  -- CXREF:
  -- ~/.local/share/nvim/lazy/LazyVim/lua/lazyvim/plugins/editor.lua @ 124
  --
  --   {
  --     "lewis6991/gitsigns.nvim",
  --     event = "LazyFile",
  --     ...
  --   },

  {
    "nvim-mini/mini.surround",
    -- SPOKE/2025-02-28: Print out list of surround bindings.
    -- opts = function(_, opts)
    --   print("surround: " .. vim.inspect(opts))
    -- end,
  },
}
