# nvim-lazyb 🧸

My personal, powerful [LazyVim 💤](https://github.com/LazyVim/LazyVim) distro.

This is essentially stock LazyVim (98% unchanged) with additional last-mile
plumbing, such as:

- Adding \<Ctrl-Shift> bindings, including \<Ctrl-Shift-S> to save a file
  without formatting it (because LazyVim wires `conform.nvim` to format on
  save by default);

- Disabling indent guides, which I find distracting;

- And much more.

It also adds a numbers of plugins I've grown to love and depend upon over
the years, including:

- A powerful `/`-search plugin that uses \<F1> to start a search, and doesn't
  require escaping special characters;

- A browser plugin that'll open the URL under the cursor with `gW`,
  will define the word under the cursor with \<LocalLeader>D, or will
  search the word under the cursor with \<LocalLeader>W;

- An `mswin.vim`-like plugin that lets you select text with shifted
  special keys; wires \<Ctrl-X>, \<Ctrl-C>, and \<Ctrl-V> to Cut,
  Copy, and Paste (and moves blockwise Visual select from \<Ctrl-V>
  to \<Ctrl-Q>); repurposes \<Ctrl-Z> so it doesn't minimize or suspend
  Neovim, but performs Undo instead, along with \<Ctrl-Y> to Redo (and
  moves Scroll window upwards from \<Ctrl-Y> to \<Ctrl-Shift-E>);

- And much, much more.

Hopefully someday I'll document everything!

- But in the meantime, poke around the specs, or feel feel to run it and
  check out the `which-key` menus to get a taste of all the additional
  features.

  - Most of the new features are under \<LocalLeader>, mapped to `\`.

  - But a few select features have been added to LazyVim's \<Leader>
    namespace (under space) when appropriate, including \<Leader>uk to
    toggle completions, and \<Leader>uq to toggle the Quickfix window.

With mad respect to @folke for their groundbreaking work on LazyVim,
and to the countless individuals in the Vim and Neovim communities for
contributing decades of plugins, inspiration, and help, and for keeping
Vim, and now Neovim, the best editor money can't buy, 'cause it's free! =)
And especially to Bram who made this all possible.

I appreciate your curiosity, and I hope you find some goodies inside!
