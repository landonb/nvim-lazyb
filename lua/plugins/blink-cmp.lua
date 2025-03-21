-- vim:tw=0:ts=2:sw=2:et:ai:ft=lua
-- Author: Landon Bouma <https://tallybark.com/>
-- Project: https://github.com/landonb/nvim-lazyb#🧸

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

local alt_keys = require("util.alt2meta-keys")

---@class lazyb.plugins.blink-cmp
local M = {}

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

-- REFER: Run `BlinkCmp status` to view sources.

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

-- MAYBE/2025-03-04: Use different providers based on context:
--   https://cmp.saghen.dev/recipes.html#dynamically-picking-providers-by-treesitter-node-filetype
-- - LOPRI: I don't know the LSP wiring well enough yet
--   to know how best to configure sources.

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

-- MAYBE/INERT: Would you want to delay completion popup, e.g., while
-- writing comments, so that completion isn't constantly popping up?
--
-- - THOTS/2025-03-24: I'm curious if I can make the completion menu less
--   distracting, although I admit I've been getting used to it popping up
--   and updating while I type (which surprises me, as I've typically for
--   years/decades now never really enjoyed completion menus; though maybe
--   that's leftover bias from when they were slow to update and klunky
--   to work with, or poorly mapped/integrated into my environment/distro).
--
-- - TRACK: Previously, after typing a word, if I backspaced, the completion
--   menu would stay open, and it would updates on each <BS>. But I no longer
--   see that behavior, at least not once the cursor backspaces after a non-
--   trigger character. ("Phew!", I'll say; though I'm not exactly certain
--   what I did to fix the issue.)
--   - THOTS: Meh. I don't mind completion remaining on backspace so much,
--     especially now that backspacing to whitespace hides completion (i.e.,
--     completion doesn't normal appear until at least one visible character
--     is inserted, and now it works like that in reverse).

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

-- Define a globally-accessible blink.cmp enablement toggle.
-- - ALTLY: This bool is defined as a global so other nvim-lazyb
--   components can disable it. But it's currently only used locally,
--   in which case we could also just define this locally:
--     local M = {}
--     M.blink_cmp_enabled = true
--   And even as a local, we could still access it via require:
--     require("plugins.blink-cmp").blink_cmp_enabled = true|false
--   - MAYBE: I sorta like the require() approach. So change it?
-- - REFER: The approach we use here is recommended by the nvim-cmp
--   author, as there's no built-in blink.cmp nor nvim-cmp function
--   for toggling (and I'm proud to say I figured this out on my own
--   first before finding this link! So maybe I'm grokking the nvim
--   landscape pretty well after all, despite some of my doubts =):
--     https://github.com/hrsh7th/nvim-cmp/issues/261#issuecomment-929790943
-- - USERS: Note the seven-of-spines plugin uses timer_start to hide
--   the completion menu retroactively (very much a kludge):
--   ~/.kit/nvim/landonb/vim-ovm-seven-of-spines/plugin/vim_ovm_seven_of_spines.vim

vim.g.blink_cmp_enabled = true

-- FTREQ: Add buffer-local completion toggle.
-- - Use two maps: <leader>uk and <leader>uK
-- - SPIKE: How is `vim.b.cmpXXX = false|true` different than fcn()?:
--     vim.api.nvim_buf_set_var(0, "cmpXXX", false|true)
--   Other than the former only works for the current buffer
--   (well, unless you use `vim.b[bufnr].cmpXXX = false|true`).

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

-- This fcn. helps determine whether to show completion when entering Insert mode.
-- - You'll find it wired via opts below:
--     opts.completion = { menu = { auto_show = M.auto_show_except_after_lua_comment } }
-- - See also check_triggers_timeout(), which is called via cancel_and_debounce on arrow
--   movement (<Up>/<Left>/<Right>/<Down/) to retroactively hide completion (which
--   continues to show completion for previous cursor position), and similarly checks
--   if the cursor is after Lua comment "--", but also needs to check if the cursor
--   is after a space, etc.).

M.auto_show_except_after_lua_comment = function(ctx)
  local before_curs = M.get_chars_before_cursor(2)

  -- MAYBE: Check ft=lua.
  if before_curs == "--" then
    return false
  end

  return true
end

-- ISOFF/ALTLY: Here's an alternative auto_show that hides completion when
-- cursor is in comments — though because the author *occasionally* uses
-- completion from the buffer words source when writing comments, I prefer
-- the enabled auto_show above that only avoids completion after "--".
-- - You could try this function by wiring it below, e.g.:
--     opts.completion = { menu = { auto_show = M.auto_show_except_within_comments } }
--
-- THANX: @DeidaraMC via *Disable when in a comment?*
-- https://github.com/Saghen/blink.cmp/discussions/564#discussioncomment-12024223
-- - CALSO: *Dynamically picking providers by treesitter node/filetype*
--   https://cmp.saghen.dev/recipes#dynamically-picking-providers-by-treesitter-node-filetype
-- - CPYST: Get a node via cmdline: (And then, e.g., "lua print(node:<TAB>" shows completion):
--     lua suc, node = pcall(vim.treesitter.get_node, { pos = { 95 - 1, math.max(0, 0 - 1) }, ignore_injections = false, })
--   - DUNNO: Tree-sitter docs show a "text" attribute but returns nil.
--     https://tree-sitter.github.io/py-tree-sitter/classes/tree_sitter.Node.html#tree_sitter.Node.text
--     - I was curious if I could use node instead of vim.fn.getline(".")
-- ISOFF: We use a scalpel to just not auto-show after Lua "--" comment.
-- - But this works if you want to disable completion for all comments,
--   or for any other tree-sitter node type.
M.auto_show_except_within_comments = function(ctx)
  local row, column = unpack(vim.api.nvim_win_get_cursor(0))
  local success, node = pcall(vim.treesitter.get_node, {
    pos = { row - 1, math.max(0, column - 1) },
    ignore_injections = false,
  })
  local reject = {
    "comment",
    "comment_content",
    -- CALSO:
    --   "line_comment",
    --   "block_comment",
    --   "string_start",
    --   "string_content",
    --   "string_end",
  }
  -- stylua: ignore
  -- print(success, "/", vim.tbl_contains(reject, node and node:type() or ""),
  --   "/", "node:", node and node:type() or "", "/", node)
  if success and node and vim.tbl_contains(reject, node:type()) then
    return false
  end

  return true
end

M.auto_show_except_when = function(ctx)
  -- MAYBE/INERT: Make behavior runtime-toggleable.
  if true then
    return M.auto_show_except_after_lua_comment(ctx)
  else
    return M.auto_show_except_within_comments(ctx)
  end
end

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

M.get_chars_before_cursor = function(n_chars)
  local curs_col = vim.fn.col(".")

  if (curs_col - 1) < n_chars then
    return ""
  end

  local curs_line = vim.fn.getline(".")
  local until_curs = vim.fn.strcharpart(curs_line, 0, curs_col - 1)
  local truncated = vim.fn.strcharpart(until_curs, curs_col - n_chars - 1)

  -- print("curs_col:", curs_col, "/ until_curs:", until_curs)

  return truncated
end

-- This uses Noice to suss the before-cursor byte.
-- - ISOFF: Because get_chars_before_cursor() feels "righter".
-- - SAVVY: Noice returns the *byte*, whereas we could get the
--   character instead using strcharpart():
--       local char_before_cursor = vim.fn.strcharpart(
--         vim.fn.getline("."), vim.fn.charcol(".") - 2, 1)
--       print("char:", char_before_cursor, "/ byte:", byte_before_cursor)
--   - Either approach works, but returning the character feels
--     more appropriate.
--     - E.g., after "✅", strcharpart() returns "✅", whereas
--       Noice reports "<85>" (its UTF-16 encoding is 0x2705,
--       and its UTF-8 encoding is 0xE2 0x9C 0x85).
--
-- REFER: Prefer vim.api.nvim_get_current_buf() vs. vim.fn.bufnr().
-- - (ASIDE: So noted because author still learning vim.api calls.)
if false then
  function M.get_byte_before_cursor()
    local bufnr = vim.api.nvim_get_current_buf()
    local byte_before_cursor = require("noice.lsp.signature").get_char(bufnr)

    return byte_before_cursor
  end
