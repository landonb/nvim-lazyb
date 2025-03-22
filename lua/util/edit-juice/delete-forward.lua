-- vim:tw=0:ts=2:sw=2:et:ai:ft=lua
-- Author: Landon Bouma <https://tallybark.com/>
-- Project: https://github.com/landonb/nvim-lazyb#🧸

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

---@class lazyb.util.edit-juice.delete-forward
local M = {}

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

M._trace_level = 0
-- USAGE: Uncomment to see trace messages.
--
--  M._trace_level = 1

function M.trace(msg)
  if M._trace_level <= 0 then
    return
  end

  print(msg)
end

function M.trace_vars(msg, mode, curs_col, curr_col, line_len_plus_one, last_col)
  if M._trace_level <= 0 then
    return
  end

  M.trace(
    msg
      .. " / mode: "
      .. mode
      .. " / curs_col: "
      .. vim.inspect(curs_col)
      .. " / curr_col: "
      .. vim.inspect(curr_col)
      .. " (line_len_plus_one: "
      .. vim.inspect(line_len_plus_one)
      .. ") / last_col: "
      .. vim.inspect(last_col)
  )
end

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

-- ------------------------------------------------------
-- A Delicious Delete
-- ------------------------------------------------------

-- In EditPlus, Ctrl-Delete deletes characters
-- starting at the cursor and continuing to the
-- end of the word, or until certain punctuation.
-- If the cursor precedes whitespace instead of a
-- non-whitespace character, Ctrl-Delete just
-- deletes the continuous block of whitespace,
-- up until the next non-whitespace character.
--
-- In Vim, the 'dw' and 'de' commands perform
-- similarly, but they include whitespace, either
-- after the word is deleted ('dw'), or before
-- it ('de'). Here we bake our own delete-forward
-- using `dn` and a specially-crafted @/ regex
-- to get the deletion *just* right.
--
-- We also handle other special cases, such as
-- when the cursor is at the end of the line,
-- which is tricky in Vim because of how the two
-- modes, insert and normal, behave, and because
-- virtualmode. Also the special case of an empty
-- line. And a few others. Tricky, tricky business.

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

function M.Del2EndOfWsAz09OrPunct(deleteToEndOfLine)
  local mode = vim.api.nvim_get_mode().mode:sub(1, 1)
  local curs_col = vim.fn.virtcol(".")
  local orig_line = vim.fn.getline(".")
  M.DeleteForwardLogically(deleteToEndOfLine, mode, curs_col, orig_line)
  M.FixCursorIfAtEndOfLine(curs_col, orig_line)
  -- Hide the completion menu, otherwise user might delete word
  -- after ghost test, which makes it more difficult to see the
  -- edit, and to keep deleting if they need to.
  pcall(function()
    require("blink-cmp").hide()
  end)
end

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

