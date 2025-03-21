-- vim:tw=0:ts=2:sw=2:et:ai:ft=lua
-- Author: Landon Bouma <https://tallybark.com/>
-- Project: https://github.com/landonb/nvim-lazyb#🧸

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

---@class lazyb.util.colorscheme
local M = {}

function M.setup()
  -- catppuccin-mocha:
  --   hi Normal guifg=#cdd6f4 guibg=#1e1e2e
  --   hi NormalNC guifg=#cdd6f4 guibg=#1e1e2e
  -- Meh: I'm used to a darker (almost black) background and lots
  -- of contrast, but I'm also kinda groovin on the more muted,
  -- grayish background that most popular color schemes seem to
  -- use. So we'll stick with catppuccin-mocha defaults for now,
  -- but here's how you can adjust the background if you want.
  if false then
    local guifg = "#cdd6f4"
    -- local guibg = "#1e1e2e"
    -- local guibg = "#060606"
    local guibg = "#0e0e0e"
    -- CPYST:
    --   hi Normal   guifg=#cdd6f4 guibg=#0e0e0e
    --   hi NormalNC guifg=#cdd6f4 guibg=#0e0e0e
    vim.cmd([[highlight Normal guifg=]] .. guifg .. [[ guibg=]] .. guibg)
    vim.cmd([[highlight NormalNC guifg=]] .. guifg .. [[ guibg=]] .. guibg)
  end

  -- VertSplit:
  -- - catppuccin-mocha: highlight WinSeparator guifg=#11111b
  -- - nvim-depoxy: hi WinSeparator link Normal
  -- - nvim: hi WinSeparator link Normal
  -- vim.cmd("highlight WinSeparator guifg=white guibg=#060606")
  -- vim.cmd("highlight WinSeparator guifg=#1e1e2e guibg=#060606")
  -- vim.cmd("highlight WinSeparator guifg=#363636 guibg=#060606")
  -- I like either a darker/black separator, or a lighter/whiter one...
  -- - We'll use the darker one, perhaps it's less distracting but
  --   still helps you identify windows individually.
  -- - Note you won't see any horizontal WinSeparator highlights
  --   unless you disable &laststatus, or set &laststatus=3 (global
  --   statusline), in which case WinSeparator paints a line of "─".
  --   (The vertical WinSeparator lines is like a column of "│".)
  -- vim.cmd("highlight WinSeparator guifg=#696969 guibg=#060606")
  -- Wider vertical line, near black:
  --   vim.cmd("highlight WinSeparator guifg=#060606 guibg=#060606")
  -- Thinner vertical line ("│" chars.), same guibg as Normal. Just
  -- a tad darker than catppuccin-mocha draws it (which is easy to
  -- see in a dark room, but not in a sunny room).
  vim.cmd("highlight WinSeparator guifg=#060606 guibg=#1e1e2e")

  -- Note that WinSeparator highlights the vertical line between
  -- windows, and there doesn't be a way to change the horizontal
  -- separators other than through the status line (lualine) config.
  -- - This changes nothing:
  --    highlight StatusLineNC guifg=#ff0000 guibg=#00ff00
  --  - REFER: StatusLine     xxx guifg=#cdd6f4 guibg=#181825
  --           StatusLineNC   xxx guifg=#45475a guibg=#181825
  -- - Also this changes nothing: hi WinBar guifg=#ff0000
  --   - REFER: WinBar guifg=#f5e0dc | WinBarNC links to WinBar
  -- MAYBE: Adjust lualine config for a more noticeable horizontal separation.

  -- FIXME: /2025-03-05: These are rst highlight tweaks.
  -- - Where's a better spot for these changes?
  --   - Or maybe it belongs here (or in catppuccin-mocha spec config()).

  -- REFER: |nvim-treesitter-highlight-mod|
  --
  -- - Though I suppose this could run on init().
  --
  -- require"nvim-treesitter.highlight".set_custom_captures {
  --   -- Highlight the @foo.bar capture group with the "Identifier" highlight group.
  --   ["foo.bar"] = "Identifier",
  -- }

  -- REFER: |treesitter-highlight-groups|
  --
  -- -- To customize the syntax highlighting of a capture, simply define or link a highlight group of the same name:
  -- -- Highlight the @foo.bar capture group with the "Identifier" highlight group
  -- vim.api.nvim_set_hl(0, "@foo.bar", { link = "Identifier" })
  -- --
  -- -- For a language-specific highlight, append the name of the language:
  -- -- Highlight @foo.bar as "Identifier" only in Lua files
  -- vim.api.nvim_set_hl(0, "@foo.bar.lua", { link = "Identifier" })

  -- @markup.heading.rst links to @markup.heading | priority: 100 | language: rst
  -- hi @markup.heading xxx cterm=bold gui=bold guifg=#89b4fa
  -- hi Title xxx cterm=bold gui=bold guifg=#89b4fa
  -- - aka :syntax rstSections
  --   - nvim-depoxy:
  --     hi rstSections xxx links to Title
  --     hi Title xxx cterm=bold ctermfg=13 gui=bold guifg=Magenta
  vim.api.nvim_set_hl(0, "@markup.heading.rst", { bold = true, fg = "Magenta" })
  -- Except if you disable Tree-sitter on rst (because its parser is very
  -- strict), then you need to use rstSections, which is default links Title,
  -- where :hi Title cterm=bold gui=bold guifg=#89b4fa — a kinda powdery blue.
  if false then
    vim.api.nvim_set_hl(0, "rstSections", { bold = true, fg = "Magenta" })
  end

  -- -- https://www.reddit.com/r/neovim/comments/16sqyjz/finally_we_can_have_highlighted_folds/
  -- local bg = vim.api.nvim_get_hl(0, { name = "StatusLine" }).bg
  -- local hl = vim.api.nvim_get_hl(0, { name = "Folded" })
  -- lua vim.inspect(vim.api.nvim_get_hl(0, { name = "Folded" }))
  -- hl.bg = bg
  -- vim.api.nvim_set_hl(0, "Folded", hl)
  -- Folded         xxx guifg=#89b4fa guibg=#45475a
  --
  --
  -- nvim-depoxy: hi Folded xxx ctermfg=14 ctermbg=242 guifg=#cccccc guibg=#333333
  --vim.api.nvim_set_hl(0, "Folded", { fg = "#cccccc", bg = "#333333" })
  --vim.api.nvim_set_hl(0, "Folded", { fg = "#cdd6f4", bg = "#1e1e2e" })
  --vim.api.nvim_set_hl(0, "Folded", { fg = "#cdd6f4", bg = "#0e0e0e" })
  -- FIXME: Adjust this, especially for Project tray.
  vim.api.nvim_set_hl(0, "Folded", { fg = "#abbbed", bg = "#181825" })

  -- hi @spell xxx cleared
  --  vim.api.nvim_set_hl(0, "@spell.rst", { fg = "#abbbed", bg = "#181825" })

  -- FIXME: SnacksPickerPathHidden is too dark to read.
  -- - In the nvim-depoxy project, there's a .config/ top-level dir,
  --   so all the lua/ files thereunder are considered hidden, and
  --   the highlight is very close to the background color.
end

return M
