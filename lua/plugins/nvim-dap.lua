-- vim:tw=0:ts=2:sw=2:et:ai:ft=lua
-- Author: Landon Bouma <https://tallybark.com/>
-- Project: https://github.com/landonb/nvim-lazyb#🧸

-- ISOFF: This is an incomplete nvim-dap setup.
-- - I was trying (hoping) to debug C code (tig), but
--   I don't see symbols, only machine instructions.
-- - And it should work, because VS Code shows symbols
--   while I step code using the same build.
--   - Oh, well... I need to start using windsurf, anyway,
--     and hop on that AI train (before it runs me over =).
-- - So this *sorta* works, but not quite.
-- - Also note that, at least for tig, you need to 'attach'
--   to the process. If you try to launch it from nvim, or
--   to launch a new terminal, then tig fails to get I/O
--   handles.
--   - But while VS Code automatically attaches (you don't
--     even need to specify the PID), here you have to select
--     the PID from a list.
--
-- stylua: ignore
if true then return {} end

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

-- CXREF:
-- ~/.local/share/nvim_lazyb/lazy/LazyVim/lua/lazyvim/plugins/util.lua @ 38

return {
  {
    "mfussenegger/nvim-dap",
    -- optional = true,
    -- dependencies = {
    --   -- Ensure C/C++ debugger is installed
    --   "mason-org/mason.nvim",
    --   optional = true,
    --   opts = { ensure_installed = { "codelldb" } },
    -- },
    opts = function()
      -- DUNNO: LazyVim opts() also runs...
      --  print("nvim-lazyb nvim-dap")
      local dap = require("dap")
      if not dap.adapters["codelldb"] then
        require("dap").adapters["codelldb"] = {
          type = "server",
          -- host = "localhost",
          host = "127.0.0.1",
          port = "${port}",
          executable = {
            command = "codelldb",
            args = {
              "--port",
              "${port}",
            },
          },
        }
      end
      for _, lang in ipairs({ "c", "cpp" }) do
        dap.configurations[lang] = {
          {
            type = "codelldb",
            request = "launch",
            name = "Launch file",
            program = function()
              return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
            end,
            cwd = "${workspaceFolder}",
          },
          {
            type = "codelldb",
            request = "attach",
            name = "Attach to process",
            pid = require("dap.utils").pick_process,
            cwd = "${workspaceFolder}",
          },
          -- LB:
          {
            type = "codelldb",
            --type = "lldb",
            request = "launch",
            name = "Launch tig",
            program = "/Users/puck/.kit/git/tig/src/tig",
            cwd = "/Users/puck/.kit/git/tig",
            -- MAYBE?:
            --relativePathBase = "/Users/user/.kit/git/tig/src",
            -- stopOnEntry = true,
            --runInTerminal = true,
            -- terminal = "integrated",
            --stdio = "/dev/ttys003",
            --stdio = nil,
            --stopOnEntry = true,
          },
        }
      end

      -- local dap = require("dap")
      -- print("dap:", dap)
      dap.defaults.fallback.external_terminal = {
        command = "/opt/homebrew/bin/alacritty",
        args = { "-e" },
        -- :help dap.set_log_level
        -- Terminal exited 1 running
        --   /opt/homebrew/bin/alacritty -e --hold --working-directory /Users/user/.kit/git/tig /Users/user/.local/share/nvim_lazyb/mason/packages/codelldb/extension/adapter/codelldb terminal-agent --connect=54346
        -- args = { "-e", "--hold", "--working-directory", "/Users/user/.kit/git/tig" },
        -- args = { "-e", "--hold" },
        --
        -- https://stackoverflow.com/questions/15600684/debugging-fopen-in-c
        -- https://github.com/microsoft/vscode-cpptools/issues/3351
      }
      --
      dap.defaults.fallback.force_external_terminal = true

      -- dap.defaults.fallback.terminal_win_cmd = "50vsplit new"

      -- CXREF:
      -- ~/.cache/nvim_lazyb/dap.log
      -- print("dap.log:", vim.fn.stdpath("cache"))
      dap.set_log_level("TRACE")

      -- https://stackoverflow.com/questions/74622676/check-if-mac-executable-has-debug-info
      -- https://github.com/mfussenegger/nvim-dap/discussions/1146
      -- https://github.com/mfussenegger/nvim-dap/wiki/Troubleshooting
      -- dsymutil -s src/tig
      -- dsymutil --dump-debug-map src/tig
      -- dsymutil --statistics src/tig
      -- dwarfdump --debug-info src/tig
      -- otool -hv src/tig
      --
      -- *lldb-vscode showing assembly instructions*
      -- https://github.com/mfussenegger/nvim-dap/discussions/600
    end,
  },
}