function M.DeleteForwardLogically(deleteToEndOfLine, mode, curs_col, orig_line)
  local curr_col = vim.fn.col(".")
  local line_len_plus_one = vim.fn.col("$")
  local last_col = vim.fn.virtcol("$")

  if deleteToEndOfLine == 0 and orig_line == "" then
    vim.cmd([[normal! "_dd]])
    M.trace_vars("dd-deleted line", mode, curs_col, curr_col, line_len_plus_one, last_col)

    return
  end

  if deleteToEndOfLine == 0 and curr_col == line_len_plus_one then
    -- Use case: Cursor is at the end of the line, so at least delete
    -- the newline... and might as well Join (delete-forward normally
    -- gobbles whitespace, so we should gobble newline and leading
    -- whitespace from next line; with |J|, we'll also remove the
    -- comment leader, a bonus).
    -- - Use case: Cursor is on empty line, e.g.,
    --     vim.fn.getline("."):len() == 0
    --   (in which case vim.fn.col(".") == vim.fn.col("$") == 1)
    vim.cmd([[normal! J]])
    M.trace_vars("J-joined from EOL", mode, curs_col, curr_col, line_len_plus_one, last_col)

    return
  end

  if curr_col + 1 == line_len_plus_one then
    -- Use case: Cursor is in the penultimate column. Just delete
    -- the last character (and later we'll fix the cursor pos.).
    vim.cmd([[normal! "_x]])
    M.trace_vars("x-deleted final char", mode, curs_col, curr_col, line_len_plus_one, last_col)

    return
  end

  if deleteToEndOfLine == 1 then
    vim.cmd([[normal! "_d$]])
    M.trace_vars("d$-deleted to EOL", mode, curs_col, curr_col, line_len_plus_one, last_col)

    return
  end

  M.DeleteForwardWord()
end

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

-- SAVVY: (lb): I use a search pattern in another plugin I maintain
--       that implements meta- and arrow-based motion selection,
--       vim-select-mode-stopped-down, which looks like this:
--         let @/ = "\\(\\(\\_^\\|\\<\\|\\s\\+\\)\\zs\\|\\>\\)"
--       which we can repurpose here to delete words. But note that
--       the final "\\>" tickles an edge case when trying to delete
--       the last word in a line: it leaves the last character behind.
--       - So remove the \>, but with the caveat that when you
--         C-Del the last word from a line, the newline is also removed,
--         and the cursor moves to the first visible character.
--         (lb): This is not quite in line with how I would naturally
--         expect this operation to behave -- e.g., imagine two words
--         on the line, 'foo bar', if you ctrl-del from the first
--         column 'foo ' is removed; and then I'd expect another
--         ctrl-del to delete the 'bar', but here it deletes the
--         'bar\n', which I think should be two separate operations.
--         Nonetheless, I've already invested enough time in this
--         function today (2020-05-14) so calling it good (at least
--         for another 5-10 years, because this function, per a comment
--         I deleted today, was writ '2010.01.01', and remained largely
--         untouched since 2015; a staple in my repertoire, for sure,
--         but not something that has to behave exactly how I want;
--         but something that, after years of enough wanting, I'll
--         finally get around to tweaking).
--       - Here's the regex without the final \\>, end-of-word boundary
--         match, but we can move it inside the regex, like so:
--           let @/ = "\\(\\(\\_^\\|\\<\\|\\>\\|\\s\\+\\)\\zs\\)"
--         However, that leaves an edge case with the final word on the
--         line, where all but the last character are deleted.
--         So add a not-followed-by-newline [^\\n] check,
--         and sprinkle the \zs sets-start-of-match appropriately,
--         which lets us check not-newline without using a lookahead.
function M.DeleteForwardWord()
  local last_pttrn = vim.fn.getreg("/")
  -- Match:
  --   at beginning of line;
  --   at beginning of word boundary;
  --   at end of word boundary but not end of line (otherwise the final word
  --     is not fully deleted, but the final character remains undeleted); or
  --   a block of whitespace, but also not ending before a newline,
  --     for the same reason given previously.
  -- stylua: ignore
  vim.fn.setreg("/", ""
    .. "\\(\\_^\\zs"
    .. "\\|\\<\\zs"
    .. "\\|\\>\\zs[^\\n]"
    .. "\\|\\s\\+\\zs\\S"
    .. "\\)")
  -- Here's the same on one line, for easy copy-paste, or ::<CR>.
  --  let @/ = "\\(\\_^\\zs\\|\\<\\zs\\|\\>\\zs[^\\n]\\|\\s\\+\\zs\\S\\)"
  vim.cmd([[normal! "_dn]])
  vim.fn.setreg("/", last_pttrn)
  vim.cmd.nohlsearch()
  -- Clear the ghost text (extmark) user now sees after last column:
  --   ...     /\(\_^\zs\|\<\zs\|\>\zs[^\n]\|\s\+\zs\)    [>99/>99]
  -- KLUGE: This empty print does the trick, but not vim.cmd("nohlsearch")
  print(" ")
  -- Trace after the print() or user won't see it (unless they :mess).
  M.trace("_db deleted fwd using @/ pattern")
end

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

-- If we bopped outta insert mode to run the deletion and are returning
-- to insert mode, it's tricky to get the cursor back to where we want.
-- - If we did not join lines and if we deleted everything from the
--   cursor until the end of the line, the default Vim behaviour puts
--   the insert mode cursor in the penultimate position (because Vim
--   generally moves the cursor back one when transitioning from normal
--   to inert mode).
--   - We could use `$` here, which sets `curswant` very large, which
--     would essentially move the cursor to the last column -- but
--     then if the user moves the cursor to the line above or to
--     the line below, the cursor shoots off to the right if it can.
--     Which is annoying if you're using this feature to delete the ends
--     of multiple lines from the same column, e.g., if you're typing
--     <Ctrl-Shift-Delete> <Down> <Ctrl-Shift-Delete> <Down>, etc.
--   - We cannot use <Right> or call, say, `normal l` either, because,
--     technically, since we bopped out to normal mode, the cursor
--     *is* in the final column position! (So a <Right> would move the
--     cursor to the nexst line, and an `l` might blink the screen,
--     (unless whichwrap) because the cursor cannot move further right.)
--   - I tried using a mark as a work-around, as suggested by this post:
--       https://sanctum.geek.nz/arabesque/vim-annoyances/
--     e.g., instead of just ‘gJ’, call ‘mzJg`z’. But this has same issue,
--     and the insert cursor still appears leftward one column of desired.
--   - I first tried calling cursor() with a [List] that included curswant,
--     and then setpos() with the same, but it seems a simple cursor with
--     just two parameters, lnum and col, is sufficient (where lnum==0
--     means to 'stay in the current line').
function M.FixCursorIfAtEndOfLine(curs_col, orig_line)
  if curs_col == 1 then
    -- Use case: Vim will move the cursor to the first visible character,
    -- but the user had the cursor in the first column and deleted from
    -- there, so don't move the cursor from there.
    vim.cmd([[normal! 0]])
  elseif vim.startswith(orig_line, vim.fn.getline(".")) then
    -- Use case: The cursor is in the final column and we want the insert
    -- mode cursor to reappear after the final character when this command
    -- finishes.
    -- - HSTRY: The if-condition used to check virtcol, e.g.,
    --     local mode = vim.api.nvim_get_mode().mode:sub(1, 1)
    --     ...
    --     elseif (mode == "i") and (vim.fn.virtcol(".") + 1) == vim.fn.virtcol("$") then
    --     ...
    --   - But this does not distinguish between final two columns.
    --   - So now we use startswith() and see if user deleted the end
    --     of the line (and then we know cursor should be at the end).
    -- - SAVVY: Note that <Right> does not work here, because Vim re-enters Insert
    --   mode *after* the map finishes, which moves cursor one before final column.
    --     vim.cmd([[normal l]])
    --   Fortuantely we can set_cursor instead.
    -- - ALTLY: Here's the equivalent-ish Vim call:
    --     vim.fn.cursor(0, vim.fn.col('.') + 1)
    local cur_win = 0
    vim.api.nvim_win_set_cursor(cur_win, { vim.fn.line("."), vim.fn.col(".") + 1 })
  end
end

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

return M
