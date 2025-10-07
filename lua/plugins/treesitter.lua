-- vim:tw=0:ts=2:sw=2:et:ai:ft=lua
-- Author: Landon Bouma <https://tallybark.com/>
-- Project: https://github.com/landonb/nvim-lazyb#🧸

return {
  -- REFER: See next block instead.
  -- add more treesitter parsers
  -- {
  --   "nvim-treesitter/nvim-treesitter",
  --   opts = {
  --     ensure_installed = {
  --       "bash",
  --       "html",
  --       "javascript",
  --       "json",
  --       "lua",
  --       "markdown",
  --       "markdown_inline",
  --       "python",
  --       "query",
  --       "regex",
  --       "rst",
  --       "toml",
  --       "tsx",
  --       "typescript",
  --       "vim",
  --       "vimdoc",
  --       "yaml",
  --     },
  --   },
  -- },

  -- since `vim.tbl_deep_extend`, can only merge tables and not lists, the code above
  -- would overwrite `ensure_installed` with the new value.
  -- If you'd rather extend the default config, use the code below instead:
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      -- REFER: |TSInstallInfo| |TSInstall {lang}| |nvim-treesitter-commands|
      --   https://github.com/nvim-treesitter/nvim-treesitter
      --     https://github.com/nvim-treesitter/nvim-treesitter/blob/master/doc/nvim-treesitter.txt
      --
      --
      -- add tsx and treesitter
      -- vim.list_extend(opts.ensure_installed, {
      --   "tsx",
      --   "typescript",
      -- })
      vim.list_extend(opts.ensure_installed, {
        "bash",
        "html",
        "javascript",
        "json",
        "lua",
        "markdown",
        "markdown_inline",
        "python",
        "query",
        "regex",
        "rst",
        "toml",
        "tsx",
        "typescript",
        "vim",
        "vimdoc",
        "yaml",
      })

      -- *** Disable rst tree-sitter
      --
      -- - It flags things as errors that I don't think should be, e.g.,
      --   if you have an under- and over-lined title that's only spaces.
      --
      --   Also if you have leading whitespace before list items, TS
      --   flags the whole next block as an error and colors it funny.
      --
      -- - Tree-sitter also inhibits our custom rst syntax highlighting,
      --   e.g., FIVER highlights, #tag highlights, @host highlights, etc.

      -- Setting this to true will run `:h syntax` and tree-sitter at the same time.
      -- Set this to `true` if you depend on 'syntax' being enabled (like for indentation).
      -- Using this option may slow down your editor, and you may see some duplicate highlights.
      -- Instead of true it can also be a list of languages
      --  additional_vim_regex_highlighting = false,
      -- FIXME: 2025-03-04: Trying to enable on rst doesn't seem to do anything...
      -- - Oh contraire: |:Inspect| shows the rstXXX syntax, albeit after TS, so
      --   guessing TS is just winning the syntax battle (and Neovim never falls-back
      --   on the syntax highlight).
      --
      -- opts.highlight.additional_vim_regex_highlighting = { "rst" }

      -- Defaults: opts.highlight: { enable = true }
      --   print("opts.highlight: " .. vim.inspect(opts.highlight))
      -- opts.highlight = {
      --   enable = true,
      --   custom_captures = {
      --     -- Highlight the @foo.bar capture group with the "Identifier" highlight group.
      --     ["foo.bar"] = "Identifier",
      --   },
      --   disable = { "rst" },
      --   -- Setting this to true or a list of languages will run `:h syntax` and tree-sitter at the same time.
      --   additional_vim_regex_highlighting = false,
      -- }

      opts.highlight.disable = { "rst" }

      -- print("opts.highlight: " .. vim.inspect(opts.highlight))

      -- FIXME/2025-03-04 19:25: Verify this return is necessary,
      -- and audit other opts() uses, because I keep forgetting these...
      return opts
    end,
  },
}
