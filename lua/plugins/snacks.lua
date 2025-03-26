-- vim:tw=0:ts=2:sw=2:et:ai:ft=lua
-- Author: Landon Bouma <https://tallybark.com/>
-- Project: https://github.com/landonb/nvim-lazyb#🧸

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

-- FIXME: SAVVY: Is this issue abated if you don't have the same
-- buffer open in multiple windows?? Maybe that was it...!? (I hope
-- that was it, so I can avoid it, because it's a very discouraging
-- anomaly! The last thing I want is another seek-and-destroy mission,
-- I just want my editor to be reliable and pleasant!)
-- - I think that was it, becausae even mouse wheel scrolling is no
--   longer jittery, now that I've opened different buffers in the
--   5 other windows I have open...
--
-- FIXME: What is borking scrolling? Something is making it jarring
-- to even use j/k in this file (also <Up>/<Down>, PageUp>/<PageDown>,
-- and the mouse wheel).
-- - W_T_F: There's sometimes a 1- or 2-second delayed re-scroll!
--   - Like, I'm viewing the buffer, then it redraws a page up
--     and scrolls back down to what I'm looking at...
--
-- REFER: <Leader>ua — Toggle animations
--
-- REFER: <Leader>uS — Toggle Smooth Scroll
--
-- REFER: :Noice disable — doesn't help!!! wtf...
--
-- FRACK: I've got all three disabled, and there's still a delayed scroll artifact!
-- - But not always... wtf...
-- - E.g., <Ctrl-End> to bottom of file, then <PageUp> immediately,
--   now wait a second and the window redraws and re-scrolls!
-- - Happens in both Insert and Normal modes.

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

-- REFER: Show all pickers:
--
--   :lua Snacks.picker()
--
-- - CXREF: See list of picker maps (which also lists all pickers):
--   ~/.local/share/nvim_lazyb/lazy/LazyVim/lua/lazyvim/plugins/extras/editor/snacks_picker.lua @ 58
-- - Note Snacks.picker() shows default config (excluding changes below).

-- REFER: Snacks replaces |netrw|, and Explorer runs when you open a
-- directory path, e.g.,
--
--   :edit dir/path/

-- REFER: Use <Leader>fr to search recently active files:
--
--   <Leader>fr — "file/find recent"
--
-- - This features shows an MRU buffer list, though note the active buffer
--   is not placed atop the list until after you focus another buffer.

-- REFER: Use <Leader> fp to search projects:
--
--   <Leader>fp — "file/find projects"
--
-- - REFER:
--   https://github.com/folke/snacks.nvim/blob/main/docs/picker.md#projects
-- — See below: sources.projects.dev |snacks-picker-sources-projects|

-- REFER: Show Lsp Symbols for current file in command line dropdown, with live preview:
--
--    lua Snacks.picker.lsp_symbols({layout = {preset = "vscode", preview = "main"}})
--
-- REFER: Show all workspace symbols in Snacks picker:
--
--    lua Snacks.picker.lsp_workspace_symbols()
--
-- - REFER:
--   https://www.reddit.com/r/neovim/comments/1ij8xjl/symbols_navigator_with_real_preview_fully/
--   - BEGET:
--     https://www.reddit.com/r/neovim/comments/1iphb53/namunvim_a_different_take_on_symbol_navigation/
--     https://github.com/bassamsdata/namu.nvim

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

---@class lazyb.plugins.snacks
local M = {}

local alt_keys = require("util.alt2meta-keys")

-- -----------------------------------------------------------------
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

