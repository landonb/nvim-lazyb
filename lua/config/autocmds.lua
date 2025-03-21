-- Autocmds are automatically loaded on the VeryLazy event
--   ~/.local/share/nvim/lazy/LazyVim/lua/lazyvim/config/init.lua
-- REFER: Default autocmds that are always set:
--   https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
-- CXREF:
--   ~/.local/share/nvim_lazyb/lazy/LazyVim/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which
-- is prefixed with `lazyvim_` for the defaults), e.g.:
--   vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

-- NTRST/2025-03-01: Without @field def'n, diagnostic "Duplicate field `use_normal_mode_in_snacks_picker_list`. [duplicate-set-field]" reported.
---@class lazyb.config.autocmds
---@field use_normal_mode_in_snacks_picker_list function()
local M = {}

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

-- E.g.: M.group = vim.api.nvim_create_augroup("lazyb_autocmds", { clear = true })

M.group = require("util").augroup("autocmds")

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

-- FTREQ/2025-03-01: Submit PR.
-- - UCASE: From Insert mode in file buffer window, *click* in Snacks Explorer
--   window, then double-click to open file doesn't work.
-- - SPIKE: Each of the three if-else branches below works similarly.
function M.use_normal_mode_in_snacks_picker_list()
  if true then
    local group = vim.api.nvim_create_augroup("snacks_lazyb", { clear = true })
    vim.api.nvim_create_autocmd({ "FileType" }, {
      group = group,
      pattern = "snacks_picker_list",
      callback = function()
        vim.api.nvim_create_autocmd({ "BufEnter" }, {
          buffer = vim.api.nvim_get_current_buf(),
          command = "stopinsert",
        })
      end,
    })
  elseif true then
    -- ALTLY: This also works:
    vim.cmd([[
      augroup snacks_lazyb
        autocmd!
        autocmd FileType snacks_picker_list autocmd BufEnter <buffer> stopinsert
      augroup END
    ]])
  else
    -- ALTLY: Or this:
    vim.cmd([[
      augroup snacks_lazyb
        autocmd!
        autocmd FileType snacks_picker_list lua vim.api.nvim_create_autocmd(
          \ "BufEnter", { buffer = vim.api.nvim_get_current_buf(), command = "stopinsert" })
      augroup END
    ]])
  end
end

M.use_normal_mode_in_snacks_picker_list()

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

-- Disable relative line numbers for matching FileType (rst),
-- otherwise enable relative line numbers unless special buffer.
--
-- - CALSO: LazyVim <leader>uL toggle.
--
-- FEATR: I added vim.b.relativenumber for stickiness,
-- but you can only set it manually, e.g.,
--
--   vim.b.relativenumber = false
--
-- - Ideally, it'd be wired to the Snacks toggle:
--     Snacks.toggle.option("relativenumber", { name =
--       "Relative Number" }):map("<leader>uL")
--   But it's not worth the time to implement this further.
vim.api.nvim_create_autocmd("BufEnter", {
  group = M.group,
  -- Called on every file type so we can check for specialness.
  --   pattern = { "rst" },
  callback = function()
    -- - Note vim.o.filetype and vim.bo.filetype are the same.
    -- - Note you can set custom vim.b.relativenumber,
    --   but accessing vim.bo.relativenumber is an error
    --   (that tells you to use vim.wo.relativenumber instead).
    if vim.b.relativenumber ~= nil then
      vim.wo.relativenumber = vim.b.relativenumber
    elseif vim.bo.filetype == "rst" then
      vim.wo.relativenumber = false
    elseif require("util.buffer-delights.normal-buffer").IsNormalBuffer(vim.fn.bufnr()) then
      -- Default to showing relative line numbers, but only if
      -- a normal buffer (e.g., don't start showing lines numbers
      -- in Snacks Explorer, or a help window, etc.).
      vim.wo.relativenumber = true
    end
  end,
})

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

-- (lb) Copied from Vim sources.
--
-- - This restores the older Vim rst.vim literal block behavior, which
--   recognizes a literal block starting on the line immediately after
--   the `::`, e.g.,
--
--      This used to be valid literal block syntax::
--        foo bar
--
--    This was changed recently (I assume to match that actual reST
--    spec) to require an intermediate blank line, e.g.,
--
--      This is what valid literal block syntax looks like::
--
--        foo bar
--
-- - Use case: I use reST highlighting almost exclusively in Vim,
--   for notes. And while the *correct* (with blank line) syntax
--   looks nicer (yay for empty space!), sometimes I (ab)use the
--   feature when I'm trying to keep notes tighter (fewer lines)
--   or when trying to group related notes more... note-iceably.

-- (lb): This is the former definition, from 2018-12-29, which I prefer for notes:
--
--  syn region  rstLiteralBlock         matchgroup=rstDelimiter
--       \ start='::\_s*\n\ze\z(\s\+\)' skip='^$' end='^\z1\@!'
--       \ contains=@NoSpell
--
-- This is the latest definition, from 2020-03-31 (same in Neovim v0.11.0-dev):
--
--  syn region  rstLiteralBlock         matchgroup=rstDelimiter
--        \ start='\(^\z(\s*\).*\)\@<=::\n\s*\n' skip='^\s*$' end='^\(\z1\s\+\)\@!'
--        \ contains=@NoSpell
--
-- Our adjustment is a combination of both (update 'skip' so that a line
-- of only whitespace, but with fewer characters than the literal block
-- indent, does not break the block).
--
-- CXREF:
-- /opt/homebrew/Cellar/neovim/HEAD-228fe50_1/share/nvim/runtime/syntax/rst.vim

