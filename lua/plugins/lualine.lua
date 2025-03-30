-- vim:tw=0:ts=2:sw=2:et:ai:ft=lua
-- Author: Landon Bouma <https://tallybark.com/>
-- Project: https://github.com/landonb/nvim-lazyb#🧸

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

-- CXREF:
-- ~/.local/share/nvim/lazy/LazyVim/lua/lazyvim/plugins/ui.lua
-- ~/.local/share/nvim/lazy/lualine.nvim/lua/lualine.lua

-- local function hello()
--   -- return [[hello world]]
--   return [[]]
-- end
--
-- local function hello_a()
--   --let l:statline .= '%{g:embrace#mescaline#MescalinePrintClockTime()}'
--   --let l:statline .= "\\ \\ "
--   return [[%#MescalineF3Clock#]]
-- end
--
-- local function hello_b()
--   return [[%#MescalineF4Buffer#]]
-- end

local function window_number()
  -- return "%#MescalineF3Clock#" .. vim.api.nvim_win_get_number(0)
  --return "%#MescalineF3Clock#███" .. vim.api.nvim_win_get_number(0) .. "%#MescalineF4Buffer#███"
  return "%#MescalineF3Clock#██%#MescalineF4WinNum#"
    .. vim.api.nvim_win_get_number(0)
    .. "%#MescalineF3Clock#██"
end

return {
  -- AFAICT/2025-02-22: The x position is unused, it appears.
  -- - It's to the right of the diagnostics and left of the file posit, and time.
  --
  -- the opts function can also be used to change the default opts:
  -- {
  --   "nvim-lualine/lualine.nvim",
  --   event = "VeryLazy",
  --   opts = function(_, opts)
  --     table.insert(opts.sections.lualine_x, {
  --       function()
  --         return "😄"
  --       end,
  --     })
  --   end,
  -- },

  -- or you can return new options to override all the defaults
  -- {
  --   "nvim-lualine/lualine.nvim",
  --   event = "VeryLazy",
  --   opts = function()
  --     return {
  --       [>add your custom lualine config here<]
  --     }
  --   end,
  -- },

  {
    "nvim-lualine/lualine.nvim",

    -- MAYBE: Make lualine mode names user-configurable, and PR the change.
    -- - CXREF: See `local mode_to_highlight`:
    --     ~/.local/share/nvim_lazyb/lazy/lualine.nvim/lua/lualine/highlight.lua
    -- - CXREF: See `Mode.map`
    --     ~/.local/share/nvim_lazyb/lazy/lualine.nvim/lua/lualine/utils/mode.lua
    build = require("util").lazy_build_fork("lualine.nvim", "master"),

    --opts = function(_, opts)
    -- hi MescalineF3Clock guifg=#005f00 guibg=#52B788
    -- hi MescalineF4Buffer guifg=#52B788 guibg=#333138
    --
    -- 
    -- options = {
    --   section_separators = { left = '', right = '' },
    --   component_separators = { left = '', right = '' },
    -- }
    --               color = { fg = "#ffaa88", bg = "grey", gui = "italic,bold" },
    init = function()
      -- #ffaa88 is *atomic tangerine*
      -- #a1c181 is *olivine*
      -- #719150 is *asparagus*
      -- vim.cmd([[hi MescalineF3Clock guifg=#ffaa88 guibg=grey]])
      -- vim.cmd([[hi MescalineF4Buffer guifg=grey guibg=#333138]])
      -- vim.cmd([[hi MescalineF4WinNum guifg=grey guibg=#ffaa88]])
      vim.cmd([[hi MescalineF3Clock guifg=#719150 guibg=#233D4D]])
      vim.cmd([[hi MescalineF4WinNum guifg=#233D4D guibg=#719150]])
    end,
    opts = {
      inactive_sections = {
        -- Don't work here, or not setup correctly:
        --  section_separators = { left = "", right = "" },
        --  component_separators = { left = "", right = "" },
        --lualine_a = { hello },
        --lualine_a = { hello_a },
        --lualine_a = { hello_a, padding = { left = 2, right = 2 } },
        -- lualine_a = { window_number },
        lualine_a = {
          { window_number, padding = { left = 0, right = 0 } },
        },
        lualine_b = {
          --{ hello_b },
          -- {
          --   "datetime",
          --   -- options: default, us, uk, iso, format string ("%H:%M", etc..)
          --   -- Default: E.g., "Friday, February 28 | 00:00"
          --   --  style = "default",
          --   style = "%H:%M",
          -- },
          -- {
          --   function()
          --     return " " .. os.date("%R")
          --   end,
          -- },
          {
            function()
              return "████"
            end,
            -- #ffaa88: https://paletton.com/#uid=12y0u0kemkc6QtFaRoohKfBmVcW
            color = { fg = "#3C5D1A", bg = "#060606" },
            padding = { left = 0, right = 0 },
          },
        },
        -- lualine_c = {'filename'},
        lualine_c = {
          {
            "filename",
            file_status = true, -- Displays file status (readonly status, modified status)
            newfile_status = false, -- Display new file status (new file means no write after created)
            path = 3, -- 0: Just the filename
            -- 1: Relative path
            -- 2: Absolute path
            -- 3: Absolute path, with tilde as the home directory
            -- 4: Filename and parent dir, with tilde as the home directory

            shorting_target = 40, -- Shortens path to leave 40 spaces in the window
            -- for other components. (terrible name, any suggestions?)
            symbols = {
              modified = "[+]", -- Text to show when the file is modified.
              readonly = "[-]", -- Text to show when the file is non-modifiable or readonly.
              unnamed = "[No Name]", -- Text to show for unnamed buffers.
              newfile = "[New]", -- Text to show for newly created file before first write
            },
            -- FIXME/LOPRI: vim.bo.modified not true in inactive window if
            -- cursor in another window showing the same buffer...
            -- - See *DUNNO* below for more details.
            -- - SAVVY: Here's how Mescaline does it (which is not super helpful
            --   because we need to suss it here and not defer to statusline):
            --     let l:statline .= "%." . l:avail_width
            --       \ . "f%{&ro?'\\ ':''}%{&mod?'\\ 🚩':''}%<"
            --
            -- DUNNO: This function causes Snacks Explorer and lualine to
            -- show a diagnostics.Hint icon: 
            -- - SPIKE: But why??
            -- SPIKE: How do you ignore diagnostic errors?
            -- - This stylua ignore doesn't work.
            -- stylua: ignore             o Lua diagnostics.: Unused local `section`.
            --  color = function(section)
            -- color = function()
            --   local winbufnr = vim.api.nvim_win_get_buf(vim.api.nvim_get_current_win())
            --   --print("vim.bo.modified: " .. vim.inspect(vim.bo.modified))
            --   --print("bufnr: " .. vim.inspect(vim.api.nvim_get_current_buf()))
            --   -- stylua: ignore
            --   -- print(
            --   --   "winnr:bufnr "
            --   --     .. vim.inspect(vim.api.nvim_get_current_win()) .. ":"
            --   --     .. vim.inspect(vim.api.nvim_get_current_buf()) .. "="
            --   --     .. winbufnr
            --   --     .. " / modified?: " .. vim.bo.modified
            --   -- )
            --   -- return { fg = vim.bo.modified and "#aa3355" or "#33aa88" }
            --   -- return { fg = vim.bo.modified and "#aa3355" or "#33aa88",
            --   --            bg = "#333138", gui = "italic" }
            --   -- return { fg = vim.bo.modified and "#aa3355" or "#33aa88", gui = "italic" }
            --   -- --return { fg = vim.bo.modified and "#FF0000" or "#00ff00", gui = "italic" }
            --   -- return {
            --   --   fg = vim.bo[vim.api.nvim_get_current_buf()].modified and "#aa3355" or "#33aa88",
            --   --   gui = "italic",
            --   -- }
            --   return {
            --     -- DUNNO: This is only true when you move cursor to other
            --     -- buffer window. E.g., if you have 3 windows open, and the
            --     -- same buffer is open in the first 2 windows, if you edit
            --     -- that buffer in one window, the other window shows the
            --     -- "[+]" marker, but vim.bo.modified is false and the 'or'
            --     -- runs here. But if you move the cursor to the third window
            --     -- with a different buffer in it, then the other 2 windows
            --     -- show the 'and' color here...
            --     -- - It happens with vim.api.nvim_get_current_buf() and
            --     --   nvim_get_current_buf(vim.api.nvim_get_current_win()).
            --     fg = vim.bo[winbufnr].modified and "#aa3355" or "#33aa88",
            --     gui = "italic",
            --   }
            -- end,
            -- I kinda like this color, orangy-grey...
            --color = { fg = "#ffaa88", bg = "grey", gui = "italic,bold" },
            -- #ffaa88 is *atomic tangerine*
            --color = { fg = "#ffaa88", gui = "italic" },
            -- #D8E4FF is *lavender (web)*
            -- color = { fg = "#D8E4FF", gui = "italic" },
            color = { fg = "#D8E4FF", bg = "#060606", gui = "italic,underline" },
          },
        },
        -- lualine_x = { window_number() },
        lualine_x = {
          { color = { bg = "#060606" } },
        },
        lualine_y = {
          --"location",
          {
            function()
              -- Seeing column is TMI.
              --   return "%p%% ☰%4l/%4L :%3c"
              -- Using fixed width column for "line/lines" worked well in
              -- depoxy-vim to avoid the statusline reformatting and
              -- distracting you as you scrolled around. But in nvim-lazyb
              -- this text is only shown in inactive windows, so it won't
              -- change -- and now the extra whitespace looks awkward.
              --   return "%p%% ☰%4l/%4L"
              return "%p%% ☰%l/%L"
            end,
            color = { bg = "#060606" },
          },
        },

        lualine_z = {
          {
            function()
              return " " .. os.date("%R")
            end,
            color = { bg = "#060606" },
          },
        },
      },
    },
  },
}