end

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

-- This is the blink.cmp <Tab> fallback (for when completion not showing
-- and <Tab> not being used to accept a completion suggestion):
-- - If snippets active, ensures "inclusive" 'selection' mode to avoid
--   truncation issue, then jumps.
-- - Or, if selection active, indents.
-- - Finally, if Insert mode, inserts Tab or space(s) using smart-tab
--   feature, which uses spaces in comments, regardless of 'expandtab'.

-- SAVVY: Some file types, like ft=conf, won't indent when '#' is at
-- the first column.
-- - REFER: Disable smartindent to enable indenting comment blocks:
--     setlocal nosmartindent
--   - Which you could also add to a modeline.
--   - See also the ft-specific nvim-lazyb uses to disable it.
-- - BTNOT: Adjust cinkeys didn't work:
--     setlocal cinkeys=0{,0},0),0],:,0#,!^F,o,O,e
--     setlocal cinkeys-=0#

vim.keymap.set({ "i", "s" }, "<Tab>", function()
  -- SAVVY: blink.cmp's snippets.action() also checks luasnip and mini.snippets.
  -- - So not this:
  --     if vim.snippet.active({ direction = 1 }) then ... end
  local snippets = require("blink.cmp.config").snippets
  if snippets.active({ direction = 1 }) then
    -- print("SNIPPET")
    vim.o.selection = "inclusive"
    return "<Cmd>lua vim.snippet.jump(1)<CR>"
  else
    local mode = vim.fn.mode()
    -- print("TAB: mode:", vim.fn.mode())
    if mode == "s" or mode == "S" then
      return "<C-o>>gv<C-g>"
    else
      -- Return than enter a simple Tab, e.g.,
      --   return "<Tab>"
      -- Insert spaces instead if Tabbing within comments.
      -- - CXREF:
      --   ~/.kit/nvim/landonb/dubs_edit_juice/plugin/smart-tabs.vim
      return vim.fn.InsertSmartTab()
    end
  end
end, { desc = "SmartTab, Indent, or Snippet Jump", expr = true, silent = true })

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
-- *** Autocommand Events

-- Same as:
--   local group = vim.api.nvim_create_augroup("lazyb_" .. "activeSignature", { clear = true })
local group = require("util").augroup("activeSignature")

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

-- Close completion drop-down when signature help is displayed.
-- - SPIKE: What happens when Tab-jumping, can you view sign. help
--   while also using completion dropdown to complete arguments?

-- AFAIK, there's no function for checking if signatureHelp popup is
-- showing, other than setting a custom FileType ("noice_signature")
-- and tracking events ourselves.
-- - ASIDE: Noice itself uses a table<LspKind, NoiceMessage> to track messages,
--   and each message contains a table<integer, table<number, true>> lookup
--   keyed by the bufnr and an incremental ID.
--   - To decide when to close signatureHelp, Noice also monitors
--     CurorMoved(I) and InsertEnter events via its M.autohide():
--       ~/.local/share/nvim_lazyb/lazy/noice.nvim/lua/noice/lsp/docs.lua
--   - So there's not an optimal approach for asking Noice for the
--     signatureHelp bufnr without filtering its private messages table.
-- - That said, we can watch events and check &filetype.

-- SAVVY: This var. curr. not used for anything.
-- - But keeping it for possible future use (and we still at least
--   need the FileType event, though currently the WinClosed event
--   only unsets this boolean).
M.signature_showing = false

-- Tracks when signature popup is closed.
vim.api.nvim_create_autocmd("WinClosed", {
  group = group,
  -- This never fires...
  --   pattern = { "noice_signature" },
  callback = function()
    local winid = tonumber(vim.fn.expand("<amatch>")) or 0
    if not vim.api.nvim_win_is_valid(winid) then
      return
    end
    local bufnr = vim.api.nvim_win_get_buf(winid)
    local filetype = vim.api.nvim_get_option_value("filetype", { buf = bufnr })
    -- SAVVY: The "noice_signature" &filetype is set by our noice.lua config.
    -- - By default, all noice windows are ft="noice", and I don't know of
    --   any way to identify the signature popup other than a custom filetype.
    if filetype == "noice_signature" then
      -- print("SIG was hidden:", filetype)
      M.signature_showing = false
    end
  end,
})

-- Tracks when signature popup appears, and closes completion.
-- - SAVVY: WinNew is not called for signature float.
--   - So not something like this:
--       vim.api.nvim_create_autocmd("WinNew", {
--         group = group,
--         callback = function() print("WinNew") end,
--       })
vim.api.nvim_create_autocmd("FileType", {
  group = group,
  pattern = { "noice_signature" },
  callback = function()
    -- print("SIG SHOW:", vim.fn.expand("<amatch>"))
    M.signature_showing = true
    -- Close completion if it was opened while waiting for signatureHelp
    -- response. (See M.timeout_ms_signature, but don't set that to 0, or
    -- you'll see blink completion briefly, then signatureHelp pops open,
    -- then completion closes.)
    require("blink.cmp").hide()
  end,
})

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

-- FEATR: Close sig. win. when cursor moves to a different window.
-- - E.g., nvim-lazyb has <Shift-Ctrl-Arrow> you can use from Insert
--   mode to jump to another window.
-- - BUGGN: If signature help is showing in one window and you jump
--   the cursor to another window after a trigger character, the Noice
--   "stay" routine doesn't hide the signature float, which continues
--   to appear in the now-inactive window, showing help for the previous
--   cursor context.
--   - HSTRY: I first tried using this WinLeave event to determine
--     whether to hide signature help, but it didn't work as I hoped.
--   - So I added the functionality to the LSP request "stay" function
--     instead, which so far seems to work as intended.
--     - REFER: See the stay() function defined in vim.lsp.buf_request()
--       below.
--     - The stay() function checks the window ID, bufnr, and whether
--       the cursor follows a trigger character,
--   - This WinLeave block retained for posterity, and as a reminder
--     that WinLeave might not work for what you're trying to do.
--     - This is also only code where I tried to sigwin:hide(),
--       rather than relying on stay() function for "hiding" it.

