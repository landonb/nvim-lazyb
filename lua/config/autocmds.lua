-- vim:tw=0:ts=2:sw=2:et:ai:ft=lua
-- Author: Landon Bouma <https://tallybark.com/>
-- Project: https://github.com/landonb/nvim-lazyb#🧸

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

local wk = require("which-key")

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
    elseif
      require("util.buffer-delights.normal-buffer").IsNormalBuffer(vim.api.nvim_get_current_buf())
    then
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

-- "Disable" *Word that should start with a capital* check.
-- - DUNNO: Does't seem to be a disablement option (doc/insert.txt
--   via |spelling| doesn't mention), so disable capitalization
--   check by resetting its highlight.
-- - SPIKE: How do LazyVim and other plugins set highlights, or
--   don't they, because I don't see any |highlight| calls in
--   LazyVim sources. I also don't know of a Lua approach. Or
--   maybe they're doing it through tree-sitter or something?
--   I have no idea. =)
-- - Default: Yellow undercurl.
--     SpellCap cterm=undercurl gui=undercurl guisp=#f9e2af
-- - WRONG: Makes the undercurl gray, not yellow, but still visible:
--     vim.cmd("highlight! SpellCap guisp=None")
-- - Reset 'gui' to remove undercurl.
-- - ALTLY: If gui=None doesn't work in all circumstances, try link:
--     vim.cmd("highlight! link SpellCap Normal")
vim.cmd("highlight! SpellCap gui=None")

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

-- CXREF: Add to :: :? :L family of cmdline runners:
--   s:CreateAutocmdMapsVimFunctions()
-- ~/.kit/nvim/landonb/dubs_edit_juice/plugin/dubs_edit_juice.vim

-- DUNNO: `:checkhealth which-key` reports:
--   "WARNING Duplicates for <:I> in mode `v`".
-- - Though `vmap :I` shows just the one.

vim.api.nvim_create_autocmd("FileType", {
  group = M.group,
  pattern = { "help", "vim", "lua", "rst", "markdown", "txt" },
  callback = function()
    wk.add({
      mode = { "v" },
      ":I",
      [[:<C-U><CR>gvy:call histadd('cmd', 'I ' .. @")<CR>:I <C-R>"<CR>]],
      buffer = true,
      desc = "Inspect Selected",
      icon = "",
    })
  end,
})

-- CXREF: See :: :? :" :> :L bindings:
-- ~/.kit/nvim/landonb/nvim-lazyb/lua/config/keymaps.lua @ 633
-- ~/.kit/nvim/landonb/dubs_edit_juice/plugin/dubs_edit_juice.vim @ 1723
vim.api.nvim_create_autocmd("FileType", {
  group = M.group,
  pattern = { "help", "vim", "lua", "rst", "markdown", "txt" },
  callback = function()
    wk.add({
      mode = { "n" },
      "<LocalLeader>?",
      -- [[:<C-U><CR>gvy:call histadd('cmd', 'I ' .. @")<CR>:I <C-R>"<CR>]],
      function()
        -- SPIKE: Is there a way to restore cursor without using get_/set_cursor?
        -- - E.g., using a built-in mark? (I tried |CTRL-O| but didn't work).
        --   - REFER: |mark-motions| We could maybe use |m'| and |''|.
        -- SAVVY: Because which-key window pops up, cannot use window ID 0
        -- when calling nvim_win_set_cursor.
        --   local winid = 0
        local winid = vim.api.nvim_get_current_win()
        local curpos = vim.api.nvim_win_get_cursor(winid)
        -- Grab WORD under cursor.
        local topic = vim.fn.expand("<cWORD>")
        -- Remove |bars|, which Vim help syntax uses to reference topics.
        -- - SAVVY: I don't think Lua supports pattern branches, e.g.,
        --     local topic = cWORD:gsub("(^|\\||$)", "")
        --   - REFER: |pattern|, also https://www.lua.org/pil/20.2.html
        -- - SAVVY: gsub returns count as second arg, so cannot chain, e.g.,
        --     local topic = cWORD:gsub("^|", ""):gsub("|$", "")
        -- - We could restrict to pipes on string edges only, e.g.,
        --   |topic| but not (|topic|):
        --     topic = topic:gsub("^|", "")
        --     topic = topic:gsub("|$", "")
        --   but I don't think any help topic has literal bars (pipes) its
        --   name (e.g., see |bar| or |bars|), so picking a looser cleanup
        --   is more inclusive (and lets user put topic in parentheses or
        --   brackets, e.g., e.g., [|topic|]).
        topic = topic:gsub("^.*|(.*)|.*$", "%1")
        if topic:len() > 0 then
          -- SPIKE: Do we need to escape(topic, '"') ?
          local success = pcall(function()
            vim.cmd("help " .. topic)
          end)
          if success then
            vim.fn.histadd("cmd", "help " .. topic)
          else
            print("Sorry, no help for topic “" .. topic .. "”")
          end
        end
        -- Restore the cursor position.
        vim.api.nvim_win_set_cursor(winid, curpos)
      end,
      buffer = true,
      noremap = true,
      desc = "::help |topic|",
      icon = "",
    })
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

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

-- ISOFF: Don't disable equalalways, which I demoed to that
-- dragging/resizing the application window didn't also resize
-- special buffer windows, like the Project window, quickfix,
-- etc. But then it also doesn't resize normal windows.
-- - REFER: Instead, use |winfixwidth|/|winfixheight| to make
--   special windows play nice with |equalalways|.
--
--  vim.o.equalalways = false

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

-- Disable smartindent for specific file types.
-- - USAGE: So that you can select and <Tab> to indent
--   #-commented lines, which smartindent otherwise
--   won't budge if the "#" comment leader is in the
--   first column.
vim.api.nvim_create_autocmd({ "FileType" }, {
  group = M.group,
  pattern = { "conf" },
  callback = function()
    -- Inherently local, so this works, too:
    --   vim.opt.smartindent = false
    vim.opt_local.smartindent = false
  end,
})

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

return M
