-- vim:tw=0:ts=2:sw=2:et:ai:ft=lua
-- Author: Landon Bouma <https://tallybark.com/>
-- Project: https://github.com/landonb/nvim-lazyb#🧸

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

-- Don't show *tabline* buffer list at the top; show only tabpages instead.
--
-- USAGE: Toggle on/off in LazyVim: <Leader>uA
--
-- - BUGGN: Except that bufferline will reappear after some commands.
--   - E.g., if you `:set showtabline=0` and then run `:copen` (to show
--     the quickfix window), the tabline reappears.
--
-- - INERT: Add toggle for changing mode: "tabs" ↔ "buffers".
--   - I don't see require("bufferline") or :BufferLine command to change
--     at runtime, at least not in help (you could still dig into sources),
--     but `:Lazy reload bufferline.nvim` works. (So you could at least
--     call `require('bufferline').setup(new_opts)` to impl. such a toggle.)
--
-- REFER: |'showtabline'| aka |'stal'| ["stal"?!]
--
-- REFER: |bufferline.nvim|
-- - *A snazzy bufferline for Neovim*
--   https://github.com/akinsho/bufferline.nvim
--
-- SAVVY: |setting-tabline|
-- - The tabline is manageg similarly to statusline.
-- - The tabline is not a window.
--
-- UCANT: Note that bufferline.nvim manages |showtabline|, e.g., you
-- cannot `vim.opt.showtabline = 0` to disable the tabline, as the
-- plugin will change that value.

return {
  -- CXREF: See upstream LazyVim bufferline.nvim config:
  -- ~/.local/share/nvim_lazyb/lazy/LazyVim/lua/lazyvim/plugins/ui.lua @ 2
  {
    "akinsho/bufferline.nvim",

    -- DUNNO: Out of curiosity, I thought I could disable this plugin,
    -- but neither of these does so (it stills loads on VeryLazy).
    --
    --   event = nil,
    --   lazy = true,

    opts = {
      options = {
        -- Mode defaults "buffers", or you can limit to just "tabs".
        --
        -- - For numerous reasons, mostly because the bufferline redraws twice
        --   when I toggle a window (such as quickfix, Snacks Explorer, :mess,
        --   etc., as the cursor moves to the new window, then back to the old
        --   one), which I find distracting; and also because bufferline shows
        --   redundant info. (e.g., you'll find diagnostics in the statusline,
        --   which is also easier to find visually (there's a statusline for
        --   every buffer window just below the buffer in nvim-lazyb, whereas
        --   you need to visually scan the bufferline to locate the buffer
        --   name)) and it doesn't offer any command I find compelling (e.g.,
        --   deleting buffers to the right/left would require that I had opened
        --   buffers in a particular order (the drag-rearrange feature doesn't
        --   work for me); and I almost never delete buffers, why bother), we'll
        --   restrict bufferline to only show tabpages, and to only appear when
        --   more than one tabpage exists. (This is not a rant and not meant to
        --   disparage all the hard work that went into bufferline.nvim — it's
        --   a very elegant, good-looking plugin! — the "tabs" feature just is
        --   not for me. We all have our own tastes — that's why we vim! I also
        --   wanted to explain the particulars that led me to this decision.)
        mode = "tabs",
      },
    },
  },
}
