-- vim:tw=0:ts=2:sw=2:et:ai:ft=lua
-- Author: Landon Bouma <https://tallybark.com/>
-- Project: https://github.com/landonb/nvim-lazyb#🧸

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

return {
  {
    dir = "~/.kit/nvim/embrace-vim/start/vim-blinky-search",
    event = "VeryLazy",

    init = function()
      -- Disable default maps (doesn't disable fcn'ality).
      vim.g.blinky_search_disable = true
    end,

    config = function()
      -- REFER: Blink-Search is composed of many maps: <F1>, <Shift-F1>, <F3>,
      -- <Shift-F3>, <F8>, \dc, \ds, possibly <CR>, and n, N, *, #, g*, and g#.

      -- SAVVY: Visual mode <F1> same as Visual mode <F3> — start
      -- g*-like search and match forward.
      -- - CALSO: <S-F1>, <F8>, and <ENTER> start (g)*-like search but stay put.
      --   - <S-F1> and <Enter> are strict (like star); whereas
      --     <F8> is not strict (like gstar).
      --   - <F8> and <Enter> are multi-case, e.g., fooBar matches foo-bar
      -- - CALSO: The dubs_grep_steady :grep search also support multi-case,
      --   which you can toggle via \dg (similar to this plugin's \dc toggle).
      --     ~/.kit/nvim/landonb/dubs_grep_steady/plugin/dubs_grep_steady.vim
      vim.fn["embrace#blinky_search#CreateMaps_GStarSearch"]("<F1>")
      vim.fn["embrace#blinky_search#CreateMaps_StarSearchStayPut"]("<S-F1>")
      vim.fn["embrace#blinky_search#CreateMaps_GStarSearchStayPut"]("<F8>")

      -- LATER/2025-03-21: Demo <CR> binding, maybe map elsewhere.
      -- - BWARE: blinky-search fallbacks normal <CR> only in quickfix.
      --   - In other special buffers (e.g., Project, Snacks Explorer),
      --     there's usually a local <CR> map that overrides the global
      --     map.
      --   - But in case there's not, this reminder, so you know to
      --     plumb another special exception into this map.
      -- - SAVVY:
      --   - LazyVim assigns xmap <BS> to tree-sitter Decrement Selection.
      --   - (I thought LazyVim assigned <CR> to something, too, but I
      --     didn't find anything... just FYI you may be playing with fire
      --     overriding the <CR> binding....)
      --      - E.g, some user's completion tools may use <CR> specially.
      --        - My old CoC config would test if the pum (popup menu)
      --          was showing, and it would select the current item if
      --          so, or fallback normal <CR> otherwise.
      -- LATER: Revisit this. Even though I haven't currently had any
      -- issues, I'm a little wary, especially when I start demoing
      -- more LSP and AI plugins/tools. So let's leave this off for
      -- now... though it should work, at least in normal usage.
      --
      --  vim.fn["embrace#blinky_search#CreateMaps_ToggleHighlight"]("<CR>")

      vim.fn["embrace#blinky_search#CreateMaps_SearchForward"]("<F3>")
      vim.fn["embrace#blinky_search#CreateMaps_SearchBackward"]("<S-F3>")
      vim.fn["embrace#blinky_search#CreateMaps_StarPound_VisualMode"]()
      -- Feature toggles.
      -- ISOFF/2025-03-04: There are better approaches to match blinking in Neovim.
      -- - HSTRY/2025-03-20: Blinky feature removed from plugin.
      --  vim.fn["embrace#blinky_search#CreateMaps_ToggleBlinking"]("<LocalLeader>dY")
      vim.fn["embrace#blinky_search#CreateMaps_ToggleMulticase"]("<LocalLeader>dc")
      vim.fn["embrace#blinky_search#CreateMaps_ToggleStrict"]("<LocalLeader>ds")

      -- Adjust normal mode search commands to center matches w/ |zz|.
      -- - Note we could map all the commands using a simple nnoremap
      --   that adds |zz|, e.g.,
      --     vim.fn["embrace#middle_matches#CreateMaps"]({
      --       \ 'n', 'N', '*', '#', 'g*', 'g#'})
      --   But we'll create the n and N maps ourselves, based on the
      --   LazyVim maps, which always search in the same direction
      --   (regardless of if you ran /- or ?-search). They also work
      --   in Operator pending and Visual modes, so you can use n/N
      --   to extend a Visual selection.
      --   - CXREF: See the n and N maps elsewhere, which we cannot
      --     load in this config() or they get overwritten by LazyVim:
      --       ~/.kit/nvim/landonb/nvim-lazyb/lua/config/keymaps.lua @ 1013
      -- - USAGE: I usually use <F1> and <F3> to search/match, which
      --   don't call |zz|, because I don't always want the window to
      --   scroll. But when I want to center matches, then I use * or
      --   n (we also include #, g*, and g#, but I rarely use those).
      vim.fn["embrace#middle_matches#CreateMaps"]({ "*", "#", "g*", "g#" })

      -- SAVVY: Doing this from 'keys = {}' spec doesn't work (tho dunno why not...).
      local wk = require("which-key")
      wk.add({
        mode = { "n", "i", "v" },
        { "<F1>", desc = "Start GStar Easy-Search and Jump" },
        { "<S-F1>", desc = "Start Star Easy-Search w/o Jump" },
        { "<F8>", desc = "Start GStar Easy-Search w/o Jump" },
        { "<CR>", desc = "Toggle Star Easy-Search Highlight" },
        { "<F3>", desc = "Next Search Match", icon = "󰓗" }, -- 󰖃
        { "<S-F3>", desc = "Previous Search Match", icon = "󰓕" },
        -- The plugin only adds Visual/Select mode * and # maps, but
        -- the Normal mode maps are not documented, so include 'em.
        { "*", desc = "Start Star Easy-Search", mode = { "n", "v" } },
        { "#", desc = "Start Pound Easy-Search", mode = { "n", "v" } },
        -- { "<LocalLeader>dY", desc = "Easy-Search Toggle Blinky" },
        { "<LocalLeader>dc", desc = "Easy-Search Toggle Multicase", icon = "" },
        { "<LocalLeader>ds", desc = "Easy-Search Toggle Whitespace Strictness", icon = "" },
      })
    end,

    keys = {
      -- The plugin has a :nohlsearch map, which defaults <C-h>, but LazyVim
      -- uses <C-h> for moving focus to the window on the left, and LazyVim
      -- uses <Esc> to clear the search highlight (which is quite genius, if
      -- not also quite obvious, in some respects!).
      -- - Default Normal mode <C-h> is same as <Left>, <BS>, or |h|.
      -- - Default Insert mode <C-h> is same as <BS> (and deletes back a char).
      -- I do like option to clear search highlights without leaving Insert mode...
      -- - SAVVY: To see Insert mode maps in which-key, press <Ctrl-r> to bring
      --   up registers window, then press <BS>.
      { "<C-h>", "<Cmd>nohlsearch<CR>", desc = "Clear hlsearch", mode = "i" },
      -- SAVVY: Note that <Cmd> is inherently silent, and works like this:
      --   { "<C-h>", "<C-O>:nohlsearch<CR>", desc = "Clear", mode = "i", silent = true },
      -- - Though I wonder if there are other nuanced differences between the two.
      --   - In any case, the <Cmd> approach is less verbose (if you don't count this comment =).
    },
  },
}
