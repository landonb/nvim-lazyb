-- vim:tw=0:ts=2:sw=2:et:ai:ft=lua
-- Author: Landon Bouma <https://tallybark.com/>
-- Project: https://github.com/landonb/nvim-lazyb#🧸

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

-- CXREF: See LSP-related keybindings, e.g., Signature Help via `K` or <C-k>:
-- ~/.local/share/nvim_lazyb/lazy/LazyVim/lua/lazyvim/plugins/lsp/keymaps.lua

if true then
  return {
    -- add pyright to lspconfig
    -- {
    --   "neovim/nvim-lspconfig",
    --   ---@class PluginLspOpts
    --   opts = {
    --     ---@type lspconfig.options
    --     servers = {
    --       -- pyright will be automatically installed with mason and loaded with lspconfig
    --       pyright = {},
    --     },
    --   },
    -- },

    -- - REFER: Unmaintained:
    --    https://github.com/jose-elias-alvarez/typescript.nvim
    --    https://github.com/jose-elias-alvarez/typescript.nvim/issues/80
    -- - REFER: Lua typescript-language-server replacement, talks to tsserver:
    --    https://github.com/pmizio/typescript-tools.nvim
    --    "❗️ IMPORTANT: As mentioned earlier, this plugin serves as a replacement
    --    for typescript-language-server, so you should remove the nvim-lspconfig
    --    setup for it."
    {
      "pmizio/typescript-tools.nvim",
      dependencies = { "nvim-lua/plenary.nvim", "neovim/nvim-lspconfig" },
      opts = {},
    },

    -- add tsserver and setup with typescript.nvim instead of lspconfig
    {
      "neovim/nvim-lspconfig",
      -- dependencies = {
      --   "jose-elias-alvarez/typescript.nvim",
      --   init = function()
      --     require("lazyvim.util").lsp.on_attach(function(_, buffer)
      --       -- stylua: ignore
      --       vim.keymap.set(
      --         "n",
      --         "<leader>co",
      --         "TypescriptOrganizeImports",
      --         { buffer = buffer, desc = "Organize Imports" }
      --       )
      --       vim.keymap.set(
      --         "n",
      --         "<leader>cR",
      --         "TypescriptRenameFile",
      --         { desc = "Rename File", buffer = buffer }
      --       )
      --     end)
      --   end,
      -- },
      dependencies = {
        "pmizio/typescript-tools.nvim",
        init = function()
          -- You'll see a diagnostic error:
          --   "Undefined field `lsp`."
          -- If you use require:
          --   require("lazyvim.util").lsp.on_attach(function(_, buffer)
          --     ...
          -- But not if you use the _G.LazyVim variable that's registered
          -- with folke/lazydev.nvim — CXREF:
          --   ~/.local/share/nvim_lazyb/lazy/LazyVim/lua/lazyvim/plugins/coding.lua
          -- REFER: :LazyDev
          -- FIXME: Why doesn't this work as expected? Still a diagnostic.
          -- - FIXME: Restart nvim, that could be it...
          LazyVim.lsp.on_attach(function(_, buffer)
            -- stylua: ignore
            -- REFER: TSToolsOrganizeImports removes unused
            -- - CALSO: TSToolsSortImports
            --          TSToolsRemoveUnusedImports
            --          TSToolsRemoveUnused
            --          TSToolsAddMissingImports
            vim.keymap.set(
              "n",
              "<leader>co",
              "TSToolsOrganizeImports",
              { buffer = buffer, desc = "Organize Imports" }
            )
            -- REFER: allow to rename current file and apply changes to connected files
            -- stylua: ignore
            vim.keymap.set(
              "n",
              "<leader>cR",
              "TSToolsRenameFile",
              { desc = "Rename File", buffer = buffer }
            )
            -- REFER: Other commands:
            --  TSToolsFixAll -- fixes all fixable errors
            --  TSToolsGoToSourceDefinition -- FIXME: Isn't this wired by default?
            --  TSToolsFileReferences -- find files that ref curr file
          end)
        end,
      },
      ---@class PluginLspOpts
      opts = {
        -- SPIKE: Why does this cause diagnostics?:
        -- ---@type lspconfig.options
        servers = {
          -- pyright will be automatically installed with mason and loaded with lspconfig
          pyright = {},
          -- tsserver will be automatically installed with mason and loaded with lspconfig
          tsserver = {},
          -- FIXME/2025-02-22 17:27:
          --  copilot-language-server
          --  isort
          --  pydocstyle
          --  pyflakes
          --  yamlls = {}, -- yaml-language-server
          --  yamlfix
          --  yamllint
          -- FIXME/2025-02-22 17:32:
          -- - Add Mason DAPs:
          --   chrome-debug-adapter
          --   firefox-debug-adapter
          --   debugpy
        },
        -- you can do any additional lsp server setup here
        -- return true if you don't want this server to be setup with lspconfig
        ---@type table<string, fun(server:string, opts:_.lspconfig.options):boolean?>
        setup = {
          -- example to setup with typescript.nvim
          -- tsserver = function(_, opts)
          --   require("typescript").setup({ server = opts })
          --   return true
          -- end,
          tsserver = function(_, opts)
            require("typescript-tools").setup({ server = opts })
            return true
          end,
          -- Specify * to use this function as a fallback for any server
          -- ["*"] = function(server, opts) end,
        },
      },
    },
  }
end

  -- for typescript, LazyVim also includes extra specs to properly setup lspconfig,
  -- treesitter, mason and typescript.nvim. So instead of the above, you can use:
  -- FIXME: Presence causes order complaint:
  --  { import = "lazyvim.plugins.extras.lang.typescript" },

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

-- FIXME: 2025-03-04: Typing `hs.` in DXC config
-- brings shows all the Hammerspoon functions in
-- the completion dropdown.
--     ~/.depoxy/stints/2417/home/.hammerspoon/client-hs.lua
-- - But it doesn't work from the DXY config.
--     ~/.depoxy/ambers/home/.hammerspoon/init.lua
-- - They have matching .luarc.json files:
--     ~/.depoxy/stints/2417/.luarc.json
--     ~/.depoxy/ambers/.luarc.json
-- - Interestingly, in the DXY config, if you type
--     hs.loadSpoon()
--   you'll see the function signature.
--
-- FIXED/2025-03-04: It looks like Hammyspoony symbols are recongized.
-- - E.g., FrillsAlacrittyAndTerminal:alacritty_by_window_number_prefix
--   was previously flagged as an undefined field; but now <Ctrl-K> shows
--   its signature.
-- - CXREF: I added additional paths to DXC's JSON:
--     ~/.depoxy/stints/2417/.luarc.json
--   which didn't help at first, but eventually it did (it didn't seem
--   to work immediately after luals rescanned the project, but eventually,
--   after a few Neovim restarts, the signature started working... so not
--   really sure what ultimately fixed it).

