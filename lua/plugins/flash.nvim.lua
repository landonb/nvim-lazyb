-- vim:tw=0:ts=2:sw=2:et:ai:ft=lua
-- Author: Landon Bouma <https://tallybark.com/>
-- Project: https://github.com/landonb/nvim-lazyb#🧸

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

-- CXREF:
-- https://github.com/folke/flash.nvim#-examples

---@class lazyb.plugins.flash-nvim
local M = {}

local Flash = require("flash")

-- *** 2-char jump impl.

-- "2-char jump, similar to mini.jump2d or HopWord (hop.nvim)"
-- - Whoa, this approach is interesting... using pattern [[\<]],
--   it labels *every word* with a two-character jump — so you
--   don't have to type search characters at all, you just jump.
-- - Note if you have enough windows open, only the first number
--   of windows will contain labels — so you can never jump to
--   lines in buffers in the higher numbered windows.
--   - The feature is still useful for line-jumping, e.g., using
--     the "^" pattern.

---@param pattern string
M.twoCharJump = function(pattern)
  Flash.jump({
    search = { mode = "search" },
    label = { after = false, before = { 0, 0 }, uppercase = false, format = M.format },
    pattern = pattern,
    action = M.action,
    labeler = M.labeler,
  })
end

---@param opts Flash.Format
M.format = function(opts)
  -- always show first and second label
  return {
    { opts.match.label1, "FlashMatch" },
    { opts.match.label2, "FlashLabel" },
  }
end

M.action = function(match, state)
  state:hide()
  Flash.jump({
    search = { max_length = 0 },
    highlight = { matches = false },
    label = { format = format },
    matcher = function(win)
      -- limit matches to the current label
      return vim.tbl_filter(function(m)
        return m.label == match.label and m.win == win
      end, state.results)
    end,
    labeler = function(matches)
      for _, m in ipairs(matches) do
        m.label = m.label2 -- use the second label
      end
    end,
  })
end

M.labeler = function(matches, state)
  local labels = state:labels()
  for m, match in ipairs(matches) do
    match.label1 = labels[math.floor((m - 1) / #labels) + 1]
    match.label2 = labels[(m - 1) % #labels + 1]
    match.label = match.label1
  end
end

return {
  {
    "folke/flash.nvim",
    -- event = "VeryLazy",
    config = function()
      local wk = require("which-key")
      wk.add({
        mode = { "n", "x", "o" },
        icon = "",
        { "<LocalLeader>l" },
        { "<LocalLeader>L" },
        { "<Leader>sf" },
      })
    end,
    keys = {
      -- Flash line works well enough... however:
      -- - FTREQ: Impl. 2-char jump...
      {
        "<LocalLeader>l",
        mode = { "n", "x", "o" },
        function()
          local pattern = "^"
          M.twoCharJump(pattern)
        end,
        desc = "Flash line",
      },
      {
        "<LocalLeader>L",
        mode = { "n", "x", "o" },
        function()
          Flash.jump({
            search = { mode = "search", max_length = 0 },
            label = { after = { 0, 0 } },
            pattern = "^",
          })
        end,
        desc = "Flash line 1-char",
      },
      {
        "<Leader>sf",
        mode = { "n", "x", "o" },
        function()
          local pattern = [[\<]]
          M.twoCharJump(pattern)
        end,
        desc = "Flash 2-char jump",
      },
    },
  },
}