-- FEATR: Override LazyVim \e and \E bindings to include hidden and
-- ignored files in Snacks Explorer.
-- - UCASE: Especially when showing my user home, I have a number
--   of dot-prefixed directories I regularly work in. Also my top-
--   level ~/.ignore excludes *a lot*, working on the assumption
--   that I'll descend into project directories to search. And if
--   Snacks is excluding hidden and ignored files, I literally see
--   only one item from user home in the Explorer view!
--   - When I first used LazyVim, this was at first frustrating,
--     until I figured out what's up. So I'd rather always include
--     ignored and hidden items. Especially because after a few days
--     I realized I was always pressing 'I' and 'H' to show ignored
--     and hidden items. So might as well include them by default.
--   - Likewise for project directories, I often work with hidden
--     files and directories (e.g., .ignore, .gitignore, .editorconfig,
--     .luarc.json, etc.; there are lots of dot-files committed to
--     projects that you'll often want to edit). Same for ignored
--     files, I often omit files from ripgrep that I'd otherwise
--     still want to open and edit. So let's show 'em all!

-- FEATR: If Explorer already open but project is different,
-- <Leader>fe runs `cd` to change the Explorer project root.
-- - TRACK: I'm not completely confident in the solution.
--   - It checks picker:dir(), though there's also picker:cwd().
--     The latter reports the picker's actual cwd (I think),
--     whereas the former returns the current item's root
--     path (or something, I don't totally grok it) but falls-
--     back on picker:dir().
--     - So the picker:dir() usage below might be incorrect.
--   - Also, I use vim.cmd.cd() to change directories, but there's
--     also :lcd and :tcd and I'm not completely clear on the
--     differences.
--     - I sometimes have issues with Explorer where it's showing
--       a the project for the active file, but as soon as I change
--       focus to Explorer, the list changes to a completely
--       different project. (Which feels like a bug, but, like I
--       noted, I'm not completely certain how Snacks Explorer is
--       suppose to behave, and how cd/tcd/lcd affect that; so
--       maybe Explorer is behaving correctly in that case? And
--       if the latter is the case, that feels like poor UX...
--       unless the user knowingly forced Explorer to show a
--       different project, in which case, yeah, it could well
--       be my lack of understanding, and how cd/tcd/lcd work....)
-- - WRKLG: I thought I could use reveal(), but doesn't work like I expected.
--   ---@param opts? {file?:string, buf?:number}
--   Snacks.explorer.reveal(opts)
--   - None of these work... they don't change the path for an open Explorer,
--     and while they do open Explorer if closed, they don't use the root I'd
--     expect...
--       Snacks.explorer.reveal()
--       Snacks.explorer.reveal({ buf = vim.fn.bufnr() })
--       Snacks.explorer.reveal({ file = vim.fn.bufname() })
--       -- Note vim.fn.system() runs from cwd, so cd first.
--       proj_root = vim.fn.trim(vim.fn.system([[cd "]] ..
--         vim.fn.expand("%:p:h") .. [[" && git rev-parse --show-toplevel]]))
--       Snacks.explorer.reveal({ file = proj_root })
--     - I think reveal() just ensures the indicated file is visible in
--       Explorer, though the current buffer is always visible (e.g.,
--       if you close (fold) the directory for a buffer's file, then
--       give that buffer window focus, the Explorer directory auto-
--       expands to reveal the current buffer file).
--   - REFER:
--       Snacks.picker.actions.cd(_, item)
--       Snacks.picker.actions.tcd(_, item)
--       Snacks.picker.actions.lcd(_, item)
--   - WKRLG: This changes the directory:
--       picker:set_cwd("~/.kit/nvim/landonb/nvim-lazyb")
--     and picker:cwd() reports it, but the Explorer list
--     doesn't update... although picker:dir() is still the
--     old path (the one you see as the Explorer list root).
--     - SAVVY: Note that `cd ~/.kit/nvim/landonb/nvim-lazyb`
--       works... maybe that's all you need...

-- REFER: We explicitly check if the Project or Snacks Explorer windows
-- are visible, which couples this code to those two plugin.
-- - There might be a more generic approach, e.g., inspecting winnr(1)
--   and checking its &filetype.
-- - Re: Project: dubs_project_tray sets &filetype=project_tray.
-- - Re: Snacks:
--   - The Explorer list has &filetype=snacks_picker_list,
--     the input control has &filetype=snacks_picker_input, and the
--     preview float win has &filetype=snacks_picker_preview (if showing).
--   - There's also a non-floating window holding space for the floating
--     windows that's beneath 'em: &filetype=snacks_layout_box. Inspect:
--       I vim.fn.getbufvar(vim.fn.winbufnr(1), '&filetype')
--     See also: :echom winbufnr(1), :ls!, :exec "b " .. winbufnr(1), etc.
--   - (Also note that the floating windows are numbered higher than the
--      last non-floating normal window, just FYI.)
-- - Mostly I'm just saying I didn't devise a non-coupled approach; we
--   use the Snacks api. below to identify the Explorer window, and we
--   use the g: global Project variable to identify the Project window.
--   - I tried alternatively to use WinEnter to check if the Project
--     window was moved, which happens if you open Explorer while
--     Project is showing. But before the event happens, the Explorer
--     window is opened incorrectly (too wide), and I couldn't figure
--     out how to fix the width. So the approach below preemptively
--     closes the Project window before opening Explorer.

-- FEATR: Add support for Project window, to avoid issues.
-- - If you open Explorer while Project is showing, the Explorer
--   window is created wider than its normal 40 character width.
-- - E.g., if Neovim is fullscreen and I have one buffer open,
--   then I open Project, then Explorer, the Explorer window is
--   147 characters wide.
--   - Or, if I have 5 vertical splits open, Project open, and
--     then open Explorer, Explorer is 49 characters wide.
-- - The Explorer window also causes the Project window to
--   shift rightward one, to winnr() == 2, at least until
--   you give focus to Project, and then they swap!
--   - MAYBE: Investigate Project, and adjust its affinity for winnr=1.
-- - Note that at some point during testing, when I opened
--   Explorer, it would *hide* the Project buffer instead —
--   but now I cannot reproduce that behavior!
--   - This behavior was also a little quirky: I didn't see any
--     event fired! At least not BufHidden nor BufWinLeave.
--   - When I'd :ToggleProject off manually, I'd see BufLeave
--     and then BufWinLeave.
--   - But when I ran Explorer, I saw BufLeave, *but nothing else*.
--     (And note that you'll see BufLeave if you simply move the
--     cursor out of the Project window, so it's not helpful.)
--     - Though, like I said, I could not reproduce this behavior
--       after a while (maybe after I started a new Session?).

-- SAVVY: LuaLS reports lots of missing fields to Snacks.explorer:
--   "Missing required fields in type `snacks.picker.explorer.Config`:
--     `finder`, `sort`, ... [missing-fields]"
-- - REFER: Use `@diagnostic disable-line` to disable diagnostics.
--   - Put in comment at end of the line in question (and not
--     above the line, like you'd do with stylua-ignore).
--   - SPIKE: Where is `@diagnostic disable-line` documented?
--     - On GH, I only see in Lua files, so I'm guessing it's LuaLS...
--       https://github.com/search?q=%40diagnostic+disable-line&type=code
-- - SPIKE: How do you fix these diagnostic errors?
--   - CXREF: You'll see the "Snacks" global is registered with
--     folke/lazydev.nvim, so I'd except it to work. See:
--        library = { ... { path = "snacks.nvim", words = { "Snacks" } }, ... }
--     ~/.local/share/nvim_lazyb/lazy/LazyVim/lua/lazyvim/plugins/coding.lua @ 75

-- SPIKE: Does it matter how you declare module functions?
--   function M.func()
--   M.func = function()
-- M.project_aware_explorer_toggle = function(handle_picker_showing)
function M.project_aware_explorer_toggle(cwd, handle_picker_showing)
  local runit = false
  local snack_types = {
    snacks_picker_input = true,
    snacks_picker_list = true,
    snacks_picker_preview = true,
  }
  local picker_showing = false
  if snack_types[vim.bo.filetype] then
    picker_showing = true
    -- Run Snacks.explorer to toggle it off.
    -- MAYBE: Move cursor to previous window.
    -- - It currently moves to window that "opened" Explorer.
    runit = true
  else
    local pickers = Snacks.picker.get({ source = "explorer" })
    local picker = #pickers > 0 and pickers[1] or nil

    if not picker then
      runit = true
    else
      picker_showing = true

      if handle_picker_showing then
        runit = handle_picker_showing(picker)
      end
    end
  end

  if runit then
    local proj_winnr = nil
    if not picker_showing then
      proj_winnr = vim.g.proj_running and vim.fn.bufwinnr(vim.g.proj_running) ~= -1

      if proj_winnr and proj_winnr ~= -1 then
        vim.cmd([[execute "normal \<Plug>DubsProjectTray_ToggleProject_Wrapper"]])
      end
    end

    Snacks.explorer({ --- @diagnostic disable-line: missing-fields
      cwd = cwd,
      hidden = true,
      ignored = true,
      exclude = { ".DS_Store" },
    })

    -- MAYBE: Maybe don't toggle back on...
    if proj_winnr and proj_winnr ~= -1 then
      -- If called immediately or on vim.schedule(), messes up
      -- Explorer width, and reappears to the right of Explorer.
      -- - MAGIC: 100 msec. was first timeout I tried. It works.
      -- - MAYBE: Is there a Snacks/Explorer event we could hook
      --   instead, i.e., that runs after Explorer opens?
      --   Because using defer_fn is very kludgy.
      local timeout_ms = 100
      vim.defer_fn(function()
        vim.cmd([[execute "normal \<Plug>DubsProjectTray_ToggleProject_Wrapper"]])
      end, timeout_ms)
    end
  end
end

function M.handle_picker_showing_root(picker)
  local runit = false

  -- MAYBE: Improve this. I.e., if not Git, print error.
  -- - Though author has user home under Git, so unless
  --   I'm working outside my user directory, I'll never
  --   see this fail. (And is anyone else using this project? =)
  -- MAYBE: Relocate to util.script.
  local proj_root = vim.fn.trim(
    vim.fn.system([[cd "]] .. vim.fn.expand("%:p:h") .. [[" && git rev-parse --show-toplevel]])
  )

  local lazy_root = LazyVim.root()
  if proj_root ~= lazy_root then
    print("proj_root:", proj_root, "/ lazy_root:", lazy_root)
  end

  -- SPIKE: What's the difference between cwd() and dir()?
  --
  -- - E.g., some paths I've seen reporeted:
  --
  --   proj_root:    ~/.kit/nvim/landonb/nvim-lazyb
  --   picker:cwd(): ~/.kit/nvim/landonb/nvim-lazyb
  --   picker:dir(): ~/.kit/nvim/landonb/nvim-lazyb/lua/util/buffer-delights
  --
  --   proj_root:    ~/.kit/nvim/landonb/nvim-lazyb
  --   picker:cwd(): ~/.kit/nvim/landonb/nvim-lazyb
  --   picker:dir(): ~/.kit/nvim/landonb/nvim-lazyb/lua/plugins
  --
  -- - It appears that picker:cwd() matches the Git project root...
  if picker:cwd() ~= picker:dir() then
    print(
      "SPIKE: Why is cwd() ~= dir()? / proj_root: "
        .. proj_root
        .. " / picker:cwd(): "
        .. picker:cwd()
        .. " / picker:dir(): "
        .. picker:dir()
        .. " / runit: "
        .. vim.inspect(not (proj_root ~= picker:cwd()))
    )
  end

  if proj_root ~= picker:cwd() then
    -- Leave Explorer open, but change its root.
    -- FIXME: Associate <CR> with current window.
    -- - <CR> still opens to window that "opened" Explorer.
    vim.cmd.cd(proj_root)
  else
    runit = true
  end

  return runit
end

-- -----------------------------------------------------------------
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

return {

  -- -----------------------------------------------------------------
  -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

  -- BUGGN/2025-03-05: If you :lcd (and maybe if you :cd ?) so that
  -- different windows have different working directories, the Explorer
  -- root changes as you move the cursor between windows. Which I find
  -- annoying — I'd rather <Leader>e twice to close and re-open Explorer
  -- if I want to change the Explorer view.
  -- - BUGGN: At some point, Explorer itself got a window-local cwd that
  --   I couldn't get rid of, such that if I <Leader>e opened Explorer
  --   from some buffer and was looking at its project listing, when I
  --   then click or move the cursor to the Snacks window, the Explorer
  --   listing changes to the Snacks window directory!
  --   - Which is buggy — it makes the Explorer useless, because whenever
  --     you try to interact with it, it always changes back to its
  --     window-local cwd. And then you cannot open files from any other
  --     project, at least not without :cd or :lcd first.
  -- - I couldn't figure out how to recover other than quit LazyVim and
  --   to not reload my session after restarting.
  --   - MAYBE: A :cd command should disassociate the local window dir.,
  --     but you might need to run from every window? Or maybe just
  --     close all windows, and run :cd on the last window?
  --
  -- SAVVY: To see this behavior, `:set autochdir` so that Vim changes
  -- directories whenever you change buffers.
  -- - You can also load the vim-lcd-project-root plugin (see after this
  --   long comment), which cd's to the project root of the active buffer.
  --   - This behavior is basically what happens if you switch windows
  --     and run <Leader>e twice to close and reopen the Explorer using
  --     the current buffer's project root.
  -- - FEATR: I modified <Leader>e to be a "throggle" (a tri-state toggle) —
  --   when Explorer is already open, if its project root differs from the
  --   active buffer (whatever now has focus when you run <Leader>e),
  --   <Leader>e will |cd| to current file's project root. This precludes
  --   you from needing to <Leader>e twice to explore the current project.
  --
  -- BWARE: vim-lcd-project-root changes Snacks Explorer behavior,
  -- as mentioned above.
  -- - SPIKE: What was I using this plugin for in nvim-depoxy? And do I
  --   still need it?
  --   - Because, if I do, it doesn't currently play nice with Snacks
  --     Explorer.
  --   - A better approach might be to find the root directory for the
  --     active buffer whenever you need to do whatever you need to do,
  --     rather than always :lcd'ing on BufEnter. I.e., leave the global
  --     :cd set, and don't change any window-local directories.
  --
  -- TRACK: I saw this behavior previously, but it currently doesn't happen
  -- unless I run <Leader>e from help window... and even then, the 'help'
  -- window cwd still matches the project root and isn't changed to the
  -- help docs like I noted... *DUNNO*: While it's frustrating that I
  -- observe different Explorer behaviors and cannot faithfully replicate
  -- previous issues, at least the unreproducability is consistent...
  -- - BUGGN: Opening :help sets a window-local directory, and if Explorer
  --   is open, focusing the help window changes the Explorer listing
  --   (e.g., on macOS to /opt/homebrew/ as its root).
  --   - This behavior seems unexpected, and I'd hasten to suggest that
  --     it's not the behavior @folke intends (albeit I haven't seen any
  --     documentation on how things are suppose to behave).
  --   - *DUNNO*: As noted by the preceding *TRACK* comment, this issue
  --     has happened previously, but now when I :pwd from a 'help' window,
  --     its cwd is still the project directory (that correlates with the
  --     Session I opened after I started nvim). So seems like when this
  --     happened, Explorer was in an abnormal state (that I'm currently
  --     unable to reproduce, guh).
  --
  -- BUGGN: It's happening again!
  -- - When I click the Explorer window, it changes directories!
  -- - However, I could at least recover by closing and reopening Explorer.
  --   - It's still buggy behavior, though.
  --   - Also, the directory listing gets out of sync, e.g.,
  --     <Leader>e to open Explorer for a particular file.
  --     Then I move cursor to a window with a buffer from
  --     another project, and Explorer doesn't change. But
  --     then I move cursor back to the original window,
  --     and Explorer changes to the project directory
  --     from the previous file! (So now Explorer doesn't
  --     match the current buffer; and if I move cursor
  --     back to the second window, Explorer changes again
  --     and shows the project for the first window buffer!)
  --   - I recovered with <leader>bd and reopening the file,
  --     and now Explorer is behaving normally... ugh, whatever,
  --     I don't have time to hunt this down. (And the Explorer
  --     feature was only added last January! So maybe someone
  --     else will notice/fix the same thing; not that I found a
  --     matching Issue or Discussion about it, unfortunately.)
  {
    dir = "~/.kit/nvim/landonb/vim-lcd-project-root",
    -- See long comments above — while this plugin is not activated
    -- and may be unnecessary, it's primed and ready to help you
    -- explore and diagnose issues that may arise with Explorer usage.
    lazy = true,
  },

  -- -----------------------------------------------------------------
  -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

  -- CXREF: ~/.local/share/nvim_lazyb/lazy/LazyVim/lua/lazyvim/plugins/ui.lua @ 271
  -- REFER: Get inspired by other user's dashboards:
  -- - *Share your dashboards!*
  --   https://github.com/folke/snacks.nvim/discussions/111
  -- - Folke includes GH PRs on their dashboard:
  --   https://github.com/folke/snacks.nvim/discussions/111#discussioncomment-11382576
  --   - FTREQ/LOPRI: Wire GH PRs to dashboard.
  --     - SPIKE: But are they interactive?
  --       - Do they just open in a browser, or are there additional Neovim commands
  --         you can use to interact with GH and/or PRs?
  --
  -- FTREQ/INERT: Add a "picture" to the dashboard using chafa.
  -- - E.g.,
  --   https://github.com/folke/snacks.nvim/discussions/111#discussioncomment-11526630
  -- - REFER: See also dashboard ASCII utility:
  --   https://github.com/MaximilianLloyd/ascii.nvim
  {
    "snacks.nvim",

    --      🫧 🫧 🫧 🫧 🫧 🫧 🫧 🫧 🫧 🫧 🫧 🫧 🫧 🫧 🫧 🫧 🫧 🫧
    opts = {
      dashboard = {
        preset = {
          header = [[
          ██╗      █████╗ ███████╗██╗   ██╗██╗   ██╗██╗███╗   ███╗          B
  󰗣       ██║     ██╔══██╗╚══███╔╝╚██╗ ██╔╝██║   ██║██║████╗ ████║      B    
          ██║     ███████║  ███╔╝  ╚████╔╝ ██║   ██║██║██╔████╔██║   b       
      󰗣   ██║     ██╔══██║ ███╔╝    ╚██╔╝  ╚██╗ ██╔╝██║██║╚██╔╝██║ b         
          ███████╗██║  ██║███████╗   ██║    ╚████╔╝ ██║██║ ╚═╝ ██║           
 󰗣        ╚══════╝╚═╝  ╚═╝╚══════╝   ╚═╝     ╚═══╝  ╚═╝╚═╝     ╚═╝           
   ]],
        },
      },
    },
    --      🫧 🫧 🫧 🫧 🫧 🫧 🫧 🫧 🫧 🫧 🫧 🫧 🫧 🫧 🫧 🫧 🫧 🫧
  },

  -- -----------------------------------------------------------------
  -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

  -- CXREF:
  -- ~/.local/share/nvim_lazyb/lazy/LazyVim/lua/lazyvim/plugins/init.lua
  -- ~/.local/share/nvim_lazyb/lazy/LazyVim/lua/lazyvim/plugins/extras/editor/snacks_explorer.lua
  -- ~/.local/share/nvim_lazyb/lazy/snacks.nvim/lua/snacks/picker/config/defaults.lua
  --
  -- REFER: `_G.Snacks = M` from:
  --   ~/.local/share/nvim_lazyb/lazy/snacks.nvim/lua/snacks/init.lua
  -- - So we can access `Snacks` anywhere (and don't, e.g., need to require() it).
  -- - Also provides luals enablement.
  --
  -- REFER:
  -- https://github.com/folke/snacks.nvim/tree/main/docs
  --
  -- - REFER: Snacks.picker command maps:
  --   - E.g., <Alt-w> cycles cursor between picker windows and input.
  --   https://github.com/folke/snacks.nvim/blob/main/docs/picker.md
  {
    "folke/snacks.nvim",

    -- This build function maintains a personal fork that's kept ahead
    -- of upstream snacks.nvim.
    -- - ONGNG: I plan to maintain this fork if/until I PR the changes
    --   I've made (though I probably cannot PR every change, at least
    --   not without adding configurability to some of the changes, so
    --   expect this fork to exist indefinitely).
    -- - A lazy approach might be to pin the repo, and then lazy won't
    --   update it:
    --     pin = true,
    --   But that I'm liable to forget to ever update, and snacks very
    --   much still under active development [/2025-03-19].
    -- - LazyVim runs the 'build' hook after it updates plugins (which
    --   detaches HEAD, for some reason).
    --   - We'll checkout the fork-branch and rebase against upstream.
    -- - SAVVY: This plugin always appears to have updates in :Lazy.
    -- - SAVVY: Note that lazy does not change directories, e.g.,
    --   vim.fn.getcwd() is wherever user was when they ran Lazy.
    build = require("util").lazy_build_fork("snacks.nvim"),

    -- -----------------------------------------------------------------
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

    opts = {
      -- SPIKE: Does follow_file mean <CR> opens to MRU window?
      -- - Currently file opens to window you started Explorer
      --   from, unless you <Shift-CR> to pick a different window.
      --   - REFER: I also wired <Ctrl-CR> (mostly so that other
      --     <C-CR> map doesn't run, which adds newline w/o comment
      --     leader, which evokes unmodifiable scorn in Explorer).
      --
      -- - @field follow_file? boolean follow the file from the current buffer
      -- follow_file = true,
      -- explorer = { follow_file = true },

      -- ***

      -- SPIKE: Experiment with auto-closing Explorer after opening a file.
      -- - Though I bet you wouldn't like it! =)
      -- - SPIKE: What's diff. between auto_close and jump?
      --
      -- auto_close = false,
      -- jump = { close = false },

      -- ***

      -- USAGE: Don't show indent guides by default (I find them
      -- distracting without adding much value; but they're cute!
      -- and nice to know they're there if you want them.)
      -- - REFER: Toggle indents lines via <Leader>ug
      -- - ASIDE: LazyVim (gitsigns) also shows `|` marks for modified
      --   lines, which appear to the column left of the indent guides
      --   (just to the right of the line numbers). (These I like.)
      -- - REFER: Toggle gitsigns signcolumn via <Leader>uG
      -- CRUMB: opts.indent.enabled
      indent = { enabled = false },

      -- BUGGN: <Shift-Down> in Select mode is busted -- when window starts to
      -- scroll, selected text is replaced with what looks like an 'H' command,
      -- e.g., "51H", "5H", etc.
      -- - TRYME: Enable "Smooth scrolling for Neovim", then select text via
      --   <Shift-Down> or <Shift-Up> to test (&selectmode should include "key").
      --    :echom &selectmode
      --    :lua Snacks.scroll.enable()
      --    :lua Snacks.scroll.disable()
      -- - CXREF: You'll find the relevant code in scroll.check(). See also
      --   the WinScrolled event in the same file:
      --     ~/.local/share/nvim_lazyb/lazy/snacks.nvim/lua/snacks/scroll.lua
      -- CRUMB: opts.scroll.enabled
      -- FIXME: Investigate further and PR. (E.g., test in terminal, on Debian, etc.)
      scroll = { enabled = false },

      -- CRUMB: opts.statuscolumn.folds.statuscolumn
      -- FIXME: Open PR: Send cursor to first column when clicking the sign column.
      statuscolumn = { folds = { click_to_col = 0 } },

      picker = {
        -- CXREF: See LazyVim opts.picker.win.input.key picker bindings:
        -- ~/.local/share/nvim_lazyb/lazy/snacks.nvim/lua/snacks/picker/config/defaults.lua @ 196
        win = {
          input = {
            keys = {
              -- I find it useful to run ex commands while the picker is active,
              -- so I don't need an easy <Escape>.
              -- - Though if you want to close a picker with a single <Esc>, this:
              --   ["<Esc>"] = { "close", mode = { "n", "i" } },

              -- Default <C-v> opens file in new vsplit:
              --   ["<c-v>"] = { "edit_vsplit", mode = { "i", "n" } },
              -- - But we'll use a different map, because paste.
              -- SAVVY: Disable a default key with `false` — but not `{}` or `nil`.
              -- - BNGNG: <Ctrl-v> Maintain paste fcn'ality in Snacks pickers.
              ["<c-v>"] = false, -- So that paste works (ALTLY: <Ctrl-r>+)

              -- Relocate v-split opener <Ctrl-v> → <Alt-v>
              -- - BNGNG: <Alt-v> Edit file in new Vertical split.
              ["<a-v>"] = { "edit_vsplit", mode = { "i", "n" } },

              -- Make <C-CR> same as <S-CR> — dubs_edit_juice maps <C-CR> to new
              -- line below without comment leader, which causes unmodifiable
              -- warning. Which is somewhat cruel when you meant <S-CR>.
              -- - BNGNG: <Ctrl-CR> Pick target window to edit file.
              ["<C-CR>"] = { { "pick_win", "jump" }, mode = { "n", "i" } },
            },
          },

          -- CXREF: See LazyVim opts.picker.win.list.key Explorer bindings:
          -- ~/.local/share/nvim_lazyb/lazy/snacks.nvim/lua/snacks/picker/config/defaults.lua @ 196
          list = {
            keys = {
              -- Interestingly, while <Esc> is not wired for Snacks Picker by
              -- default, it is wired for Snacks Explorer, so let's disable it.
              -- - BECUZ: I sometimes mash <Esc> as a reflex before typing a
              --   command, then I feel punished when that closes a window instead.
              -- - Default:
              --   ["<Esc>"] = "cancel",
              -- - SAVVY: Note that <Ctrl-c> doesn't close Explorer.
              --   - In a normal Snacks picker floating window, <Ctrl-c> cancels it.
              --   - But in Explorer, <Ctrl-c> calls `tcd` to change the top-level.
              --     - CALSO: The "." map works similarly, but doesn't set `tcd`
              --       (Explorer continues to use the pwd it inherited from the
              --       window you opened Explorer from... I think):
              --         ["<c-c>"] = "tcd",
              --         ["."] = "explorer_focus"
              --   - SPIKE: How exactly does `tcd` work/influence Explorer??
              ["<Esc>"] = false,

              -- Mimic <S-CR> (and avoid dubs_edit_juice <CR> w/out comment leader).
              -- - BNGNG: <Ctrl-CR> Pick target window to edit file.
              ["<C-CR>"] = { { "pick_win", "jump" } },

              -- Wire "-" for parity with |netrw| (not that I used netrw all that
              -- much, but for some reason I still have this muscle memory...).
              -- - CXREF: Default: ["<BS>"] = "explorer_up",
              --   ~/.local/share/nvim_lazyb/lazy/snacks.nvim/lua/snacks/picker/config/sources.lua @ 77
              -- - BNGNG: "-" Snacks Explorer change directories up.
              ["-"] = "explorer_up",
            },
          },
        },

        -- USAGE: Uncomment to enable debug trace for git diff, e.g.,
        --
        --   lua Snacks.picker.git_diff()
        --
        -- -- CRUMB: opts.picker.debug
        -- debug = {
        --   proc = true,
        -- },
        --
        -- -- Other debug options (DUNNO: Though when I enabled, I didn't see anything...)
        -- debug = {
        --   explorer = true,
        --   files = true,
        -- },

        sources = {
          -- Disable "tree" to shows partial path prefixes, e.g.:
          --   project
          --     subdir
          --       subdir/subdir
          --         subdir/subdir/file
          --
          -- explorer = {
          --   tree = false,
          -- },

          -- Customize "project" paths.
          -- - REFER: LazyVim assigns projects picker to <leader>fp.
          -- - Note that choosing a project calls load_session.
          --     ...
          --     vim.fn.chdir(dir)
          --     local session = Snacks.dashboard.sections.session()
          --   which is to say that each Session is associated with
          --   a particular directory path... though beyond that I'm
          --   not sure exactly how Sessions work, especially if you
          --   have multiple windows with buffers open from different
          --   projects.
          -- - Note that using a top-level directory doesn't really
          --   work well here, because <CR> opens that path as a
          --   Session, rather than showing its descendants...
          --   - DUNNO: I'm not sure how the docs example works:
          --       dev = { "~/dev", "~/projects" },
          --     Not that it says, but I assume under ~/projects
          --     you'd have multiple projects. But if they're not
          --     listed in the picker, and if choosing "~/projects"
          --     loads it rather than showing its subdirectories,
          --     how is this supposed to work?
          -- - BUGGN/TRACK: Hrmm, is this how <Shift-CR> works?
          --   It prompts you for the target window like Explorer
          --   does — which seems weird, because it loads a Session
          --   which changes all windows and buffers — but then it
          --   opens the Explorer picker and shows each project subdir.
          --   - And then you can select a subdir and <Ctrl-C>
          --     which calls :tcd to set the tabpage cwd, and
          --     then the Expolorer view shows only files from
          --     the subdir you picked....
          --   - Ugh, sometimes when you <Ctrl-C>, all the project
          --     files are shown   disabled in Explorer, but if
          --     you restart Neovim, then they appear normally...
          --     this feels buggy to me, but I'm also not certain
          --     exactly how some of these features are suppose
          --     to work...
          --     - I see similar behavior if you <BS> in Explorer
          --       to go up a directory, then descend into another
          --       project and <Ctrl-C>. Even if I close and reopen
          --       Explorer, files are shown   disabled, but fixed
          --       after a restart...
          --       - If feels like Explorer is not updating ignore/
          --         exclude rules or something (though disabling
          --         'H' and 'I' doesn't hide those files... so
          --         why are they shown   disabled?).
          --     - Of course now I'm testing <BS> and <Ctrl-C> on
          --       the same and other projects, and the   disabled
          --       issue isn't happening now! Buggy indeed... well,
          --       buggy in the formatting, at least Explorer is
          --       still usable, it just *looks* wrong sometimes!
          projects = {
            -- Default: dev = { "~/dev", "~/projects" },
            dev = {
              "~/.depoxy",
              "~/.kit",
              "~/.kit/dob",
              "~/.kit/docs",
              "~/.kit/git",
              "~/.kit/mOS",
              "~/.kit/sh",
            },
          },

          -- DUNNO: This doesn't seem to do anything,
          -- or it's in the wrong spot. I also tried
          -- this at the top-level (see above)....
          -- - BUGGN/TRACK: Specifically, I'm curious why one project
          --   shows all the project files in a disabled highlight
          --   with the closed-eye icon,  , but nothing is ignored/
          --   excluded, and disabling 'H' hidden and 'I' ignored
          --   options still shows the files and   icons...
          --   - FRACK: Or not? Now that project appears normal...
          --     and I haven't changed anything, just restarted
          --     a few times... ugh.
          --
          --   debug = {
          --     explorer = true,
          --     files = true,
          --   },
        },
      },

      -- BUGGN: Default notification ft=markdown, which converts user
      -- home path tilde to strike-through, e.g., `map <leader>gsa`,
      -- which should print:
      --   s  <Space>    *@<Lua 1441: ~/.local/share/.../triggers.lua:43>
      --                   which-key-trigger
      --   n  <Space>gs  * <Lua 266: ~/.local/share/.../snacks_picker.lua:77>
      --                   Git Status
      -- but instead prints:
      --   s  <Space>    *@<Lua 1441: /.local/share/.../triggers.lua:43>
      --                   which-key-trigger
      --                              ----------------------------------
      --   n  <Space>gs  * <Lua 266: /.local/share/.../snacks_picker.lua:77>
      --   --------------------------
      --                   Git Status
      -- Where characters above the dashes are printed in ~~strike-through~~.
      -- - SPIKE: Is there a better ft? Or a different approach?
      --
      -- - REFER: A few of the defaults:
      --     styles = {
      --       notification = {
      --         ft = "markdown",
      --         bo = { filetype = "snacks_notif" },
      --       },
      --     },
      --   ~/.local/share/nvim_lazyb/lazy/snacks.nvim/docs/styles.md @ 180
      --
      -- Either "text" or "rst" avoids the strike-through.
      -- - "text" uses white text to show map mode, lhs and rhs components,
      --   and gray text for paths.
      -- - "rst" output looks similar, but uses colorful, bold text for
      --   lhs components, but also bolds the "@" in the example above.
      --  styles = { notification = { ft = "rst" } },
      styles = { notification = { ft = "text" } },
    },

    -- -----------------------------------------------------------------
    -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

    keys = {
      {
        -- Call Snacks.explorer() with cwd set to current file's project root.
        -- REFER: |snacks-picker-sources-explorer|
        -- ~/.local/share/nvim_lazyb/lazy/snacks.nvim/lua/snacks/picker/config/sources.lua
        "<leader>fe",
        function()
          -- stylua: ignore
          M.project_aware_explorer_toggle(
            LazyVim.root(),
            M.handle_picker_showing_root
          )
        end,
        desc = "Explorer Snacks (root dir)",
      },
      {
        -- Call Snacks.explorer() without "cwd".
        -- - USAGE: Useful to always open Explorer (from any window) using
        --   the same base directory (per :pwd, based on cd, lcd, or tcd,
        --   I think).
        -- - Basically this:
        --     Snacks.explorer({ hidden = true, ignored = true })
        --   But Project-window aware.
        "<leader>fE",
        function()
          M.project_aware_explorer_toggle()
        end,
        desc = "Explorer Snacks (cwd)",
      },
      -- SAVVY: LazyVim also defines two aliases that'll now use our custom maps:
      --   { "<leader>e", "<leader>fe", desc = "Explorer Snacks (root dir)", remap = true },
      --   { "<leader>E", "<leader>fE", desc = "Explorer Snacks (cwd)", remap = true },

      -- FTREQ/INERT: Show Alt seq in which-key when literal lhs used.
      -- - E.g., set lhs to "∂", but show the Alt binding in which-key, e.g., "<M-d>".
      -- - I currently at least (manually) add the Alt binding to the "desc",
      --   but the left side of the which-key column shows the (not very
      --   helpful) <Option> character.
      {
        -- BNDNG: <Leader>f<M-d> aka <Leader>f∂
        "<leader>f" .. alt_keys.lookup("d"),
        -- function()
        --   Snacks.explorer({ --- @diagnostic disable-line: missing-fields
        --     cwd = "~/.kit/nvim",
        --     hidden = true,
        --     ignored = true,
        --     exclude = { ".DS_Store" },
        --   })
        -- end,
        function()
          M.project_aware_explorer_toggle("~/.kit/nvim")
        end,
        desc = alt_keys.AltKeyDesc("Explorer Snacks (~/.kit/nvim)", "M-d"),
      },

      -- CXREF: See Snack and FZF file pickers elsewhere:
      -- ~/.kit/nvim/landonb/nvim-lazyb/lua/plugins/snacks-fzf-pickers.lua
      -- - Including <LocalLeader>F, <LocalLeader>dF, etc.

      -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

      -- REFER: LazyVim <Leader>q bindings: <L>qs | <L>qS | <L>ql | <L>qd
      --   cd ~/.local/share/nvim_lazyb/lazy
      --   rg "leader>q"
      {
        -- SAVVY: Dashboard runs as a floating window and works best if you
        -- close all windows first (:only).
        -- MAYBE: Move LazyVim don't-save-Session from <Leader>fd → <Leader>fD
        -- BNDNG: <Leader>q aka <Leader>fD
        "<leader>qD",
        function()
          Snacks.dashboard()
        end,
        desc = "Snacks Dashboard",
      },
    },
  },
}
