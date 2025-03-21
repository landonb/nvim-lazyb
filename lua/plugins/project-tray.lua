-- vim:tw=0:ts=2:sw=2:et:ai:ft=lua
-- Author: Landon Bouma <https://tallybark.com/>
-- Project: https://github.com/landonb/nvim-lazyb#🧸

local alt_keys = require("util.alt2meta-keys")

return {
  {
    dir = "~/.kit/nvim/landonb/dubs_project_tray",
    event = "VeryLazy",
    init = function()
      -- CXREF:
      -- ~/.kit/nvim/landonb/dubs_project_tray/plugin/dubs_project.vim @ 72
      vim.g.proj_flags = "imstB"

      vim.g.proj_create_maps = false
    end,

    -- FIXME:/2025-03-14: Opt-out force placement (play nice with Snacks Explorer).
    --
    -- - I think it's b:proj_locate_command and b:proj_resize_command
    --   that forces the project window to the left if it's moved.
    --   ~/.kit/nvim/landonb/dubs_project_tray/plugin/dubs_project.vim

    -- CXREF:
    -- ~/.kit/nvim/landonb/dubs_project_tray/plugin/dubs_project_tray.vim
    config = function()
      local wk = require("which-key")
      wk.add({
        -- CALSO: The <Shift-Alt> bindings are sorta related: they each
        -- hide and/or show a left-side or bottom-side window.
        -- - Use <Shift-Alt-2> aka <M-@> to close Noice overflow window (bottom).
        -- - Use <Shift-Alt-3> aka <M-#> to toggle Quickfix window (bottom).
        -- - Use <Shift-Alt-4> aka <M-$> to toggle Project window (left).
        {
          mode = { "n", "i" },
          -- BNDNG: <Shift-Alt-4> aka <Shift-Alt-$> aka <M-$> aka <›>
          alt_keys.lookup("$"),
          function()
            -- Note that :ToggleProject only works after you've run Project {path}
            -- (i.e., it only works after you've indicated the .vim_projects path).
            -- - So this won't always work:
            --   vim.cmd([[ToggleProject]])
            -- Run the <Plug>, instead.
            -- - Though I could not get vim.fn.execute to run \<Plug>, e.g.,
            --   vim.fn.execute("normal \\<Plug>DubsProjectTray_ToggleProject_Wrapper")
            --   vim.fn.execute([[normal \<Plug>DubsProjectTray_ToggleProject_Wrapper]])
            -- Fortunately, there's vim.cmd() instead.
            vim.cmd([[execute "normal \<Plug>DubsProjectTray_ToggleProject_Wrapper"]])
          end,
          noremap = true,
          silent = true,
          desc = alt_keys.AltKeyDesc("Toggle Project Window", "M-$"),
        },

        -- Resize windows with \dV
        -- -----------------------
        -- USAGE: You generally don't need this if you enable |'equalalways'|,
        -- though this is still helpful if something messes up window widths
        -- and you want to smooth it out without resizing the desktop window
        -- by dragging the window border or using, e.g., (macOS) Rectangle or
        -- some other mechanism to resize the application window.
        -- - It's also useful if you show Snacks Explorer, which doesn't cause
        --   a resize, and you want to resize the windows (though you don't
        --   need to bother when you close Snacks Explorer, because it'll
        --   resize the remaining windows automatically).
        --
        -- FIXME: Move this autoload# fcn. or promote to Lua (decouple from Project).
        {
          mode = { "n", "i" },
          -- BNDNG: <LocalLeader>dV aka \dV
          "<LocalLeader>dV",
          -- CXREF:
          -- ~/.kit/nvim/landonb/dubs_project_tray/autoload/embrace/vresize.vim
          "<cmd>call g:embrace#vresize#VerticalResizeNormalBufferWindowsEqually()<CR>",
          noremap = true,
          silent = true,
          desc = "Resize Windows Equally Vertically",
          icon = "",
        },
      })

      -- SAVVY: See Snacks spec for coordination between Project
      -- and Snacks Explorer, both of which prefer to use the
      -- leftside of the tabpage (i.e., winnr() == 1).
      -- - CXREF:
      --   ~/.kit/nvim/landonb/nvim-lazyb/lua/plugins/snacks.lua
      -- I originally hoped to hook an event to coordinate with
      -- Snacks Explorer, to avoid coupling the logic, but hooking
      -- WinEnter is too late.
      -- - By the time the callback runs, e.g.,:
      --     vim.api.nvim_create_autocmd("WinEnter", function() ... end)
      --   the Snacks Explorer window width is already incorrect (too wide)
      --   because of some interaction with the Project buffer/window. So
      --   we have to be preemptive before showing Snacks Explorer. (Though
      --   the reverse is not a problem — if you show Snacks Explorer and
      --   then Project, such that Project is on the left, everything's
      --   golden.)

      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("lazyb_project_tray", { clear = true }),
        pattern = { "project_tray" },
        callback = function()
          -- CXREF: CreateMaps_ProjectBuffer
          -- ~/.kit/nvim/landonb/dubs_project_tray/plugin/dubs_project.vim @ 1714
          wk.add({
            -- Base/Inherited values for nested mappings.
            mode = "n",
            noremap = true,
            buffer = true,
            silent = true,
            -- Before custom &ft added, project &filetype=conf, which causes
            -- which-key to show a  icon (at first I thought it was because
            -- these are buffer-local maps, but it's because the &ft; although
            -- buffer-local maps are sorted higher).
            icon = "",
            -- Nested mappings.
            -- BWARE: Use iconic angle brackets e.g., CR, not <CR>, because:
            --   "Open File (<CR>)" → which-key shows → Open File ()
            --   "Open File (<lt;>CR>)"   ''    shows → Open File (<lt>lt;>CR>)
            { "<CR>", desc = "Open File in Previous Window" },
            { "<S-CR>", desc = "Edit File in Horiz'ntl Split" },
            { "<C-CR>", desc = "Edit File in Only Window" },
            { "<LocalLeader>T", desc = "Edit File in New Tab" },
            { "<LocalLeader>s", desc = "Edit in Hpriz Split (S-CR)", noremap = false },
            { "<LocalLeader>S", desc = "Load All Files in Splits" },
            { "<LocalLeader>o", desc = "Edit in Only Window (C-CR)", noremap = false },
            { "<LocalLeader>i", desc = "Print Directives (info)" },
            { "<LocalLeader>I", desc = "Print Full Path" },
            { "<M-CR>", desc = "Open File (CR) Refocus Proj", noremap = false },
            { "<LocalLeader>v", desc = "Open Prev Refocus (M-CR)", noremap = false },
            { "<LocalLeader>l", desc = "Load Dir Files" },
            { "<LocalLeader>L", desc = "Load Recursive" },
            { "<LocalLeader>w", desc = ":bwipe Dir Files" },
            { "<LocalLeader>W", desc = ":bwipe Recursive" },
            { "<LocalLeader>g", desc = "Grep Recursive" },
            { "<LocalLeader>G", desc = "Grep Dir Files" },
            { "<2-LeftMouse>", desc = "Open File (CR)", mode = { "n", "i" } },
            { "<S-2-LeftMouse>", desc = "Edit in Hpriz Split (S-CR)" },
            { "<M-2-LeftMouse>", desc = "Open Prev Refocus (M-CR)" },
            { "<S-LeftMouse>", desc = "LeftMouse" },
            { "<C-2-LeftMouse>", desc = "Edit in Only Window (C-CR)", noremap = false },
            { "<C-LeftMouse>", desc = "LeftMouse" },
            { "<3-LeftMouse>", desc = "Nop" },
            { "<RightMouse>", desc = "Toggle Window Width" },
            { "<2-RightMouse>", desc = "Toggle Window Width" },
            { "<3-RightMouse>", desc = "Toggle Window Width" },
            { "<4-RightMouse>", desc = "Toggle Window Width" },
            { vim.g.proj_width_toggle_lhs, desc = "Toggle Window Width" },
            { "<C-k>", desc = "Move Entity Up", mode = { "n", "i" } },
            { "<C-j>", desc = "Move Entity Down", mode = { "n", "i" } },
            {
              "<LocalLeader><Up>",
              desc = "Move Entity Up (<C-k)",
              mode = { "n", "i" },
              noremap = false,
            },
            {
              "<LocalLeader><Down>",
              desc = "Move Entity Down (<C-j)",
              mode = { "n", "i" },
              noremap = false,
            },
            -- Skipping: <LocalLeader>\(f|F\)?[1-9]
            -- - (lb): I've also never used and unsure exactly how works.
            { "<LocalLeader>0", desc = "List External Cmds (g:proj_run[1-9])" },
            { "<LocalLeader>f0", desc = "List Ext Cmds (g:proj_run_fold[1-9])" },
            { "<LocalLeader>F0", desc = "List Ext Cmds (g:proj_run_fold[1-9])" },
            { "<LocalLeader>c", desc = "Create New Project (Simple)" },
            { "<LocalLeader>C", desc = "Create New Project (Wizard)" },
            { "<LocalLeader>r", desc = "Refresh Project Dir" },
            { "<LocalLeader>R", desc = "Refresh Project Recursive" },
            { "<F5>", desc = "Refresh Project Recursive" },
            -- ISOFF: \e disabled b/c behaves like |^| and I don't know what it should do.
            --  { "<LocalLeader>e", desc = "Does nothing" },
            { "<LocalLeader>E", desc = "Open Parent Dir." },
            { "<F1>", desc = "Search Word", mode = { "n", "i", "v" } },
            { "<Home>", desc = "Friendly Home", mode = { "n", "i", "v" } },
            { "<End>", desc = "Friendly End", mode = { "n", "i", "v" } },
            { "<C-^>", desc = "Nop" },
          })
        end,
      })
    end,
  },
}
