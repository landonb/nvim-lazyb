-- vim:tw=0:ts=2:sw=2:et:ai:ft=lua
-- Author: Landon Bouma <https://tallybark.com/>
-- Project: https://github.com/landonb/nvim-lazyb#🧸

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

local wk = require("which-key")

local alt_keys = require("util.alt2meta-keys")

local ctrl_keys = require("util.ctrl2pua-keys")

return {
  {
    dir = "~/.kit/nvim/landonb/vim-buffer-ring",
    -- lazy = not lazy_profile["vim-buffer-ring"],
    -- SAVVY: If no 'lazy', 'event', etc., lazy.nvim uses 'keys' as trigger.
    -- DUNNO: Why is the `lazy =` necessary? Isn't is implied false if not specified?
    -- - Or is there something different about vim-buffer-ring?
    event = "VeryLazy",

    config = function()
      -- Vim's builtin <Ctrl-K> maps to a :digraph feature.
      -- - Vim's builtin <Ctrl-J> is an <NL>, "Begin new line"
      --   (including adding comment leader).
      -- LazyVim uses <Ctrl-H|J|K|L> to move cursor between windows
      -- in Normal mode.
      -- - LayzVim Insert mode <Ctrl-K> shows signature help.
      -- - Dubs uses <Ctrl-Alt-Arrow>, from all modes.
      -- - MAYBE: Though I'm not opposed to LazyVim maps.
      --   - Maybe try <Ctrl-,> and <Ctrl-.> (which are the '<' and '>' keys);
      --     or maybe you can't bind those, they emit ',' and '.' characters,
      --     respectively, and I know that not all <Ctrl> combos are possible.
      --   - Maybe also wire LazyVim [b and ]b to these...
      -- BWARE: `Lazy reload vim-buffer-ring` doesn't reload `keys`.
      wk.add({
        icon = "🪐",
        -- CXREF: LazyVim <Ctrl-H|J|K|L> window jumpers (Normal mode).
        --   ~/.local/share/nvim_lazyb/lazy/LazyVim/lua/lazyvim/config/keymaps.lua
        -- CXREF: LazyVim <Ctrl-K> Show Signature (Insert mode).
        --   ~/.local/share/nvim_lazyb/lazy/LazyVim/lua/lazyvim/plugins/lsp/keymaps.lua
        --
        -- { "<C-j>", "<cmd>BufferRingReverse<CR>", desc = "Buffer Ring Reverse", mode = { "n", "i" } },
        -- -- BLOKD: LazyVim defines Insert mode <C-k> Show Signature LSP command...
        -- { "<C-k>", "<cmd>BufferRingForward<CR>", desc = "Buffer Ring Forward", mode = { "n", "i" } },
        -- -- FIXME: But what about LazyVim's <C-h>/<C-l>?
        --
        -- Yeah, no, sorry, nice try, these don't work:
        --   { "<C-,>", "<cmd>BufferRingReverse<CR>", desc = "Buffer Ring Reverse", mode = { "n", "i" } },
        --   { "<C-.>", "<cmd>BufferRingForward<CR>", desc = "Buffer Ring Forward", mode = { "n", "i" } },
        --
        -- ALTLY: Leave the LazyVim maps, and use <Alt-;>/<Alt-'>
        -- { "<M-;>", "<cmd>:BufferRingReverse<CR>", desc = "Buffer Ring Reverse", mode = { "n", "i" } },
        -- { "<M-'>", "<cmd>:BufferRingForward<CR>", desc = "Buffer Ring Forward", mode = { "n", "i" } },
        -- {
        --   alt_keys.lookup(";"),
        --   "<cmd>:BufferRingReverse<CR>",
        --   desc = alt_keys.AltKeyDesc("Buffer Ring Reverse", "<M-;>"),
        --   mode = { "n", "i" },
        -- },
        -- {
        --   alt_keys.lookup("'"),
        --   "<cmd>:BufferRingForward<CR>",
        --   desc = alt_keys.AltKeyDesc("Buffer Ring Forward", "<M-'>"),
        --   mode = { "n", "i" },
        -- },
        --
        -- CXREF: ~/.depoxy/ambers/home/.config/alacritty/alacritty.toml
        --   { key = ";", mods = "Control", chars = "\uE01A" },
        --   { key = "'", mods = "Control", chars = "\uE01B" },
        -- BUGGN: These two maps cause a top-level which-key entry under "î" (<Opt-i>i)
        -- which says "+1 keymap", even though these PUA characters...
        -- - I see the same "î" character even if I use diff. chars, e.g., "" and "".
        -- - KLUGE: See "î" which-key def'n atop keymaps config:
        --   ~/.kit/nvim/landonb/nvim-lazyb/lua/config/keymaps.lua
        -- BNDNG: <Ctrl-;> aka <>
        {
          ctrl_keys.lookup(";"),
          "<cmd>:BufferRingReverse<CR>",
          desc = "Buffer Ring Reverse",
          mode = { "n", "i" },
        },
        -- BNDNG: <Ctrl-'> aka <>
        {
          ctrl_keys.lookup("'"),
          "<cmd>:BufferRingForward<CR>",
          desc = "Buffer Ring Forward",
          mode = { "n", "i" },
        },
        --
        -- These maps add the which-key entries (but
        -- the real bindings are the ones above).
        --
        -- BNDNG: <Ctrl-;> aka <>
        {
          "<C-;>",
          "<cmd>:BufferRingReverse<CR>",
          desc = "Buffer Ring Reverse",
          mode = { "n", "i" },
        },
        -- BNDNG: <Ctrl-'> aka <>
        {
          "<C-'>",
          "<cmd>:BufferRingForward<CR>",
          desc = "Buffer Ring Forward",
          mode = { "n", "i" },
        },

        -- CXREF: Wire a map to show buffer history list.
        -- - FIXME: Add other maps here, too...
        -- ~/.kit/nvim/landonb/vim-buffer-ring/autoload/embrace/bufsurf.vim
        --
        -- DUNNO/2025-02-05: Neovim inhibits output when you use vim.keymap.set
        -- and hides messages — which user can view using :messages. But that's
        -- not helpful if point of command is show the user some output!
        -- - I fount at least 2 work-arounds, though.
        -- - ALTLY: Use a floating window or some other mechanism.
        --
        -- - BWARE: Sends output directly to messages, so user won't see it
        --   unless they run :messages
        --
        --     lua vim.keymap.set("n", "<Leader>db", function()
        --       vim.api.nvim_call_function("g:embrace#bufsurf#BufferRingListAll", {})
        --     end, { silent = false })
        --
        -- - BWARE: Quietly prints to messages; you won't see anything unless `:messages`:
        --
        --     lua vim.keymap.set("n", "<Leader>db", function() print("foo\nbar\nbaz\n") end, { silent = false })
        --
        -- - WORKS: Calling `nvim_set_keymap` directory works (albeit the Lua
        --   string you pass it is less Lua-like than using a function () end.
        --
        --     lua vim.api.nvim_set_keymap("n", "<leader>db",
        --       '<cmd>lua vim.api.nvim_call_function("g:embrace#bufsurf#BufferRingListAll", {})<CR>', {})
        --
        -- - WORKS: You can also thunk back to classic Vim, e.g., this also works:
        --
        --    lua vim.cmd('nnoremap <silent> <leader>db :call g:embrace#bufsurf#BufferRingListAll()<CR>')
        --
        -- - WRKLG/2025-02-05: Ugh, for posterity:
        --
        --     keys__WRONG = {
        --       {
        --         "<leader>db", mode = { "n", "i" }, function()
        --           -- DUNNO/2025-02-05: This all prints silently to :messages.
        --           local foo = vim.api.nvim_call_function("g:embrace#bufsurf#BufferRingListAll", {})
        --           print('foo/1: ' .. vim.inspect(foo))
        --
        --           vim.api.nvim_echo({{'foo!'}}, true, {verbose = false})
        --
        --           -- Vim:E121: Undefined variable: call
        --           --   local foo = vim.api.nvim_eval('call g:embrace#bufsurf#BufferRingListAll()')
        --           local foo = vim.api.nvim_eval('g:embrace#bufsurf#BufferRingListAll()')
        --           print('foo/2: ' .. vim.inspect(foo))
        --
        --           local output = vim.api.nvim_exec2('call g:embrace#bufsurf#BufferRingListAll()', {output = true})
        --           print('output: ' .. vim.inspect(output))
        --           print(output.output)
        --           print('- done')
        --         end, desc = "BufferRingListAll"
        --       },
        --     },
        --
        --     config__WORKS = function()
        --       vim.cmd('nnoremap <silent> <leader>db :call g:embrace#bufsurf#BufferRingListAll()<CR>')
        --       vim.cmd('inoremap <silent> <leader>db :<C-O>call g:embrace#bufsurf#BufferRingListAll()<CR>')
        --     end,
        --
        -- FIXME: SPIKE: What's better?:
        --   vim.api.nvim_call_function("g:embrace#bufsurf#BufferRingListAll", {})
        --   vim.fn["embrace#bufsurf#BufferRingListAll"]()
        {
          "<localleader>dB",
          mode = { "n", "i" },
          -- SPIKE/2025-02-05: Why does using closure inhibit user seeing
          -- messages and needing to acknowledge &more prompt? E.g., this:
          --   function() vim.api.nvim_call_function()...  end,
          -- vs. this:
          '<cmd>lua vim.api.nvim_call_function("g:embrace#bufsurf#BufferRingListAll", {})<CR>',
          desc = "Inspect Buffer-Ring",
        },
      })
    end,
  },
}