-- stylua: ignore
if true then return {} end

-- Before I added the .luarc.json files, I tried editing the LazyVim table
-- directly, but it didn't work...
-- - CXREF:
--   ~/.local/share/nvim_lazyb/lazy/LazyVim/lua/lazyvim/plugins/lsp/init.lua
--
-- - BEGET: I searched GitHub for "EmmyLua.spoon/annotations" rather than reading more
--   docs, which is where I copied the following config from (which didn't work).
--     https://github.com/search?q=EmmyLua.spoon%2Fannotations&type=code
--   - But going through more GH results, I saw people using .luarc.json files,
--     which I emulated, and fortunately, it just worked.
--   - There are also GH results for .neoconf.json files (folke's plugin),
--     but that didn't work for me (though I didn't check the LazyVim
--     neoconf config, either; I got .luarc.json working soon after; so
--     neoconf might still be an approach we could use).
--
-- - Here's the config I copied from some project I found on GH that didn't work
--   (note its "settings.Lua.workspace.library" key", which is similar to the
--   "Lua.workspace.library" key you'll find in the .luarc.json files).
--   - COPYD:
--     https://github.com/sanchay9/nvim/blob/fc43f30eca90/lua/plugins/lspconfig.lua#L317
--
--    ...
--         -- LSP Server Settings
--         ---@type lspconfig.options
--         servers = {
--           lua_ls = {
--             -- mason = false, -- set to false if you don't want this server to be installed with mason
--             -- Use this to add any additional keymaps
--             -- for specific lsp servers
--             -- ---@type LazyKeysSpec[]
--             -- keys = {},
--             settings = {
--               Lua = {
--                 workspace = {
--                   checkThirdParty = false,
--
--                   -- FIXME/2025-03-03 22:11: For Hammerspoon...
--                   library = {
--                     -- /opt/homebrew/Cellar/neovim/HEAD-228fe50_1/share/nvim/runtime
--                     [vim.fn.expand("$VIMRUNTIME/lua")] = true,
--                     [vim.fn.expand("$VIMRUNTIME/lua/vim/lsp")] = true,
--                     -- ~/.config/nvim_lazyb
--                     -- [vim.fn.stdpath("config") .. "/meta"] = true,
--                     -- ~/.local/share/nvim_lazyb
--                     [vim.fn.stdpath("data") .. "/lazy/lazy.nvim/lua/lazy"] = true,
--                     [vim.fn.expand("$HOME/.kit/mOS/hammerspoons/Source/EmmyLua.spoon/annotations")] = true,
--                     -- ["${3rd}/luv/library"] = true,
--                   },
--                 },
--                 codeLens = {
--                  ...

return {
  -- lspconfig
  {
    "neovim/nvim-lspconfig",
    --config = function(_, opts)
    opts = function(_, opts)
      local Util = require("neoconf.util")

      --print("before " .. vim.inspect(opts))

      -- **      -- ***

      -- opts.settings = Util.merge({
      --   Lua = {
      --     workspace = {
      --       -- checkThirdParty = true,
      --       library = {},
      --     },
      --   },
      -- }, opts.settings)
      --
      -- if false then
      --   vim.list_extend(
      --     opts.settings.Lua.workspace.library,
      --     { vim.env.HOME .. "/.kit/mOS/hammerspoons/Source/EmmyLua.spoon/annotations" }
      --   )
      -- elseif false then
      --   vim.list_extend(
      --     opts.settings.Lua.workspace.library,
      --     { [vim.env.HOME .. "/.kit/mOS/hammerspoons/Source/EmmyLua.spoon/annotations"] = true }
      --   )
      -- else
      --   opts.settings.Lua.workspace.library[vim.env.HOME .. "/.kit/mOS/hammerspoons/Source/EmmyLua.spoon/annotations"] =
      --     true
      -- end

      -- ***

      opts.servers.lua_ls.settings = Util.merge({
        Lua = {
          workspace = {
            -- Defaults: checkThirdParty = false,
            --   checkThirdParty = true,
            -- - I think false avoids prompt, "Do you need to configure your work environment as ..."
            library = {},
          },
        },
      }, opts.servers.lua_ls.settings)

      if true then
        vim.list_extend(
          opts.servers.lua_ls.settings.Lua.workspace.library,
          { vim.env.HOME .. "/.kit/mOS/hammerspoons/Source/EmmyLua.spoon/annotations" }
        )
      elseif false then
        vim.list_extend(
          opts.servers.lua_ls.settings.Lua.workspace.library,
          { [vim.env.HOME .. "/.kit/mOS/hammerspoons/Source/EmmyLua.spoon/annotations"] = true }
        )
      else
        opts.servers.lua_ls.settings.Lua.workspace.library[vim.env.HOME .. "/.kit/mOS/hammerspoons/Source/EmmyLua.spoon/annotations"] =
          true
      end

      -- library[vim.fn.expand('$HOME/.hammerspoon/Spoons/EmmyLua.spoon/annotations')] = true

      -- ***

      print("after " .. vim.inspect(opts))

      return opts
    end,
  },
}
