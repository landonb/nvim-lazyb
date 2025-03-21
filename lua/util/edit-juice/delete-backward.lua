-- vim:tw=0:ts=2:sw=2:et:ai:ft=lua
-- Author: Landon Bouma <https://tallybark.com/>
-- Project: https://github.com/landonb/nvim-lazyb#🧸

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

---@class lazyb.util.edit-juice.delete-backward
local M = {}

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

-- Delete to start of word.
--
-- - HSTRY/2020-05-13: I've been using `db` the past 10 years, but
--   let's behave more elegantly when the cursor is at the beginning
--   or the end of the line.

function M.delete_back_word()
  -- Mimic `db`, but behave different at end of line, and at beginning.
  local mode = vim.api.nvim_get_mode().mode:sub(1, 1)
  local curr_col = vim.fn.col(".")
  local line_nbytes = vim.fn.getline("."):len()
  if curr_col == 1 then
    local was_ww = vim.o.whichwrap
    vim.o.whichwrap = "h"
    vim.cmd([[normal! dh]])
    if mode == "i" and line_nbytes == 0 then
      -- A `dh` on an empty line deletes the newline but moves the cursor one
      -- before the final character (probably because of virtualedit behavior),
      -- so jump to the final cursor position.
      -- DUNNO: Unsure why, but need to both `l` and to call nvim_win_set_cursor...
      vim.cmd([[normal l]])
      local cur_win = 0
      vim.api.nvim_win_set_cursor(cur_win, { vim.fn.line("."), vim.fn.col(".") + 1 })
    end
    -- E.g., "<,>,[,],b,s"
    vim.o.whichwrap = was_ww
  else
    local curpos = vim.fn.getcurpos()
    local i_curswant = 5 -- 1-based Lua arrays
    local curswant = curpos[i_curswant]
    local last_col = vim.fn.virtcol("$")

    local last_pttrn = vim.fn.getreg("/")
    -- vim.o.hlsearch is true|false and vim.v.hlsearch is 1|0.
    --  local hlsearch = vim.o.hlsearch and vim.v.hlsearch
    vim.fn.setreg("/", "\\(\\(\\_^\\|\\<\\|\\s\\+\\)\\zs\\|\\>\\)")
    vim.cmd([[normal! dN]])
    -- stylua: ignore
    if (
      (mode == 'i' and curswant >= last_col)
      or (mode == 'n' and (curswant + 1) >= last_col)
    ) then
      if mode == 'n' then
        -- The final character escaped the dN motion. Delete it.
        vim.cmd([[normal! x]])
      end
      -- Weird: I'm seeing getcurpos() report incorrect curswant.
      -- E.g., if the line is
      --         foo bar
      -- and I C-BS to delete the 'bar' in insert mode, so what's
      -- left is 'foo ', and the cursor is after the space, the
      -- curswant should be 5, but getcurpos says 4. If I hit
      -- '$' though, the cursor does not move, but curswant updates
      -- to 5. So ensure curswant is accurate if this function
      -- called again.
      vim.cmd([[normal! $]])
      -- Dunno: I ported this code from Vimscript, and now call via
      -- vim.keymap.set(..., function() ... end), and from Insert mode,
      -- when you delete from the last column, the previous call,
      -- `vim.cmd([[normal! $]])`, doesn't move the cursor, which
      -- remains one column before the last column. Fortunately,
      -- nvim_win_set_cursor works.
      -- - Though also need this `l`, what's going on?
      if mode == 'i' then
        vim.cmd([[normal l]])
        local cur_win = 0
        vim.api.nvim_win_set_cursor(cur_win, {vim.fn.line("."), vim.fn.col('.') + 1})
      end
    end
    vim.fn.setreg("/", last_pttrn)
    -- In LazyVim (I'm not sure which plugin does this), even though
    -- we restore the search register (and the user sees the same
    -- search matches highlighted), the current line shows our setreg
    -- pattern from above as ghost text at the end of the line, e.g.,
    --         ...     ?\(\(\_^\|\<|\s\+\)\zs\|\>\)   [>99/>99]
    -- - SPIKE: Determine what plugin does this.
    -- Clearing the search highlight doesn't hide the ghost text:
    --   vim.cmd.nohlsearch()
    -- Nor does enabling search highlights for the restored "/" register:
    --   if hlsearch == 1 then
    --     vim.o.hlsearch = true
    --   end
    -- Nor does mimicking LazyVim <Esc> binding ("Escape and Clear hlsearch"):
    --   vim.cmd("noh")
    --   LazyVim.cmp.actions.snippet_stop()
    -- KLUGE: But for some reason, emitting a space works (and thankfully
    -- doesn't ellicit noice notification popup).
    print(" ")
    vim.cmd("nohlsearch")
  end
  -- Hide the completion menu, otherwise user might delete word
  -- after ghost test, which makes it more difficult to see the
  -- edit, and to keep deleting if they need to.
  pcall(function()
    require("blink-cmp").hide()
  end)
end

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

-- Enhanced `d<Home>` motion.
-- - When cursor is in second or greater column, delete from the cursor
--   back to the start of the line, just like `d<HOME>`.
--   - Except handle edge case when in normal mode where cursor is atop the
--     final column, and don't not delete the final character like `d<Home>`
--     (the 'x', below, deletes the final character that `d0` misses).
-- - When cursor is in first column, delete the line above.
--   - This feels like the most natural behavior for this motion.
--   - We could alternatively do nothing, like `d0`/`d<HOME>`, and 'stop'
--     when the cursor is at the first column (so, e.g., pressing C-S-BS
--     deletes to the start of the line, but then every C-S-BS after that
--     does nothing until the user moves the cursor). But this feature
--     feels more powerful/useful if it can be used to keep deleting lines.
--   - The delete-the-line-above behavior adds another quick-line-delete
--     option, like `dd`, but the user will not have to leave insert mode.
--   - We can also take this behavior one step further, such that if/when
--     the cursor is at the beginning of the buffer (in the first column
--     on the first line), C-S-BS will start behaving just like `dd`, and
--     can be used to trim leading lines one-by-one. E.g., you could C-S-BS
--     on a line to delete to its start, then hit C-S-BS again to delete the
--     line above, etc., until the cursor moved up to the first line, and then
--     each C-S-BS after than deletes the current (first) line, shortening the
--     the file (buffer) every time, until the buffer itself is empty -- and
--     all it would take to clear the entire buffer would be n+1 C-S-BS
--     presses, where n is the number of lines originally in the file.

function M.delete_back_line()
  -- SAVVY: <c-g>u starts a new Undo set, so the deletion can be undone.
  -- - REFER: :help undo-break
  -- - BWARE: Note that running <c-g>u moves the cursor, e.g., if the
  --   user <S-C-W>'s from the end of a line and this fcn. starts with:
  --     execute "normal i\<C-g>u\<ESC>"
  --   then the final 2 chars from that line are left behind.
  --   - So use the other trick to close the undo block, assign to undolevels:
  --let &g:undolevels = &g:undolevels
  vim.g.undolevels = vim.g.undolevels

  -- Mimic `d<Home>`, but behave better at end of line.
  local curr_col = vim.fn.col(".")
  local line_nbytes = vim.fn.getline(vim.fn.line(".")):len()
  if curr_col == 1 then
    if vim.fn.line(".") > 1 then
      vim.cmd([[normal! k]])
    end
    -- If the line has leading whitespace, Vim will put the cursor over
    -- the first visible character, so ensure cursor finishes on col 1
    -- by running `0` after the `dd`.
    vim.cmd([[normal! dd0]])
  else
    vim.cmd([[normal! d0]])
    if curr_col >= line_nbytes then
      vim.cmd([[normal! x]])
    end
  end
end

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

function M.delete_char()
  local line = vim.fn.getline(".")
  if string.match(line, "^%s*$") then
    vim.cmd([[normal dd0]])

    return
  end

  local column = vim.fn.col(".")
  local right = ""

  if column ~= 1 and column ~= line:len() then
    right = "l"
  end

  vim.cmd([[silent! execute "normal! i\<Del>\<Esc>]] .. right .. [["]])
end

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

return M
