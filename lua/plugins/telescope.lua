-- vim:tw=0:ts=2:sw=2:et:ai:ft=lua
-- Author: Landon Bouma <https://tallybark.com/>
-- Project: https://github.com/landonb/nvim-lazyb#🧸

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

-- COPYD: From nvim-depoxy:
-- ~/.kit/nvim/nvim-depoxy/.config/nvim/lua/specs/spec--telescope.nvim.lua

-- SPIKE: Compare against :LazyExtras editor.telescope config.

return {
  {
    -- "nvim-telescope/telescope.nvim",
    dir = "~/.kit/nvim/nvim-telescope/start/telescope.nvim",
    event = "VeryLazy",

    dependencies = {
      { dir = "~/.kit/nvim/nvim-lua/start/plenary.nvim" },
    },

    -- REFER: See default key maps:
    -- https://github.com/nvim-telescope/telescope.nvim#default-mappings

    config = function()
      local actions = require("telescope.actions")
      local builtin = require("telescope.builtin")

      local themes = {
        popup_list = {
          theme = "popup_list",
          border = true,
          preview = false,
          prompt_title = false,
          results_title = false,
          sorting_strategy = "ascending",
          layout_strategy = "center",
          borderchars = {
            prompt = { "─", "│", "─", "│", "┌", "┐", "┤", "└" },
            results = { "─", "│", "─", "│", "├", "┤", "┘", "└" },
            preview = { "─", "│", "─", "│", "┌", "┐", "┘", "└" },
          },
        },
        popup_extended = {
          theme = "popup_extended",
          prompt_title = false,
          results_title = false,
          layout_strategy = "center",
          layout_config = {
            width = 0.7,
            height = 0.3,
            mirror = true,
            preview_cutoff = 1,
          },
          borderchars = {
            prompt = { "─", "│", " ", "│", "┌", "┐", "│", "│" },
            results = { "─", "│", "─", "│", "├", "┤", "┘", "└" },
            preview = { "─", "│", "─", "│", "┌", "┐", "┘", "└" },
          },
        },
        command_pane = {
          theme = "command_pane",
          preview = false,
          prompt_title = false,
          results_title = false,
          sorting_strategy = "descending",
          layout_strategy = "bottom_pane",
          layout_config = {
            height = 13,
            preview_cutoff = 1,
            prompt_position = "bottom",
          },
        },
        ivy_plus = {
          theme = "ivy_plus",
          preview = false,
          prompt_title = false,
          results_title = false,
          layout_strategy = "bottom_pane",
          layout_config = {
            height = 13,
            preview_cutoff = 120,
            prompt_position = "bottom",
          },
          borderchars = {
            prompt = { "─", "│", "─", "│", "┌", "┐", "┘", "└" },
            results = { "─", "│", "─", "│", "┌", "┬", "┴", "└" },
            preview = { "─", "│", " ", " ", "─", "┐", "│", " " },
          },
        },
      }

      require("telescope").setup({
        defaults = {

          -- COPYD: From:
          -- https://github.com/talha-akram/anvil/blob/220e21e46154da965b0ce16b497a0d99355a7570/lua/plugins/telescope.lua#L76-L126
          border = true,
          prompt_title = false,
          results_title = false,
          color_devicons = false,
          layout_strategy = "horizontal",
          borderchars = {
            prompt = { "─", "│", "─", "│", "┌", "┐", "┘", "└" },
            results = { "─", "│", "─", "│", "┌", "┐", "┘", "└" },
            preview = { "─", "│", "─", "│", "┌", "┐", "┘", "└" },
          },
          layout_config = {
            bottom_pane = {
              height = 20,
              preview_cutoff = 120,
              prompt_position = "top",
            },
            center = {
              height = 0.4,
              preview_cutoff = 40,
              prompt_position = "top",
              width = 0.7,
            },
            horizontal = {
              prompt_position = "top",
              preview_cutoff = 40,
              height = 0.9,
              width = 0.8,
            },
          },
          sorting_strategy = "ascending",
          prompt_prefix = " ",
          selection_caret = " → ",
          entry_prefix = "   ",
          file_ignore_patterns = { "node_modules" },
          path_display = { "truncate" },
          results_title = false,
          prompt_title = false,
          preview = {
            treesitter = {
              enable = {
                "css",
                "dockerfile",
                "elixir",
                "erlang",
                "fish",
                "html",
                "http",
                "javascript",
                "json",
                "lua",
                "php",
                "python",
                "regex",
                "ruby",
                "rust",
                "scss",
                "svelte",
                "typescript",
                "vue",
                "yaml",
                "markdown",
                "bash",
                "c",
                "cmake",
                "comment",
                "cpp",
                "dart",
                "go",
                "jsdoc",
                "json5",
                "jsonc",
                "llvm",
                "make",
                "ninja",
                "prisma",
                "proto",
                "pug",
                "swift",
                "todotxt",
                "toml",
                "tsx",
              },
            },
          },

          -- Default configuration for telescope goes here:
          -- config_key = value,
          mappings = {
            i = {
              -- AUDIT/2025-02-10: Decide if you want this or not...
              -- SAVVY: With this map, cannot escape to Normal mode.
              -- - REFER: So no H|M|L, gg|G, etc.
              -- - REFER: <C-c> from Insert mode also closes Telescope.
              -- - COPYD: From:
              --  https://github.com/nvim-telescope/telescope.nvim/wiki/Configuration-Recipes#mapping-esc-to-quit-in-insert-mode
              -- ["<esc>"] = actions.close,
              --
              -- SAVVY: See i_<C-/> and n_? for help.
              -- -- map actions.which_key to <C-h> (default: <C-/>)
              -- -- actions.which_key shows the mappings for your picker,
              -- -- e.g. git_{create, delete, ...}_branch for the git_branches picker
              -- ["<C-h>"] = "which_key"
            },
          },
        },

        pickers = {
          -- Default configuration for builtin pickers goes here:
          -- picker_name = {
          --   picker_config_key = value,
          --   ...
          -- }
          -- Now the picker_config_key will be applied every time you call this
          -- builtin picker
        },

        extensions = {
          -- Your extension configuration goes here:
          -- extension_name = {
          --   extension_config_key = value,
          -- }
          -- please take a look at the readme of the extension you want to configure

          -- COPYD: From:
          -- https://github.com/nvim-telescope/telescope-fzf-native.nvim#telescope-setup-and-configuration
          -- These are the default settings.
          fzf = {
            fuzzy = true, -- false will only do exact matching
            override_generic_sorter = true, -- override the generic sorter
            override_file_sorter = true, -- override the file sorter
            case_mode = "smart_case", -- or "ignore_case" or "respect_case"
            --   the default case_mode is "smart_case"
          },

          -- COPYD: https://github.com/tsakirist/telescope-lazy.nvim#configuration
          -- REFER: https://github.com/tsakirist/telescope-lazy.nvim#mappings
          -- USAGE: Telescope lazy
          -- Type information can be loaded via 'https://github.com/folke/lazydev.nvim'
          -- by adding the below two annotations:
          ---@module "telescope._extensions.lazy"
          ---@type TelescopeLazy.Config
          lazy = {
            -- Optional theme (the extension doesn't set a default theme)
            theme = "ivy",
            -- The below configuration options are the defaults
            show_icon = true,
            mappings = {
              open_in_browser = "<C-o>",
              open_in_file_browser = "<M-b>",
              open_in_find_files = "<C-f>",
              open_in_live_grep = "<C-g>",
              open_in_terminal = "<C-t>",
              open_plugins_picker = "<C-b>",
              open_lazy_root_find_files = "<C-r>f",
              open_lazy_root_live_grep = "<C-r>g",
              change_cwd_to_plugin = "<C-c>d",
            },
            actions_opts = {
              open_in_browser = {
                auto_close = false,
              },
              change_cwd_to_plugin = {
                auto_close = false,
              },
            },
            terminal_opts = {
              relative = "editor",
              style = "minimal",
              border = "rounded",
              title = "Telescope lazy",
              title_pos = "center",
              width = 0.5,
              height = 0.5,
            },
            -- Other telescope configuration options
          },
        },
      })

      -- COPYD:
      -- https://github.com/talha-akram/anvil/blob/220e21e46154da965b0ce16b497a0d99355a7570/lua/plugins/telescope.lua

      local map = vim.keymap.set

      local use_layout = function(picker, layout)
        return function()
          picker(themes[layout])
        end
      end

      local set_keymap = function(lhs, rhs, desc)
        map("n", lhs, rhs, { noremap = true, desc = desc })
      end

      set_keymap("<LocalLeader>dft", use_layout(builtin.builtin, "popup_list"), "Telescope Builtins")

      -- BWARE/2025-02-18: May need { hidden = false, no_ignore = true }
      -- or you might not see a lot of files listed...
      --   lua require('telescope.builtin').find_files({cwd = "/Users/puck/.kit/nvim", hidden = true, no_ignore = true})
      --   Telescope find_files cwd=/Users/puck/.kit/nvim hidden=true no_ignore=true
      set_keymap(
        "<LocalLeader>dfo",
        use_layout(builtin.find_files, "popup_list"),
        "Telescope Find Files"
      )
      -- Another example:
      set_keymap("<LocalLeader>dfO", function()
        require("telescope.builtin").find_files({ cwd = require("lazy.core.config").options.root })
      end, "Find Plugin File")

      set_keymap(
        "<LocalLeader>dfb",
        use_layout(builtin.buffers, "popup_extended"),
        "Telescope Buffers"
      )
      set_keymap(
        "<LocalLeader>dfc",
        use_layout(builtin.commands, "command_pane"),
        "Telescope Commands"
      )
      set_keymap(
        "<LocalLeader>dfg",
        use_layout(builtin.git_status, "popup_extended"),
        "Telescope Git Status"
      )
      set_keymap("<LocalLeader>dfq", use_layout(builtin.quickfix, "ivy_plus"), "Telescope Quickfix")
      set_keymap("<LocalLeader>dfl", use_layout(builtin.loclist, "ivy_plus"), "Telescope Loc list")
      -- set_keymap(
      --   '<F1>',
      --   use_layout(builtin.help_tags, 'popup_extended'),
      --   "Telescope Builtins"
      -- )
      set_keymap(
        "<LocalLeader>dfh",
        use_layout(builtin.help_tags, "popup_extended"),
        "Telescope Help tags"
      )

      -- vim.keymap.set("n", "<LocalLeader>ff", builtin.find_files, { desc = "Telescope find files" })
      -- vim.keymap.set("n", "<LocalLeader>fg", builtin.live_grep, { desc = "Telescope live grep" })
      -- vim.keymap.set("n", "<LocalLeader>fb", builtin.buffers, { desc = "Telescope buffers" })
      -- vim.keymap.set("n", "<LocalLeader>fh", builtin.help_tags, { desc = "Telescope help tags" })
      -- GROUP: #vim_buffer_picker
      -- CALSO:
      --   :Buffers (junegunn/FZF)
      --   :ls<CR>:b<Space> (old Vim tip)
      --
      -- Show buffers list above preview, and use lower half of tabpage.
      -- - ALTLY: Default layout is list on th left, preview on the right,
      --   maybe ~80% of height:
      --     vim.keymap.set("n", "__", builtin.buffers, { desc = "Telescope buffers" })
      -- - ALTLY:
      --   keys = {
      --     { "__", mode = { "n" }, "<cmd>Telescope buffers<CR>", desc = "Telescope buffers" },
      --   },
      vim.keymap.set(
        "n",
        -- "__",
        "<Leader>__",
        use_layout(builtin.buffers, "popup_extended"),
        { desc = "Telescope buffers" }
      )

      local builtin = require("telescope.builtin")

      set_keymap(
        "<LocalLeader>dff",
        -- use_layout(require('telescope').extensions.live_grep_args.live_grep_args, 'popup_extended')
        use_layout(builtin.live_grep, "popup_extended"),
        "Telescope Live Grep"
      )
    end,

    keys = {
      -- add a keymap to browse plugin files
      -- stylua: ignore
      {
        -- REFER: LazyVim "Find Config File" is <LocalLeader>fc
        "<Leader>fC",
        function()
          -- -- E.g., ~/.local/share/nvim_lazyb/lazy
          -- require("telescope.builtin").find_files(
          --   { cwd = require("lazy.core.config").options.root }
          -- )
          -- REFER: |telescope.builtin.find_files()|

          -- FIXME: Ugh, this shows .git/ contents...
          --
          -- - Hhrmm, the issue is that I exclude project directories from
          --   intermediate/parent directories.
          --   - In this case, ~/.kit/nvim/.gitignore excludes all its
          --     project subdirs, because ~/.kit/nvim/ is in the
          --     ~/.kit/.git repo, and it needs to exclude all ~/.kit/**/.git
          --     projects... so how would you show an intermediate project
          --     directory in the picker? You'd have to keep ignore enabled,
          --     but somehow ignore the top-level .gitignore file...
          -- - I tried other combos on no_ignore and no_ignore_parent,
          --   didn't help.
          --
          -- - FIXME: I see two options:
          --
          --   - 1) Set search_dirs = {} and specify subdirs explicitly.
          --     - There's probably a vim.uv fcn. or related that'll
          --       return a list of sub-dirs of a path.
          --   - 2) Set find_command = fcn|table, though I think this
          --     would be more work than using search_dirs....
          require("telescope.builtin").find_files(
            -- {
            --   cwd = "~/.kit/nvim",
            --   -- find_command = fcn|table
            --   follow = false,
            --   hidden = true,
            --   no_ignore = true,
            --   no_ignore_parent = false,
            -- }
            --  Okay, this, and note the no_ignore_parent.
            --  - Telescope is all-in on .ignore, .gitignore, etc., which
            --    causes a little problem — I use .ignore files so that
            --    ripgrep doesn't generate noise, even though I often
            --    .ignore files that I work on...
            --  - In any case, this mostly works...
            --    - And it's not really my workflow, anyway.
            {
              -- ~/.kit/nvim/landonb/.ignore
              cwd = "~/.kit/nvim",
              -- cwd = "~/.kit/nvim/landonb",
              follow = false,
              hidden = true,
              no_ignore = false,
              no_ignore_parent = true,
              -- LOPRI: Both DepoXy and embrace-vim show .git/ files, but not landonb/
              -- - FIXME: Probably cp ~/.kit/nvim/landonb/.ignore → embrace-vim/, DepoXy/.
              -- - FIXME: Also get rid of embrace-vim/start/, DepoXy/start/.
              search_dirs = {
                "~/.kit/nvim/DepoXy",
                "~/.kit/nvim/embrace-vim",
                "~/.kit/nvim/landonb",
              },
            }
          )
        end,
        desc = "Find Plugin File (telescope)",
      },
    },
    -- change some options
    opts = {
      defaults = {
        layout_strategy = "horizontal",
        layout_config = { prompt_position = "top" },
        sorting_strategy = "ascending",
        winblend = 0,
      },
    },
  },

  {
    -- 'nvim-telescope/telescope-fzf-native.nvim',
    dir = "~/.kit/nvim/nvim-telescope/start/telescope-fzf-native.nvim",
    event = "VeryLazy",
    dependencies = {
      { dir = "~/.kit/nvim/nvim-telescope/start/telescope.nvim" },
    },

    build = "cmake -S. -Bbuild -DCMAKE_BUILD_TYPE=Release && "
      .. "cmake --build build --config Release",

    config = function()
      require("telescope").load_extension("fzf")
    end,
  },

  {
    -- 'tsakirist/telescope-lazy.nvim',
    dir = "~/.kit/nvim/tsakirist/telescope-lazy.nvim",
    event = "VeryLazy",
    dependencies = {
      { dir = "~/.kit/nvim/nvim-telescope/start/telescope.nvim" },
    },

    config = function()
      require("telescope").load_extension("lazy")
    end,
  },
}