-- vim.cmd([[
--   augroup rst_literal_block
--     autocmd!
--     autocmd FileType rst syn region rstLiteralBlock matchgroup=rstDelimiter
--       \ start='::\_s*\n\ze\z(\s\+\)' skip='^\s*$' end='^\z1\@!'
--       \ contains=@NoSpell
--   augroup END
-- ]])
vim.api.nvim_create_autocmd("FileType", {
  group = M.group,
  pattern = { "rst" },
  callback = function()
    vim.cmd([[
      syn region rstLiteralBlock matchgroup=rstDelimiter
        \ start='::\_s*\n\ze\z(\s\+\)' skip='^\s*$' end='^\z1\@!'
        \ contains=@NoSpell
    ]])
  end,
})

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

-- CXREF: Add rst to LazyVim spell filetypes:
--   ~/.local/share/nvim_lazyb/lazy/LazyVim/lua/lazyvim/config/autocmds.lua
-- SAVVY: Note that &spell is local to a window, so `set spell` only
--   enables &spell on the current window, and `setlocal spell` only
--   enables &spell on the current buffer. (This seems like basic
--   knowledge, but I tried `vim.bo.spell = true` which doesn't work;
--   you want to use `vim.opt_local.spell = true` instead;
--                 (and not `vim.wo.spell = true`) — just saying,
--     I'm fairly new to Neovim and still learning the ropes.)
vim.api.nvim_create_autocmd("FileType", {
  -- USYNC: Use the same LazyVim group to replace its autocmd:
  --   ~/.local/share/nvim_lazyb/lazy/LazyVim/lua/lazyvim/config/autocmds.lua @ 99
  group = vim.api.nvim_create_augroup("lazyvim_" .. "wrap_spell", { clear = true }),
  -- USYNC: Use the same pattern as LazyVim, plus "rst":
  pattern = { "text", "plaintex", "typst", "gitcommit", "markdown", "rst" },
  callback = function()
    vim.opt_local.wrap = true
    vim.opt_local.spell = true
  end,
})

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

-- SAVVY: "Smart tabs" — for tabbed file, insert <Tab>s before first
-- non-whitespace character, then use <Space>s after that character.
-- - CXREF:
--   ~/.kit/nvim/landonb/dubs_edit_juice/plugin/smart-tabs.vim
-- FIXME: Localize this file.
pcall(function()
  -- We'll wire the `imap <Tab>` ourselves, because blink.cmp (snippets).
  vim.g.ctab_disable_tab_maps = true
  vim.cmd("source " .. vim.env.HOME .. "/.kit/nvim/landonb/dubs_edit_juice/plugin/smart-tabs.vim")
end)

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

-- CXREF:
-- ~/.kit/nvim/landonb/dubs_ftype_mess/plugin/dubs_ftype_mess.vim

-- DUNNO: Docs suggest you need to glob, e.g., "*.vim", which
-- seems odd b/c classic Vim `au FileType` takes actual &filetype,
-- e.g., "vim". But glob doesn't work; &filetype works.

-- TRACK/2025-03-11: I thought I saw this setting not apply to help files.
-- - E.g., `I vim.bo.iskeyword` printed '!-~,^*,^|,^",192-255'.
-- - But now I cannot reproduce it.
--   - Perhaps there's a competing autocmd?
vim.api.nvim_create_autocmd("FileType", {
  group = M.group,
  pattern = {
    -- 2017-12-06: Surprised I hadn't been bothered by the octothorpe
    -- being included in '*' and <F1> searches...
    --  autocmd Filetype vim setlocal iskeyword=@,48-57,_,192-255,#
    "vim",
    -- So that <C-]> and `*` work better in (Neo)Vim help.
    -- - Default:
    --     " echom &iskeyword
    --     !-~,^*,^|,^",192-255
    -- - Including dash, which is valid help keyword char, e.g.,
    --     |expr-option-function|
    --   - TRACK: I assume dash'll be fine for ft=vim, too, and
    --     that we don't need to split this autocmd.
    "help",
  },
  callback = function()
    vim.bo.iskeyword = "@,-,48-57,_,192-255"
  end,
})

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

vim.api.nvim_create_autocmd("FileType", {
  group = M.group,
  pattern = { "qf" },
  callback = function()
    -- 2016.01.27: Avoid distracting spell check, esp. when search results is code.
    vim.opt_local.spell = false
    -- 2025-03-13: When you double-click a result near the edges and
    -- &scrolloff is set, the window scrolls and the double-click ignored.
    -- - Especially annoying when Quickfix height it minimal and all but
    --   middle line causes scrolling!
    -- DUNNO: What's diff. btw. vim.wo.scrolloff and vim.opt_local.scrolloff?
    -- - Note these each print the last set scrolloff from that window:
    --     echo &scrolloff
    --     I vim.wo.scrolloff
    --     I vim.opt_local.scrolloff:get()
    --   I.e., they print the last X from this command that was run in
    --   the window:
    --     set scrolloff=X
    --     lua vim.wo.scrolloff = X
    --     lua vim.opt_local.scrolloff = X
    --   DUNNO: Though when I open a new buffer in a window after setting
    --   vim.wo.scrolloff, it assumes the global `&scrolloff` value (so
    --   what's vim.wo.scrolloff do if not apply in that situation?).
    --   - But if I set vim.wo.scrolloff on a buffer and then open that
    --     buffer in another window, it keeps that scrolloff value...
    --     it feels like vim.wo.scrolloff and vim.opt_local.scrolloff
    --     are the same.
    vim.opt_local.scrolloff = 0
  end,
})

-- MAYBE: When dragging/resizing the application window, this
-- avoids special buffers, like the Project window, quickfix,
-- etc., resizing equal in size to the other windows.
-- - REFER: Use |winfixwidth|/|winfixheight| to make special
--   windows play nice with |equalalways|.
--
--   vim.o.equalalways = false

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

return M