if false then
  vim.api.nvim_create_autocmd("WinLeave", {
    group = group,
    callback = function()
      -- DUNNO: I don't see a vim.lsp.buf signature-close command. So this.
      -- - WRONG: Don't close the window directly, because it removes the
      --   signature window text but leaves a big empty rectangle:
      --     require("util.windows").close_windows_by_ft({ filetype = "noice_signature" })
      -- - WRONG: Same issue with this approach, leaves an empty rectangle:
      --     vim.api.nvim_win_close(require("noice.lsp.docs").get("signature"):win(), false)
      -- - WRONG: Don't use a broad Noice dismiss, which is too inclusive,
      --   e.g., it'll also close the :messages window:
      --     vim.cmd("Noice dismiss")
      -- - WRONG: I tried Manager.get(), but it only works when testing, and not
      --   when wired to run normally.
      --   - E.g., Manager.get() in the following code returns nil:
      --       local Manager = require("noice.message.manager")
      --       -- Returns nil:
      --       local messages = Manager.get({ event = "signature" }, { sort = true })
      --       -- Also returns nil:
      --       local messages = Manager.get(nil, { sort = true })
      --       if #messages > 0 then
      --         Manager.remove(messages[1])
      --       end
      --    - Although this works when I run it manually:
      --        call timer_start(4000, { -> execute("lua print(require('noice.message.manager').get(
      --          { event = 'signature' }, { sort = true }))", '')})
      -- - WRONG: This reports 0 when the signature float is showing:
      --       local views = require("noice.message.router").get_views()
      --       call timer_start(2000, { -> execute("lua views = require('noice.message.router').get_views() and print(#views)", '')})
      --   - BWARE: You'll hang Neovim in you try to print(vim.inspect()) a very large table!
      --     - E.g., don't run `I require("noice.message.router")._routes`!
      --     - But you can at least print a count, e.g., this reported "26":
      --         #require("noice.message.router")._routes
      --     - And this reported "0":
      --         #require("noice.message.router").get_views()
      --
      -- local messages = require("noice.message.manager").get(nil, { sort = true })
      -- print("WinLeave: #messages:", #messages)
      --
      -- DUNNO: This get() works when run manually, but it returns nil
      -- when run via WinLeave event.
      local sigwin =
        require("noice.message.manager").get({ event = "signature" }, { sort = true })[1]
      if sigwin then
        -- print("WinLeave: sigwin:hide()")
        sigwin:hide()
      end
    end,
  })
end

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

-- FEATR: Dismiss completion menu when user starts a Select mode selection.
--
-- BUGGN: WEIRD: If the completion menu is showing and you begin
-- a selection, and then <PageUp>, it sends the cursor to the top
-- of the sign column!?
-- - And then you cannot move the cursor, but you can :wincmd
--   back to a real window.
-- - This *might* be a result of the blink bindings I'm developing.
--   - Still seems weird, like, how is this even possible?!
-- - You'll also see a blink.cmp trace:
--     Error executing vim.schedule lua callback:
--       ...zy/blink.cmp/lua/blink/cmp/completion/accept/preview.lua:30:
--         Cursor position outside buffer
--
-- SPIKE: Should you hide when mode changed to "n" Normal?
-- - I'm guessing not, because of command maps that temporarily
--   switch modes.

vim.api.nvim_create_autocmd("ModeChanged", {
  group = group,
  callback = function()
    local mode = vim.fn.mode()
    -- print("blink: ModeChanged:", mode)
    -- Note we don't to need to also check line-wise "S" selection.
    -- - AFAIK, you can only triple-click to make "S" selection (e.g.,
    --   <Shift-Down> is just a character-wise "s" selection), and
    --   there's an `imap <LeftMouse>` that'll hide() blink.cmp on
    --   the first click. So no need to check "S".
    -- - But if signature showing and you triple-click to start a
    --   line-wise "S" selection, then we do need to hide it. But
    --   that's handled in the vim.lsp.buf_request() stay() callback,
    --   because I otherwise don't know how to identify and deliberately
    --   close the signature float — the closest I got was using
    --   require("noice.message.manager").get(), as shown in the
    --   disabled WinLeave handler, above, but I also couldn't get
    --   get() to work reliably.
    --   - Nor does this work to close signature, but leaves empty
    --     rectangle:
    --     vim.api.nvim_win_close(require("noice.lsp.docs").get("signature"):win(), false)
    if mode == "s" then
      require("blink.cmp").hide()
    end
  end,
})

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
-- *** Debounce hider

-- FEATR: Hide completion menu when moving cursor around in Insert mode.
-- - Otherwise, if completion menu open and you, e.g., press <Down> or
--   <Up>, the completion menu remains open.
--   - BUGGN: And not just that, but it continues to show completion
--     items for the previous keyword under/behind the cursor.
-- - Note also we debounce, so that if you continue to move the cursor,
--   the completion menu doesn't reappear after every movement.
--   - Not only are you probably not interested in the completion menu
--     while moving the cursor, but the menu can obscure the text you're
--     trying to move the cursor to (or, e.g., if you're selecting text,
--     the menu might obscure the text that you want to add to the
--     selection (and while you can still continue to select text while
--     the menu is open, the menu might obscure useful context as you
--     add to the selection)).
-- - REFER: See additional (somewhat redundant) notes in the opts.keymap{}
--   definition below.

-- ALTLY: I had considered using CursorMovedI to hide completion, but it
-- also fires when you insert text, which also moves the cursor.
-- - TRYME: You can demo with this autocmd (which also prints the date,
--   otherwise if the message is the same as the previous message, you
--   might not see the message displayed until you run |mess|):
--     augroup TESTME2 | au! | au CursorMovedI * echom "MOVED " .. strftime('%X') | augroup END
--     au! TESTME2 CursorMovedI
-- - The idea would be to call cmp.cancel() on CursorMoved, but it looks
--   like we'll have to intercept (via `map`) individual motions instead.
--   - There's also "InsertCharPre", but that only fires on visible text
--     actually being inserted, and not control keypresses.
-- - Though note this approach might be moot anyway, because we also need
--   to react to more than just bare arrows, but also <Shift-{arrow}>,
--   <PageUp>/<PageDown>, etc., and not all those trigger CursorMoved.
--   - E.g., <End> does, but not <Shift-End>.

-- Note that some things might be more easily implemented if Neovim
-- signalled snippet mode events. But it currently does not.
-- - REFER: *Add SnippetEnter and SnippetLeave events*
--   https://github.com/neovim/neovim/issues/26449

-- The M.blink_cmp_debounce flag set true when debounce initiated, and
-- it's used together with vim.g.blink_cmp_enabled to drive blink.cmp
-- opts.enabled().
-- - CPYST: You could set this manually when testing, e.g.:
--     require("plugins.blink-cmp").blink_cmp_debounce = false
M.blink_cmp_debounce = false

-- These timers are used to manage the debounce timer, and also for
-- waiting for the LSP signatureHelp response (to determine whether
-- to hide completion if signatureHelp is displayed).
-- - KLUGE: There might be a better approach, but if the debounce
--   timer finds a trigger character, we try to emulate blink.cmp
--   behavior, and to show the signature help if available. But
--   rather than explicitly check if signature help is available,
--   we ask the LSP to show it, and then check back later; if the
--   LSP found signature help and blink.cmp (well, Noice) shows it,
--   then we don't show the completion menu. (We need the signature
--   help timer because we cannot immediately detect if signature
--   help exists, and then we might end up showing *both* the
--   signature help float as well as the completion menu.)
M.timer_debounce = nil
M.timer_triggers = nil
M.timer_signature = nil

-- The arrow key maps defined in opts.keymap each call this function.
-- - It hides the current completion dropdown, which is no longer valid
--   for the new cursor context.
-- - Then it starts the debounce timer to check later whether to show
--   completion or signature help for the new cursor context.
--   - When the debounce timer fires, we'll check for a trigger character
--     before the cursor to decide whether to reveal signature help or
--     completion or not.
M.cancel_and_debounce = {
  function(cmp)
    M.start_timer_debounce()
    cmp.cancel()
  end,
  "fallback",
}

M.hide_signature_and_fallback = {
  function(cmp)
    cmp.cancel()
    -- It seems that on_signature()'s stay() callback runs
    -- immediately after this function, so we can tell it
    -- to close signature help.
    M.close_signature_help = true
  end,
  "fallback",
}

-- How long to debounce.
-- - This is personal preference and shouldn't affect whether feature
--   works or not (unlike, e.g., M.timeout_ms_signature, which might).
-- MAYBE: Make the timer values configurable.
-- - If we used a vim.g global, user could set it before LazyVim loads specs.
--   - Ideally, user would specify from init() like normal for most plugins,
--     but this is a plugin spec, not a plugin, so wouldn't work like that.
M.timeout_ms_debounce = 50

-- How long after debounce to decide whether to show signature/completion
-- again.
-- - This is separate from M.timeout_ms_debounce so that we don't inhibit
--   the completion menu if the user starts inserting new text, or does
--   something else that normally reveals the completion menu.
-- - This value is also personal preference, and any value should work.
M.timeout_ms_triggers = 500

-- How long to wait after requesting signatureHelp to check if the float
-- was opened, and, if not, to then show blink completion.
-- - KLUGE: This value is derived emperically.
-- - FEATR: Our `au FileType` will close the completion window if
--   signature response from LSP takes longer than this timeout value.
--   - So worst case scenario, you might see completion for a very brief
--     moment, then the signature popup, and then completion is closed.
-- - Note that it'll take at least M.timeout_ms_triggers to show signature
--   popup, or M.timeout_ms_triggers plus M.timeout_ms_signature to show
--   the completion picker.
M.timeout_ms_signature = 300

function M.start_timer_debounce()
  -- Note that blink.cmp creates both Insert and Select mode maps for
  -- the items in opts.keymap{}, so we'll bounce unless called in Insert
  -- mode (or at least I assume it does, because this function called in
  -- "s" mode, and, e.g., `smap <left>` reports a blink.cmp handler).
  -- - DUNNO: Not sure why called in Select mode. Plain LazyVim doesn't have
  --   this issue, AFAICT. But without this, if you make a selection, this
  --   function called, and while you might not see completion while
  --   selecting, if you cancel to Normal mode, you might then see the
  --   completion menu popup.
  local mode = vim.fn.mode()
  -- print("debounce: mode:", mode)
  if mode == "s" then
    --

    return
  end

  M.blink_cmp_debounce = true
  -- Stop all timers and restart the debounce timer.
  if M.timer_triggers then
    M.timer_triggers:stop()
  end
  if M.timer_signature then
    M.timer_signature:stop()
  end
  if M.timer_debounce then
    M.timer_debounce:again()
  else
    -- One-time timer setup (once this runs once, we'll again() it
    -- on subsequent runs).
    -- - So we'll keep the timer indefinitely, i.e., not:
    --     M.timer_debounce:close()
    --     M.timer_debounce = nil
    --   - MAYBE: See note above: We could support changing timeout values at
    --     runtime, in which case we'd want to recreate the timer if the user
    --     changes the timeout value.
    --     - For now, user must restart Neovim or Lazy-reload to realize
    --       timeout changes.
    M.timer_triggers = vim.uv.new_timer()
    -- So that again() uses the same timeout value.
    local debounce_repeat_ms = M.timeout_ms_debounce
    M.timer_debounce = vim.uv.new_timer()
    M.timer_debounce:start(M.timeout_ms_debounce, debounce_repeat_ms, function()
      M.timer_debounce:stop()
      M.blink_cmp_debounce = false
      local timeout_ms_triggers = M.timeout_ms_triggers
      local repeat_ms_triggers = M.timeout_ms_triggers
      M.timer_triggers:start(
        timeout_ms_triggers,
        repeat_ms_triggers,
        -- REFER: Don't call vim.api from vim.uv callback; use schedule_wrap.
        --   |E5560| |lua-loop-callbacks|
        vim.schedule_wrap(M.check_triggers_timeout)
      )
    end)
  end
end

-- This timer callback checks if cursor is after a trigger character,
-- which is how blink.cmp behaves after user enters Insert mode and
-- cursor is after a trigger character, per the option:
--     completion.trigger.show_on_insert_on_trigger_character
-- - We'll treat moving cursor in Insert mode similarly: show signature
--   or completion if cursor is after a trigger character.
-- - REFER: To see list of trigger characters, request from the LSP:
--     :lua print(vim.inspect(vim.lsp.get_clients({bufnr = vim.fn.bufnr()})[1].server_capabilities.completionProvider.triggerCharacters))
-- - E.g., in Lua file, luals reports a bunch of 'em':
--     { "\t", "\n", ".", ":", "(", "'", '"', "[", ",", "#", "*",
--       "@", "|", "=", "-", "{", " ", "+", "?" }
--
-- FTREQ/INERT: Cache triggerCharacters (if requesting from LSP is slow).
--
-- Note that blink.cmp shows signature help instead of completion when
-- possible, but it's Noice, not blink.cmp, that shows signature help.
-- - And we call the LSP to show signature help, not blink.cmp.
--   - I.e., this won't work:
--       require("blink.cmp").show_documentation()
-- - DEVEL: You can inspect the signature window using a timer callback,
--   because if you show signature help and then try to run a normal
--   mode command, the signature help is closed. So instead, set a timer,
--   press <Ctrl-K> to show signature help, and then when the timer fires,
--   the signature window will still be visible.
--   - E.g., this indicates that the signature help window has ft=noice:
--       call timer_start(2000, { -> execute("lua vim.tbl_filter(function(win) print(win, vim.api.nvim_buf_get_option(vim.api.nvim_win_get_buf(win), 'filetype')) end, vim.api.nvim_tabpage_list_wins(0))", '')})
--
-- We send a buf_request to show signature help, which fails
-- silently if no help is available.
-- - SAVVY: There's an easier function that also shows help:
--     vim.lsp.buf.signature_help()
--   But it evokes a Noice message if no signature help is
--   available:
--     vim.notify("No signature help available")
--   And using 'silent' doesn't silence the Noice message:
--     vim.lsp.buf.signature_help({ silent = true })
--
-- TRYME: You can test buf_request manually by running these three
-- :lua commands:
--   mybufnr = vim.fn.bufnr()
--   mychars = vim.lsp.get_clients({ bufnr = mybufnr })[1].server_capabilities.completionProvider.triggerCharacters or {}
--   vim.lsp.buf_request(mybufnr, "textDocument/signatureHelp", vim.lsp.util.make_position_params(0, "utf-16"), function(err, result, ctx) require('noice.lsp.signature').on_signature(err, result, ctx, { trigger = true, stay = function() return vim.tbl_contains(mychars, require('noice.lsp.signature').get_char(mybufnr)) end}) end)

function M.check_triggers_timeout()
  M.timer_triggers:stop()

  local mode = vim.fn.mode()
  if mode == "n" then
    -- Don't show signature help if user escaped quickly
    -- before this timer callback runs.

    return
  end

  -- *** Hide completion depending on the previous character.

  local chars_before_cursor = M.get_chars_before_cursor(2)
  local char_before_cursor = vim.fn.strcharpart(chars_before_cursor, 1)
  -- print("CHECK: chars:", chars_before_cursor, "/ char:", char_before_cursor)

  -- Don't show completion at the start of the line.
  if char_before_cursor == "" then
    --

    return
  end

  -- Don't show completion after a Lua comment delimiter.
  --
  -- MAYBE: Restrict to Lua filetype specifically.
  -- - Could we also move this "business logic" to config?
  if chars_before_cursor == "--" then
    --

    return
  end

  -- Don't show completion after a space.
  if char_before_cursor == " " then
    --

    return
  end

  -- *** Hide completion unless cursor follows a trigger character.

  -- ALTLY: We could pass bufnr=0, but we need the bufnr later, anyway.
  --   local first_client = vim.lsp.get_clients({ bufnr = 0 })[1]
  local req_bufnr = vim.api.nvim_get_current_buf()
  local first_client = vim.lsp.get_clients({ bufnr = req_bufnr })[1]

  local triggerChars = first_client
      and first_client.server_capabilities.completionProvider.triggerCharacters
    or {}
  local triggers = type(triggerChars) == "string" and { triggerChars } or triggerChars

  if not vim.tbl_contains(triggers, char_before_cursor) then
    --

    return
  end

  -- *** Hide completion after waiting to see if LSP responds with Signature help.

  -- MAYBE: Move these chars to config, and associate with |filetype|.
  if vim.tbl_contains({ ".", ":" }, char_before_cursor) then
    -- Special case: Don't show signature help after "." or ":".
    -- - MAYBE: We might want to adjust this depending on the language/LSP.
    -- - MAYBE: We might want to add additional trigger characters that
    --   should not evoke signature help.
    -- - (You can still show signature help after ".", but blink.cmp doesn't
    --    do this; it'll show signature help after "(", but only the normal
    --    completion menu after ".".)
    -- - Show completion immediately.
    -- print("CHECK: show now")
    require("blink.cmp").show()

    return
  else
    -- Request signature help, then check later if any received.
    -- - If LSP returns signature help, hide completion; otherwise
    --   Noice will have displayed the signatureHelp floating window.
    -- - Note there's a Noice function to show signature:
    --     require("noice.lsp").signature()
    --   except it prints "No signature help available" if no help.
    --   - Which is no help, and distracting, so we do it the long way.

    -- Remember the window ID of the request, in case use changes
    -- windows (and don't just check the bufnr, so we can handle
    -- splits for the same buffer).
    local req_winid = vim.api.nvim_get_current_win()

    -- Use a module variable to effect a signature help close (because I
    -- cannot find another way to deliberately close the signature float
    -- that doesn't leave an empty rectangle in its place).
    M.close_signature_help = false

    -- The encoding is one of: "utf-8" | "utf-16" | "utf-32".
    local window_id = 0
    local offset_encoding = first_client and first_client.offset_encoding or "utf-16"

    vim.lsp.buf_request(
      req_bufnr,
      "textDocument/signatureHelp",
      vim.lsp.util.make_position_params(window_id, offset_encoding),
      function(err, result, ctx)
        -- print("signatureHelp: req_bufnr:", req_bufnr)
        require("noice.lsp.signature").on_signature(err, result, ctx, {
          trigger = true,
          -- If you cursor away from window, e.g., <Ctrl-Cmd-Arrow>, this
          -- function called, but nvim_get_current_buf() still the old
          -- value, so stay() returns true, and signature window remains
          -- open in the old window.
          -- - This is Noice issue: if cursor lands in the other buffer
          --   after trigger character, signature remains open. But if
          --   cursor not after trigger character, then the signature
          --   popup in the previous window is closed.
          --   - The issue is that Noice doesn't check if the cursor is
          --     in the same window as the currently-showing sig. float.
          -- - ASIDE: Happens regardless of noice auto_open.trigger:
          --     noice.opts.lsp.signature.auto_open.trigger = true|false
          stay = function()
            local now_winid = vim.api.nvim_get_current_win()
            local now_bufnr = vim.api.nvim_get_current_buf()
            local now_char = require("noice.lsp.signature").get_char(req_bufnr)
            local now_mode = vim.fn.mode()
            local do_stay = (req_winid == now_winid)
              and (req_bufnr == now_bufnr)
              and vim.tbl_contains(triggers, now_char)
              and now_mode ~= "S"
              and now_mode ~= "n"
              and not M.close_signature_help
            -- stylua: ignore
            -- print("do_stay:", do_stay, "/ req_winid:", req_winid, "/ now_winid:", now_winid,
            --   "/ req_bufnr:", req_bufnr, "/ now_bufnr:", now_bufnr, "/ now_char: ", now_char,
            --   "/ now_mode:", now_mode, "/ M.close_signature_help:", M.close_signature_help)
            M.close_signature_help = false
            return do_stay
          end,
        })
      end
    )
  end

  if M.timer_signature then
    M.timer_signature:again()
  else
    local signature_repeat_ms = M.timeout_ms_signature
    M.timer_signature = vim.uv.new_timer()
    -- print("BLINK DEFER")
    M.timer_signature:start(
      M.timeout_ms_signature,
      signature_repeat_ms,
      vim.schedule_wrap(function()
        -- DEVEL: If you want to see the window ID, you can set a timer, then
        -- position the cursor between ()'s before the timer fires and press
        -- <Ctrl-K> to show signature help, and when the timer fires, it'll
        -- print the window ID:
        --   call timer_start(2000, { -> execute("lua print(require('noice.lsp.docs').get('signature'):win())", '')})
        -- - See also `activeSignature` instead, but prints nil:
        --     require('noice.lsp.signature').activeSignature
        -- print("DEFER: timer_signature callback")
        if not require("noice.lsp.docs").get("signature"):win() then
          -- Don't show completion if user escaped to Normal mode.
          -- - TRYME: Consider code `vim.defer_fn` — Position cursor
          --   in Insert mode before ".", then <Ctrl-Space> to show
          --   completion. Next, <Right>, <Right>, and <Esc>. The timer
          --   callback runs, but state no longer in Insert mode, so
          --   shouldn't show completion.
          -- - SPIKE: Change this defer_fn callback to cancellable
          --   timer, than maybe this check unnecessary.
          if vim.fn.mode() ~= "n" then
            -- DUNNO: Sometimes signatureHelp not found, e.g., this vim.tbl_contains
            -- (but found for other vim.tbl_contains within this file).
            -- local now_chars_before_cursor = M.get_chars_before_cursor(2)
            -- local now_char_before_cursor = vim.fn.strcharpart(chars_before_cursor, 1)
            local now_char_before_cursor = M.get_chars_before_cursor(1)
            if
              not vim.tbl_contains({ "(", " ", "" }, now_char_before_cursor)
              and vim.tbl_contains(triggers, now_char_before_cursor)
            then
              -- print("BLINK SHOW: mode:", vim.fn.mode())
              require("blink.cmp").show()
            end
          end
        else
          -- print("SIGNATURE SHOWING")
          require("blink.cmp").hide()
        end
      end)
    )
  end
end

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

-- REFER:
-- https://cmp.saghen.dev/configuration/completion.html
-- https://cmp.saghen.dev/recipes.html

-- REFER: Disable auto-showing completion menu
--   completion.menu.auto_show = false
-- You could disable auto-show but use ghost text:
--   completion.ghost_text.enabled = true

-- MAYBE: Make the completion dropdown colorful
-- (works with blink.cmp completion menu):
--   https://github.com/xzbdmw/colorful-menu.nvim

-- SAVVY: LazyVim uses the "enter" preset, and it adds
-- a <Ctrl-y> binding:
--
--   keymap = {
--     preset = "enter",
--     ["<C-y>"] = { "select_and_accept" },
--   },
--
-- - CXREF:
--   ~/.local/share/nvim_lazyb/lazy/LazyVim/lua/lazyvim/plugins/extras/coding/blink.lua @ 89
--
-- But we'll use the "super-tab" profile instead, and we'll clear
-- the <Ctrl-y> binding (which conflicts with mswin.lua Undo).
--
-- - REFER: https://cmp.saghen.dev/configuration/keymap#super-tab
--
--   ['<C-space>'] = { 'show', 'show_documentation', 'hide_documentation' },
--   ['<C-e>'] = { 'hide', 'fallback' },
--
--   ['<Tab>'] = { [accept or select_and_accept], 'snippet_forward', 'fallback' },
--   ['<S-Tab>'] = { 'snippet_backward', 'fallback' },
--
--   ['<Up>'] = { 'select_prev', 'fallback' },
--   ['<Down>'] = { 'select_next', 'fallback' },
--   ['<C-p>'] = { 'select_prev', 'fallback_to_mappings' },
--   ['<C-n>'] = { 'select_next', 'fallback_to_mappings' },
--
--   ['<C-b>'] = { 'scroll_documentation_up', 'fallback' },
--   ['<C-f>'] = { 'scroll_documentation_down', 'fallback' },
--
--   ['<C-k>'] = { 'show_signature', 'hide_signature', 'fallback' },
--
-- The main difference between "enter" and "super-tab" is using
-- <CR> vs. <Tab> to "accept" the selected completion item.
-- - BECUZ: When <CR> is mapped to completion accept, then to enter
--   a line break at the end of a line of rst text, you need to either
--   double-enter (<CR><CR>) or use <Shift-Enter> to avoid `accept`'ing.
-- - RECAP:
--   - LazyVim settings:
--       preset = "enter"                      -- Uses <CR> to accept
--       ["<C-y>"] = { "select_and_accept" },  -- Conflicts with mswin.lua Undo
--   - blink.cmp "super-tab" wires <Tab> to select completion.
--
-- ASIDE: Default Insert mode <Ctrl-Space> is not documented.
-- - In Neovide, <Ctrl-Space> effectively <Esc>apes.
-- - In nvim (terminal) <Ctrl-Space> generates |CTRL-@| (insert previously
--   inserted text, and leave Insert mode; or "E29: No inserted text yet").
--     https://stackoverflow.com/questions/24983372/what-does-ctrlspace-do-in-vim
--     https://shallowsky.com/blog/linux/editors/vim-ctrl-space.html
--
-- FTREQ: Call Undo on <Ctrl-e>.
-- - Currently if you cycle through completion suggestions but
--   then cancel with <Ctrl-e>, buffer is marked modified.

return {
  {
    -- CXREF:
    -- ~/.local/share/nvim_lazyb/lazy/LazyVim/lua/lazyvim/plugins/extras/coding/blink.lua @ 16
    "saghen/blink.cmp",

    -- SAVVY: LazyVim use Vim "InsertEvent" event to load blink.cmp when user
    -- enters Insert mode.
    -- - E.g., you won't see `imap <C-Space>` set until you start Insert mode
    --   first time. (If you want to see the binding sooner, use "VeryLazy".)
    --
    --  event = "InsertEnter",

    init = function()
      -- MAYBE: Install rust toolchain for 'build', then run off latest code.
      -- - ALTLY: Still works without `cargo` but emits warning re: fallback to lua fuzzy.
      -- ~/.local/share/nvim_lazyb/lazy/LazyVim/lua/lazyvim/plugins/extras/coding/blink.lua
      --
      -- "set to `true` to follow the main branch
      --  you need to have a working rust toolchain
      --  to build the plugin in this case."
      --
      --  vim.g.lazyvim_blink_main = true
    end,

    opts = function(_, opts)
      opts.keymap = {
        -- REFER: See notes above re: "super-tab" default bindings.
        preset = "super-tab",

        -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

        -- Disable LazyVim's additional <C-y> select-and-accept binding.
        -- - USAGE: Use <Tab> to select completion item.
        -- - BECUZ: We use <C-y> as Insert mode Redo. / CXREF:
        --   ~/.kit/nvim/landonb/nvim-lazyb/lua/util/mswin.lua
        ["<C-y>"] = nil,

        -- Buffer <Tab> map. Falls-back `imap <Tab>`/`smap <Tab>` defined
        -- above that'll insert a (smart) tab, indent, or snippet-jump.
        -- - REFER: *how to map tab to select_next when the completion menu is
        --   pop out, and use tab as snippet_forward, after the select item?*
        --     https://github.com/Saghen/blink.cmp/discussions/1184
        --   ["<Tab>"] = { "select_next", "snippet_forward", "fallback" },
        -- - REFER: *use tab for [select_next & snippet_forward] based on condit.*
        --     https://github.com/Saghen/blink.cmp/discussions/628
        ["<Tab>"] = {
          function(cmp)
            -- SAVVY: Avoid "exclusive", or replacing selected
            -- snippet placeholder leaves one character behind.
            -- - See also mswin.lua, which changes this to
            --   "exclusive" for shifted special key maps.
            --   - I.e., this map and the shifted special key maps
            --     toggle 'selection' back and forth.
            vim.o.selection = "inclusive"
            if cmp.snippet_active() then
              -- print("snippet_active: cmp.accept()")
              return cmp.accept()
            else
              -- Happens on completion select, or normal <Tab>.
              -- print("!snippet_active: cmp.select_and_accept()")
              return cmp.select_and_accept()
            end
          end,
          function(cmp)
            -- SAVVY: blink.cmp's snippets.action() also checks luasnip and mini.snippets.
            local snippets = require("blink.cmp.config").snippets
            -- stylua: ignore
            -- print("snippets.active", snippets.active(), "/ snippets.active(1)", snippets.active({ direction = 1 }))
            if not snippets.active() then
              -- This unnecessary because shifted special key maps set "exclusive",
              -- but it also keeps user's session mostly in "exclusive" mode.
              vim.o.selection = "exclusive"
            end
            return nil
          end,
          "snippet_forward",
          "fallback",
        },

        -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

        -- FEATR: Cancel completion after moving the cursor using arrow keys,
        -- or when making a selection from Insert mode.
        -- - BUGGN: Sometimes completion stays open on the word you cursored
        --   away from after <Up>/<Down>, but the completion items do not
        --   update for the new word under the cursor (at least not until you
        --   <Left>/<Right>, etc.).
        -- - THOTS: Also, unless you're inserting new code/text, you probably
        --   don't care about seeing the completion menu for existing code/text
        --   (that you're probably not planning to change).
        -- - Below, we update the arrow key maps to always cancel(), then to
        --   "fallback", and possibly to re-trigger the completion menu.
        --   - But first! a detailed (aka "long") explanation.
        --
        -- SAVVY: Note that "super-tab" wires <Up>/<Down> to prev/next in the
        -- completion menu, but this makes the UX wonky if you also <Up>/<Down>
        -- to navigate the buffer, because the cursor can get "trapped" by the
        -- completion menu.
        -- - E.g., if you <Down> from one line to another, but then the completion
        --   menu appears, if you <Down> again, rather than move the cursor to
        --   the line below, the cursor is now captured by and trapped in the
        --   completion menu (and you'll need to <Ctrl-e> (or <Esc>, see below)
        --   to dismiss the completion menu to <Down> to the next line).
        -- - DUNNO: I'm unsure if blink.cmp means for this to happen or not,
        --   e.g., should <Down> from one line to another really trigger the
        --   completion menu?
        --   - blink.cmp doesn't mention arrowing around in Insert mode, and
        --     I know most (true!) Vimmers navigate from Normal mode (e.g.,
        --     using the home row keys). But I'm one of those (rare?) Vimmers
        --     who moves their cursor around a lot from Insert mode. So I'd
        --     posit a guess that blink.cmp overlooks this behavior, and that
        --     most of its users just don't arrow around during Insert mode.
        --     - You'll also notice the completion menu triggers frequently
        --       as you arrow around, which seems unnecessary — e.g., as you
        --       move the cursor <Right> across a word, the completion menu
        --       updates for every cursor position. But do you really need
        --       to see the completion menu if you're just moving the cursor
        --       across an existing word, and not typing something new?
        --   - So let's make blink.cmp play nice with the arrow keys, and to
        --     not to trigger (appear) as frequently.
        --   - ASIDE: Note this affects 3 presets, "default", "super-tab", and
        --     "enter", which each wire <Up>/<Down> similarly. / The default
        --     preset, "cmdline", wires <Right>/<Left> instead, which creates
        --     a similar conflict if you move the cursor with <Right>/<Left>
        --     in Insert mode.
        --
        -- SAVVY: The default behavior is to select or fallback:
        --     ['<Up>'] = { 'select_prev', 'fallback' },
        --     ['<Down>'] = { 'select_next', 'fallback' },
        -- - So a simple "fix" is to merely fallback:
        --     ['<Up>'] = { 'fallback' },
        --     ['<Down>'] = { 'fallback' },
        --   - REFER: https://github.com/Saghen/blink.cmp/discussions/320
        -- - Or we could just remove the maps (inherent fallback):
        --     ["<Up>"] = {},
        --     ["<Down>"] = {},
        -- - However, with this approach, it leaves completion showing as you
        --   arrow around. This can be annoying at worst (e.g., the completion
        --   menu might obscure some of the buffer you're trying to move the
        --   cursor into; or, if you're selecting text, the completion menu
        --   might overlay text that you're trying to select). Or it could
        --   just be unnecessary at best (you probably don't care much about
        --   completion items (or the signature popup) if you're positioning
        --   the cursor and not actively typing something).
        --
        -- USAGE: Use <Alt-Up>/<Alt-Down> for completion menu prev/next.
        -- - Don't use <Up>/<Down>, so that arrowing around works seamlessly.
        -- - Don't use <S-Up>/<S-Down>, which are used to select up/down a line.
        -- - Don't use <C-Up>/<C-Down>, which are used to scroll up/down a line.
        -- - Don't use <D-Up>/<D-Down>, which are used to resize up/down a window.
        -- - That leaves <M-Up>/<M-Down>, which fortunately are not mapped.
        --   - Note their arrow counterparts, <M-Left>/<M-Right>, send the cursor
        --     to the start/end of a line, but there wasn't a complementary mapping
        --     at <M-Up>/<M-Down> — in nvim-lazyb, the complementary mappings are
        --     <Ctrl-Home>/<Ctrl-End> (to send the cursor to the start/end of the
        --     buffer) and <Ctrl-PageUp>/<Ctrl-PageDown> (to send the cursor to the
        --     top/bottom of the window).
        --  - Also note that default <Alt-Up|Down> leaves Insert mode then does the
        --    motion, just like most default <Alt> commands (leave Insert mode and
        --    do the thing).
        ["<M-Up>"] = { "select_prev", "fallback" },
        ["<M-Down>"] = { "select_next", "fallback" },

        ["<Up>"] = M.cancel_and_debounce,
        ["<Down>"] = M.cancel_and_debounce,
        ["<Left>"] = M.cancel_and_debounce,
        ["<Right>"] = M.cancel_and_debounce,

        -- ISOFF: If you want other Insert mode cursor movement to show
        -- completion if appropriate, enable these.
        -- - But I'm not sure I like that behavior.
        --
        --   ["<End>"] = M.cancel_and_debounce,
        --   -- SKIPD: <Home> jumps to start of line,
        --   -- which should never show completion.
        --   ["<C-Left>"] = M.cancel_and_debounce,
        --   ["<C-Right>"] = M.cancel_and_debounce,
        --   ["<M-Left>"] = M.cancel_and_debounce,
        --   ["<M-Right>"] = M.cancel_and_debounce,
        --   -- SKIPD: <C-PageUp> and <C-PageDown> jump to start of line,
        --   -- which should never show completion.
        --
        -- Hide signature help if it's showing and user sends the cursor
        -- to the end of the line.
        -- - UCASE: This only matters if the last character is a trigger
        --   character, e.g.,
        --     vim.fn.mode().
        --   which isn't a really compelling use case, I suppose, but
        --   we'll still handle it.
        ["<End>"] = M.hide_signature_and_fallback,
        ["<M-Right>"] = M.hide_signature_and_fallback,
        -- This map is probably unnecessary, but doesn't seem to hurt.
        ["<C-Right>"] = M.hide_signature_and_fallback,
        -- - In practice, <Ctrl-Left> usually puts cursor after space
        --   or after alpha character, i.e., it won't jump to after a
        --   trigger character. So its map seems unnecessary.
        -- - nvim-lazyb doesn't define <M-PageUp> or <M-PageDown>.
        --   They currently leave Insert mode and perform their
        --   Normal mode <PageUp> and <PageDown> equivalents.
        -- - <Ctrl-Home> jumps to start of file, i.e., not after a
        --   trigger character.
        --   - And <Ctrl-End> jumps to after final character in file,
        --     which *might* be a trigger character, but (for whatever
        --     reason) that motion already hides the signature help.

        -- ***

        -- MAYBE: <PageUp>/<PageDown> sometimes interfere with buffer navigation...

        -- BWARE: Are these why <PageDown> or <PageUp> can send cursor to sign column?
        -- - Start selection when completion showing, so the completion still
        --   showing in Select mode, then <PageDown> or <PageUp> sends cursor to jail.
        -- - Except I've since adjusted the shift-to-select maps,
        --   and now I can no longer reproduce this issue.
        --   - TRACK: Though I have very rarely still seen the cursor go to
        --     sign column jail, so it can still happen. But very rarely,
        --     and not currently sure what still causes it. But at least it's
        --     no longer a real priority.
        --
        -- SPIKE: Why does blink.cmp need smaps for these, anyway?
        -- - CXREF: blink.cmp says "snippet mode: uses only snippet commands"
        --   ~/.local/share/nvim_lazyb/lazy/blink.cmp/lua/blink/cmp/keymap/apply.lua @ 40
        -- So something to do with snippets?
        -- - In which case... cancel completion when selecting, right?

        -- Similar to the scroll commands for popup docs, which defaults
        -- to jumping 4 lines, wire <PageUp>/<PageDown> likewise.
        ["<PageUp>"] = {
          function(cmp)
            if cmp.is_visible() then
              for _ = 1, 4 do
                cmp.select_prev()
              end

              -- Return non-nil so fallback doesn't run.
              return true
            end
          end,
          "fallback",
        },
        ["<PageDown>"] = {
          function(cmp)
            if cmp.is_visible() then
              for _ = 1, 4 do
                cmp.select_next()
              end

              return true
            end
          end,
          "fallback",
        },

        -- ONICE: Cancel completion menu without leaving Insert mode.
        -- - BWARE: I find myself hitting <Esc> and then starting an :ex
        --   command without realizing I'm still in Insert mode, though.
        ["<ESC>"] = {
          function(cmp)
            if cmp.is_visible() then
              cmp.cancel()

              return true
            end
          end,
          "fallback",
        },
      } -- opts.keymap{}

      -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

      -- REFER:
      -- https://cmp.saghen.dev/configuration/reference.html

      -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

      -- USAGE: Enable command line completion by assigning the option:
      --
      --  opts.cmdline = {}

      -- - REFER: *cmdline fallback for <Esc> sometimes invokes the command*
      --   https://github.com/Saghen/blink.cmp/issues/547#issuecomment-2593493560
      -- - NTRST: Enables completion in the cmdline... without this, e.g.,
      --   <Ctrl-Space> just enters a space. With this, shows a completion
      --   suggestion, and <Ctrl-Space> opens completion menu.
      -- ISOFF: This doesn't play well with the built-in wildmode menu.
      if vim.g.lazyb_blink_cmp_cmdline_enable then
        opts.cmdline.keymap = {
          ["<ESC>"] = {
            function(cmp)
              if cmp.is_visible() then
                cmp.cancel()
              else
                vim.api.nvim_feedkeys(
                  vim.api.nvim_replace_termcodes("<C-c>", true, true, true),
                  "n",
                  true
                )
              end
            end,
          },
        }
      end

      -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

      -- SAVVY: M.blink_cmp_debounce is managed by M.timer_debounce.
      if true then
        opts.enabled = function()
          -- stylua: ignore
          -- print("blink.cmp.opts.enabled(): mode:", vim.fn.mode(),
          --   "/ vim.g.blink_cmp_enabled:", vim.g.blink_cmp_enabled,
          --   "/ not M.blink_cmp_debounce", not M.blink_cmp_debounce)
          return vim.g.blink_cmp_enabled and not M.blink_cmp_debounce
        end
      end

      -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

      -- FEATR: Inhibit completion menu if cursor after "--" comment leader in Lua.
      -- - E.g., just putting the cursor after "--" triggers completion,
      --   and then <Tab> selects and inserts completion item rather than
      --   inserting whitespace. (I.e., if you type "--" to start a comment,
      --   and then <Tab> to indent, you might be surprised when it accepts
      --   a completion suggestion instead.)
      -- - HSTRY: Some of the approaches I tried:
      --   - See 'show_on_blocked_trigger_characters', which uses single characters.
      --     So you could omit "-" as a trigger character, but then it affects
      --     single dashes, too, e.g.:
      --       opts.completion = {
      --         trigger = {
      --           show_on_blocked_trigger_characters =
      --             function(ctx)
      --               -- DUNNO: ctx is always nil?
      --               --   print("ctx: " .. vim.inspect(ctx))
      --               -- blink.cmp example shows this block:
      --               --   if vim.bo.filetype == "markdown" then
      --               --     return { " ", "\n", "\t", ".", "/", "(", "[" }
      --               --   end
      --               return { " ", "\n", "\t" }
      --             end
      --           } }
      --   - I also tried disabling show_on_trigger_character but it doesn't
      --     seem to do anything? (Or I just didn't bother grokking it fully.)
      --     In any case, I don't notice a diff. whether on or off:
      --       opts.completion.trigger.show_on_trigger_character = false
      --   - And setting show_on_keyword = false is too much, it disables
      --     completion from triggering at all:
      --       -- Works, but then you have to <Ctrl-Space> to show completion.
      --       opts.completion = { trigger = { show_on_keyword = false } }
      --     CXREF:
      --     ~/.local/share/nvim_lazyb/lazy/blink.cmp/doc/configuration/reference.md @ 57
      -- - ALTLY: The current approach is specifically limited to "--" only,
      --   but we could instead inhibit showing completion menu when user is
      --   editing comments (and then they'd need to use <Ctrl-Space> to show
      --   it):
      --     opts.completion = { menu = { auto_show = M.auto_show_except_within_comments } }
      -- - CALSO: We could also customize cmdline completion, though I haven't
      --   felt a need to modify its behavior. E.g.,
      --     opts.cmdline.completion = { menu = { auto_show = M.auto_show_except_when } },
      --
      -- TL_DR: Inhibit completion menu when cursor is immediately after Lua
      -- comment leader "--".
      -- - This could be a simple one-liner:
      --     opts.completion = { menu = { auto_show = M.auto_show_except_when } }
      --   But if you can't tell by now, I like to comment profusely,
      --   so we'll use an expanded table with more comments.

      opts.completion = {
        menu = {
          -- auto_show: "Whether to automatically show the window when new
          --             completion items are available"
          -- - I assume used in coordination with the trigger{} settings:
          --   https://cmp.saghen.dev/configuration/reference.html#completion-trigger
          -- DUNNO: The auto_show callback is called every other <Down>.
          -- - E.g., consider I have copied the same line multiple times,
          --   then I enter Insert mode and move the cursor over a keyword,
          --   and blink shows the completion menu. If I <Down> to the next
          --   copy of the same line, the completion menu disappears (but
          --   enabled() callback called). If I <Down> again, the completion
          --   menu reappears (enabled() called, then auto_show() called).
          -- - Same behavior with auto_show=true.
          -- - This feels buggy. And I don't think it's the config herein.
          --   - It might be because using arrow keys? The blink.cmp docs
          --     suggest that completion appears after *typing* keyword
          --     character. It does not say what happens after *cursoring*.
          --   - I tried `autocmd CursorMoved`, but it doesn't fire
          --     consistently on arrow keys like it does h/j/k/l.
          --   - Though note docs say auto_show runs "when new completion
          --     items are available", so perhaps you'd need to investigate
          --     what causes blink.cmp to request completion items.
          --   - ORNOT: Because our arrow maps call M.cancel_and_debounce(),
          --     which hides completion but might show it again, it
          --     doesn't matter if auto_show is called on every arrow
          --     press, because cancel_and_debounce() handles it correctly.
          auto_show = M.auto_show_except_when,
        },

        -- FEATR: Don't auto-show completion when entering Insert mode.
        -- - REFER: "When both this and show_on_trigger_character are true,
        --   will show the completion window when the cursor comes after a
        --   trigger character when entering insert mode".
        -- - CALSO: signature.trigger.show_on_insert_on_trigger_character,
        --   albeit Noice handles signatureHelp:
        --     trigger = { show_on_insert_on_trigger_character = true }
        -- - So we might show signature help immediately when entering
        --   insert mode (and, e.g., cursor is after "("), but we won't
        --   show completion (which I don't find helpful, because
        --   generally when I enter Insert mode, I'm editing something
        --   that already works, and I don't need completion suggestions;
        --   but it can be nice to see signature help).
        trigger = { show_on_insert_on_trigger_character = false },

        -- CALSO: Some other opts.completion{} options you might want to adjust:
        --
        --   accept = { auto_brackets = { enabled = false } },
        --
        --   -- REFER:
        --   -- https://cmp.saghen.dev/configuration/completion#list
        --   list = { selection = { preselect = false, auto_insert = true } },
        --
        --   -- "Show documentation when selecting a completion item"
        --   documentation = { auto_show = true, auto_show_delay_ms = 500 },
        --
        --   -- "Display a preview of the selected item on the current line"
        --   ghost_text = { enabled = true },
      }

      -- COPYD:
      -- https://cmp.saghen.dev/recipes#completion-menu-drawing
      --
      --   opts.completion.menu = {
      --     draw = {
      --       components = {
      --         kind_icon = {
      --           ellipsis = false,
      --           text = function(ctx)
      --             local kind_icon, _, _ = require("mini.icons").get("lsp", ctx.kind)
      --             return kind_icon
      --           end,
      --           -- Optionally, you may also use the highlights from mini.icons
      --           highlight = function(ctx)
      --             local _, hl, _ = require("mini.icons").get("lsp", ctx.kind)
      --             return hl
      --           end,
      --         },
      --       },
      --     },
      --   },

      -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

      return opts
    end,

    keys = {
      -- Remaining <leader>u{char} bindings not assigned by LazyuVim:
      --   <leader>[uB|uH|uj|uJ|uk|uK|uM|uN|uo|uO|uP|uq|uQ|uR|uu|uU|uv|uV|uX|uy|uY]

      -- DUNNO: Is there a better way to toggle completion enablement?
      -- - Like a vim.lsp.??? setting?
      {
        "<leader>uk",
        mode = { "n" },
        function()
          vim.g.blink_cmp_enabled = not vim.g.blink_cmp_enabled
          vim.notify("blink.cmp " .. (vim.g.blink_cmp_enabled and "enabled" or "disabled"))
        end,
        desc = "Toggle Completions",
        -- SPIKE: Convert this keymap to which-key.add, and
        -- then see if this `desc = function()` works.
        -- - FTREQ: Change which-key "desc" based on toggle value.
        --   - SPIKE: How do you change desc based on state?
        --   - This func breaks the map, though docs suggest a fcn should work
        --     (though searching LazyVim, I don't see *any* desc = function()
        --     usage; or maybe it only works via require("which-key").add(),
        --     and not via lazy.nvim spec):
        -- desc = function()
        --   return vim.g.blink_cmp_enabled and "Toggle Completions Off" or "Toggle Completions On"
        -- end,
      },

      -- FEATR: Remap <C-k>, so digraph insertion works from <C-l>.
      -- HSTRY/2017-06-06: Because author uses <C-j> and <C-k> for buffer surfing.
      -- - 2025-03-03: In LazyVim, <C-k> is blink.cmp Show Signature (and buf-ring
      --   bwd/fwd at <C-;> and <C-'>, in both Insert and Normal modes, because
      --   LazyVim uses Normal mode <C-j> and <C-k> for window jumping).
      {
        "<C-l>",
        "<C-k>",
        desc = "Enter digraph",
        mode = { "i" },
        noremap = true,
      },

      -- BUGGN/2025-03-12: Sometimes when completion dropdown loses focuses (and is
      -- not explicitly <Ctrl-e> closed), it'll orphan its ghost/virtual/extmark text.
      -- - SPIKE: I assume the fault is in blink.cmp, so hunt for an open issue
      --   on the topic.
      -- In the meantime, something like this to clear extmarks and remove orphans.
      {
        -- Built-in <M-l> just like |l|, though stops Insert mode first.
        -- - MAYBE: Find a different lhs. Using <M-l> for now,
        -- - MAYBE: Is this the best spot for this map def'n?
        alt_keys.lookup("l"),
        function()
          vim.api.nvim_buf_clear_namespace(0, -1, 0, -1)
        end,
        desc = alt_keys.AltKeyDesc("Clear Orphan Extmarks (Kludge)", "<M-l>"),
        mode = { "n", "i" },
        noremap = true,
      },
    },
  },
}
