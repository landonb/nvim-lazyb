-- vim:tw=0:ts=2:sw=2:et:ai:ft=lua
-- Author: Landon Bouma <https://tallybark.com/>
-- Project: https://github.com/landonb/nvim-lazyb#🧸

-- ISOFF/2025-02-26: LazyVim switched default completion to blink.cmp.
-- - Though you could enable nvim-cmp as an Extra.
-- - SPIKE/2025-02-28: Try nvim-cmp, maybe, so you can disable
--   completion when in comments.
-- - SPIKE/2025-03-18: blink.cmp also triggers completion after
--   Lua comment leader, "--", which is also annoying.
--
-- stylua: ignore
if true then return {} end

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

return {
  -- override nvim-cmp and add cmp-emoji
  {
    "hrsh7th/nvim-cmp",
    dependencies = { "hrsh7th/cmp-emoji" },

    ---@param opts cmp.ConfigSchema
    opts = function(_, opts)
      -- Enable cmp-emoji
      table.insert(opts.sources, { name = "emoji" })

      -- REFER: *Disabling completion in certain contexts, such as comments*
      -- https://github.com/hrsh7th/nvim-cmp/wiki/Advanced-techniques#disabling-completion-in-certain-contexts-such-as-comments
      opts.enabled = function()
        -- disable completion in comments
        local context = require("cmp.config.context")
        -- keep command mode completion enabled when cursor is in a comment
        if vim.api.nvim_get_mode().mode == "c" then
          return true
        else
          -- stylua disable
          return not context.in_treesitter_capture("comment")
            and not context.in_syntax_group("Comment")
        end
      end
    end,
  },
}
