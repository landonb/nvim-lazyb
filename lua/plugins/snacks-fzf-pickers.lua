-- vim:tw=0:ts=2:sw=2:et:ai:ft=lua
-- Author: Landon Bouma <https://tallybark.com/>
-- Project: https://github.com/landonb/nvim-lazyb#🧸

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

-- SPIKE: Investigate LazyVim FZF config:
-- /Users/puck/.local/share/nvim_lazyb/lazy/LazyVim/lua/lazyvim/plugins/extras/editor/fzf.lua

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

local alt_keys = require("util.alt2meta-keys")

local wk = require("which-key")

return {

  -- -----------------------------------------------------------------
  -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

  -- REFER: Install on Linux via OMR:
  --   mr -d ~/.kit/go/fzf install
  -- ~/.depoxy/ambers/home/.kit/go/_mrconfig
  -- - On macOS, install via Homebrew (see macOS-onboarder).

  -- USAGE:
  --   <LocalLeader>F — FZF (fzf.vim) user home
  --   <LocalLeader>ff — FZF current project
  --   <Leader>ff — Snacks picker current project
  --   <LocalLeader>dF — Snacks picker user home

  -- SAVVY: Note that \F and \dF show essentially the same
  -- files, so it's redundant, but it lets us compare the
  -- two approaches, e.g., so you can choose the one that's
  -- more performant.

  {
    dir = "~/.kit/nvim/junegunn/start/fzf.vim",
    event = "VeryLazy",

    dependencies = {
      -- :FF and \ff use :Glcd command.
      -- - MAYBE: Replace with vim.system() "git rev-parse --show-toplevel" suss.
      --   - Or with LazyVim.root() (I think it returns the same).
      { dir = "~/.kit/nvim/tpope/start/vim-fugitive" },
    },

    config = function()
      -- FIXME: Localize these files.

      -- CXREF:
      -- ~/.kit/go/fzf/plugin/fzf.vim
      pcall(function()
        vim.cmd("source " .. vim.env.HOME .. "/.kit/go/fzf/plugin/fzf.vim")
      end)

      -- CXREF:
      -- ~/.kit/nvim/DepoXy/start/vim-depoxy/plugin/fzf-config.vim
      pcall(function()
        vim.cmd(
          "source " .. vim.env.HOME .. "/.kit/nvim/DepoXy/start/vim-depoxy/plugin/fzf-config.vim"
        )
      end)

      wk.add({
        -- CALSO: <LocalLeader>F FZF picker and <LocalLeader>dF Snacks picker show
        -- (essentially) the same ~200K files.
        {
          mode = { "n" },
          "<LocalLeader>F",
          ":lcd<CR>:FZF<CR>",
          noremap = true,
          silent = true,
          desc = "FZF User Home",
          icon = "",
        },

        {
          mode = { "n" },
          -- HSTRY: This is <LocalLeader>ff ({ "n", "i" }) in nvim-depoxy.
          -- BNDNG: <Leader>f<M-f> aka \f<M-f> aka \fƒ
          "<Leader>f" .. alt_keys.lookup("f"),
          function()
            -- LOPRI: Wire LazyVim into LSP annotations so doesn't complain:
            --   Undefined field `root'.
            LazyVim.root()
            -- HSTRY: nvim-depoxy uses vim-fugitive to identify the
            -- project root:
            --   vim.cmd("Glcd")
            -- REFER: See LazyVim.root.info() for list of project
            -- root detectors (e.g., lsp, .git, lua, cwd).
            -- ALTLY:
            --   vim.cmd("lcd " .. LazyVim.root())
            --   vim.uv.chdir(LazyVim.root.get())
            --   vim.uv.chdir(LazyVim.root.git())
            -- SPIKE: vim.uv.chdir() is not sticky across focus, i.e.,
            -- if you run it, :pwd reports it, but if you move cursor
            -- to another window and then back, :pwd reports prev. cwd.
            vim.uv.chdir(LazyVim.root())
            vim.cmd("FZF")
          end,
          noremap = true,
          silent = true,
          desc = alt_keys.AltKeyDesc("FZF Project Dir.", "M-f"),
          icon = "",
        },

        -- CALSO: All the buffer pickers:
        --   <LocalLeader>dfb   — Telescope buffers
        --   __                 — Telescope buffers
        --   _-                 — FZF buffers
        --   <Leader>fb         — Snacks Picker buffers
        --   <Leader>fB         — Snacks Picker buffers, all
        {
          mode = { "n" },
          -- BNDNG: _-
          -- "_-",
          "<Leader>_-",
          "<cmd>:Buffers<CR>",
          noremap = true,
          silent = true,
          desc = "FZF buffer picker",
          icon = "",
        },
      })
    end,
  },

  -- -----------------------------------------------------------------
  -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

  -- USAGE: Re: <LocalLeader>F and <LocalLeader>dF —
  --        \F runs fzf.vim picker, \dF runs Snacks.
  --
  -- ALMST/2025-03-18: Snacks picker finds 204148 files under my user
  --    home, compared to FZF, which finds 204213 files.

  -- SAVVY: We must pass custom `rg` args, or it both finds too many
  -- matches, and it also exits nonzero (and then Snacks notifies us).
  --
  -- - Here's the basic implementation:
  --
  --     Snacks.explorer({ --- @diagnostic disable-line: missing-fields
  --       command = "files",
  --       cwd = "~",
  --       hidden = true,
  --       ignored = true,
  --       exclude = { ".DS_Store" },
  --     })
  --
  -- - The issue is that opts.ignored = true|false applies to both Git
  --   exclude files and to .ignore rules files.
  --   - But I need rg to only honor .ignore files, because I use
  --     .gitignore rules to manage nested Git repos, and so that
  --     git commands ignore nested projects.
  --   - As such, if Snacks uses my exclude rules, it'll effectively
  --     ignore *everything*.
  --     - Which is easily illustrated by my user home, which is the
  --       root of a very simple Git repo that only contains a .gitignore
  --       file. The file currently ignores all known top-level files
  --       and directories under user home. I use this setup so I can
  --       be alerted whenever something new appears at the root of
  --       user home.
  -- - Note that `rg` also exits nonzero, at least if it tries to
  --   include everything under my user home, because a few GPG files
  --   (that are normally .ignore'd) are unreadable, and there might
  --   also be some broken symlinks around (which causes `rg --files`
  --   to exit 2, though it won't print an error message; but if you
  --   call `rg` without `--files`, then it prints an error message
  --   for each broken symlink).

  {
    "folke/snacks.nvim",

    keys = {
      -- CALSO: <LocalLeader>F FZF picker and <LocalLeader>dF Snacks picker show
      -- (essentially) the same ~200K files.
      {
        -- BNDNG: <Leader>dF
        "<LocalLeader>dF",
        function()
          Snacks.picker.files({
            cwd = "~",

            -- REFER: Each 'exclude' string translates to a glob arg. pair, e.g.,
            --   rg ... -g !.DS_Store

            -- ASIDE: I had a symlink in a subdirectory to ~/.Trash,
            -- but because ACL permissions (I assume), `rg` exits 2,
            -- and I was unable to ignore the symlink.
            -- - The setup is like this, e.g.:
            --      $ ln -sfn ~/.trash ~/projects/.trash
            --      $ ls ~/projects/.trash
            --      gls: cannot open directory '.../.trash/': Operation not permitted
            -- - But neither `rg -g .trash` nor adding .trash to .ignore files worked,
            --   Snacks would finish populating results, and then it would notify that
            --   rg failed.
            --   - Anyway, I changed that symlink to use an intermediate trash, ~/.trash0,
            --     that's not under macOS control. But just FYI if you encounter an exit 2.
            --     I also didn't see anythink related to permissions or '.trash' in either
            --     227MB worth of `rg --debug` or `rg --trace` output (though maybe you
            --     would if you remove the `rg --files` option, I've seen that inhibit
            --     useful errors, like broken symlinks).

            -- FIXME: Add .DS_Store to Homefries rg alias, and retest match count (this might be diff)
            exclude = { ".DS_Store" },

            -- The default width causes all filenames to be abbreviated...with ellipses.
            formatters = { file = { truncate = 400 } },

            -- Snacks prefixes with these options:
            --   rg --files --no-messages --color never -g !.git
            cmd = "rg",
            args = {
              -- USYNC: These options and globs from FZF config, and $FZF_DEFAULT_COMMAND:
              -- ~/.kit/nvim/DepoXy/start/vim-depoxy/plugin/fzf-config.vim
              "--hidden",
              "--follow",
              "--no-ignore-vcs",
              "--no-ignore-parent",
              "--glob",
              "!**/{.git,.tox,node_modules,.crypt}/**",
              "--glob",
              "!**/{*.swp,.bash_history,*.bin,*.gif,*.gpg,*.jpg,*.Jpg,*.JPG,*.nib,*.odg,*.odt,*.pdf,*.Pdf,*.PDF,*.png,*.pyc,*.svg,.viminfo,*.xpm,*.zip,doc/tags}",

              -- USAGE: Add --debug or --trace for runtime TMI.
              -- - Though I'm not sure how useful, at least for `rg --files`
              --   command — I had an issue where `rg --files` would exit 2,
              --   which means a non-catastrophic error occurred, such as a
              --   permissions error. But I couldn't find anything in the
              --   --debug or --trace output!
              --   - I did succeed by removing --files and running a normal
              --     `rg` search command. Then it reports broken symlinks, at
              --     least.
              --   - I did see one suspect message: "rg: DEBUG|rg::haystack ...
              --     ignoring S.gpg-agent.browser: failed to pass haystack filter ...",
              --     but I think that was after I set opts.ignored = false, but
              --     before I added custom args (i.e., --no-ignore-vcs), such that
              --     `rg` was not ignoring anything. So the "haystack" message might
              --     (also) have been causing `rg` to exit 2.
              -- - REFER: From `man rg`: 2 exit status occurs when an error occurred.
              --   This is true for both catastrophic errors (e.g., a regex syntax
              --   error) and for soft errors (e.g., unable to read a file).
              --
              --   "--debug",
            },
          })
        end,
        desc = "Snacks User Home",
      },
    },
  },
}
