-- vim:tw=0:ts=2:sw=2:et:ai:ft=lua
-- Author: Landon Bouma <https://tallybark.com/>
-- Project: https://github.com/landonb/nvim-lazyb#🧸

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

---@class lazyb.util.alt2meta-keys
local M = {}

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

-- REFER/2025-09-09: Related project, with both 'en-US' and 'en-GB'
-- lookups (brilliant idea!):
--   https://github.com/clvnkhr/macaltkey.nvim/blob/master/lua/macaltkey/dicts.lua

-- REFER/2025-03-03: Meta binding characters.
-- - From docs, |<T-| bindings are "meta-key when it's not alt",
--   but they don't work for me. Use the literal character that
--   macOS emits instead to use Meta-key bindings.

-- <T-a>  <T-b>  <T-c>  <T-d>  <T-e>  <T-f>  <T-g>  <T-h>
--  å Å    ∫ ı    ç Ç    ∂ Î    † ´    ƒ Ï    © ˝    ˙ Ó
-- <T-i>  <T-j>  <T-k>  <T-l>  <T-m>  <T-n>  <T-o>  <T-p>
--  † ˆ    ∆ Ô    ˚     ¬ Ò    µ Â    ˜ ˜    ø Ø    π ∏
-- <T-q>  <T-r>  <T-s>  <T-t>  <T-u>  <T-v>  <T-w>  <T-x>
--  œ Œ    ® ‰    ß Í    † ˇ    † ¨    √ ◊    ∑ „    ≈ ˛
-- <T-y>  <T-z>  <T-`>  <T-1>  <T-2>  <T-3>  <T-4>  <T-5>
--  ¥ Á    ¸ Ω           ¡ ⁄    ™ €    £ ‹    ¢ ›    ∞ ﬁ
-- <T-6>  <T-7>  <T-8>  <T-9>  <T-0>  <T-->  <T-=>
--  § ﬂ    ¶ ‡    • °    ª ·    º ‚    – —    ≠ ±
-- <T-[>  <T-]>  <T-\>  <T-;>  <T-'>  <T-,>  <T-.>  <T-/>
--  “ ”    ‘ ’    « »    … Ú    æ Æ    ≤ ¯    ¯ ˘    ÷ ¿
--   †: macOS waits for a second character

M.alt_keys = {
  a = "å",
  A = "Å",
  b = "∫",
  B = "ı",
  c = "ç",
  C = "Ç",
  d = "∂",
  D = "Î",
  -- e = "†",
  -- E = "´",
  f = "ƒ",
  F = "Ï",
  g = "©",
  G = "˝",
  h = "˙",
  H = "Ó",
  -- i = "†",
  -- I = "ˆ",
  j = "∆",
  J = "Ô",
  k = "˚",
  K = "",
  l = "¬",
  L = "Ò",
  m = "µ",
  M = "Â",
  n = "˜",
  N = "˜",
  o = "ø",
  O = "Ø",
  p = "π",
  P = "∏",
  q = "œ",
  Q = "Œ",
  r = "®",
  R = "‰",
  s = "ß",
  S = "Í",
  -- t = "†",
  -- T = "ˇ",
  -- u = "†",
  -- U = "¨",
  v = "√",
  V = "◊",
  w = "∑",
  W = "„",
  x = "≈",
  X = "˛",
  y = "¥",
  Y = "Á",
  z = "¸",
  Z = "Ω",
  -- ["`"] = "",
  -- ["~"] = "",
  ["1"] = "¡",
  ["!"] = "⁄",
  ["2"] = "™",
  ["@"] = "€",
  ["3"] = "£",
  ["#"] = "‹",
  ["4"] = "¢",
  ["$"] = "›",
  ["5"] = "∞",
  ["%"] = "ﬁ",
  ["6"] = "§",
  ["^"] = "ﬂ",
  ["7"] = "¶",
  ["&"] = "‡",
  ["8"] = "•",
  ["*"] = "°",
  ["9"] = "ª",
  ["("] = "·",
  ["0"] = "º",
  [")"] = "‚",
  ["-"] = "–",
  ["_"] = "—",
  ["="] = "≠",
  ["+"] = "±",
  ["["] = "“",
  ["{"] = "”",
  ["]"] = "‘",
  ["}"] = "’",
  ["\\"] = "«",
  ["|"] = "»",
  [";"] = "…",
  [":"] = "Ú",
  ["'"] = "æ",
  ['"'] = "Æ",
  [","] = "≤",
  ["<"] = "¯",
  ["."] = "¯",
  [">"] = "˘",
  ["/"] = "÷",
  ["?"] = "¿",
}

function M.lookup(char)
  if M.IsUsingMetaKeys() then
    return "<M-" .. char .. ">"
  else
    local alt_key = M.alt_keys[char]

    if alt_key then
      return alt_key
    else
      print("ERROR: Unusable or unmapped Alt-key for char: " .. char)

      return ""
    end
  end
end

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

function M.PrepareAltKeySequences()
  -- if M.IsUsingMetaKeys() then
  --   M.alt_f = "<M-f>"
  --   M.alt_w = "<M-w>"
  -- else
  --   M.alt_f = "ƒ"
  --   M.alt_w = "∑"
  -- end
  M.alt_f = M.lookup("f")
  M.alt_w = M.lookup("w")
end

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

-- By default, Neovide and MacVim use literal <Alt> characters, which do
-- not (seem to) work with any of the <M->, <T->, or <A-> map sequences.
-- - Here we check if user has enabled meta output instead, which is
--   how <Alt> keypresses work on Linux (and prob. Windows  ¯\_(ツ)_/¯).

-- Cached flag indicates if user logged on via SSH, which would mean
-- they're not using Option keys (AFAIK (author), that's not possible),
-- and that we can use Alt/Meta bindings.
M.is_user_logged_on_via_ssh = nil

function M.IsUsingMetaKeys()
  if M.is_user_logged_on_via_ssh == nil then
    M.is_user_logged_on_via_ssh = M.IsUserLoggedOnViaSSH()
  end

  -- stylua: ignore
  return (
    -- Using Meta keys (or (Apple) Option keys) if:
    -- - Logged on via SSH
    M.is_user_logged_on_via_ssh or
    -- - Not on macOS
    (vim.fn.has("macunix") == 0) or
    -- - On macOS, running Neovide, and enabled on left or both
    vim.g.neovide and (
      vim.g.neovide_input_macos_option_key_is_meta == "both"
      or vim.g.neovide_input_macos_option_key_is_meta == "only_left"
    )
  )
end

-- COPYD/2025-09-09: The following fcn. is converted from a shell func.
-- that checks if user running nvim over an SSH session by checking
-- local environs and the command names of parent processes.
-- - Project: https://github.com/DepoXy/sh-humble-prompt#🙇
--   _humb_prompt_is_user_logged_on_via_ssh()
-- - CXREF: If you're running DepoXy, it's at:
--   ~/.kit/sh/sh-humble-prompt/lib/set-shell-prompt-and-window-title.sh
--
-- THANX: https://unix.stackexchange.com/questions/9605/how-can-i-detect-if-the-shell-is-controlled-from-ssh
-- - "If one of the variables SSH_CLIENT or SSH_TTY is defined, it's an ssh session.
--    If the login shell's parent process name is sshd, it's an ssh session."

-- REFER: See lots of notes about accessing $$, $PPID, $gpid, $gppid, etc.:
-- ~/.kit/nvim/DepoXy/start/vim-depoxy/after/plugin/vim_minimal_sometimes.vim
--
-- - Note the different fcn. syntax:
--   - Send list of args:
--     local command_name = vim.fn.system { "ps", "-o", ... }
--   - Send single string:
--     local command_name = vim.fn.system([[ps -o ...]])
--
-- - REFER: See also:
--     |vim.system()| — use instead of |jobstart()|
--                      can be run (a)synchronously
--     |job-control| — for multitasking/non-blocking
--
--   - DEBAR/2025-09-09: I considered replacing all vim.fn.system() usage w/
--     vim.system(), but I don't see a clear benefit. What I do see is a more
--     convoluted call.
--     - E.g., using vim.fn.system:
--         local pid = vim.fn.system([[echo "$$"]])
--     - Vs. using vim.system:
--         local pid = vim.system({ "bash", "-c", [[echo $$]] }, { text = true }):wait().stdout
--     - Note these alt. approaches don't work:
--         -- Prints only "\n"
--         vim.fn.system("echo", "$$")
--         -- Prints literal "$$\n"
--         vim.fn.system { "echo", "$$" }
--         vim.system({ "echo", "$$" }, { text = true }):wait().stdout
--         -- Errors
--         vim.system({ "echo \"$$\"" }, { text = true }):wait().stdout
--
-- - SAVVY: Neovim runs this command in a new process, so
--   (obviously) its process ID is ephemeral, and its name
--   is the shell, e.g., "bash".
--     local pid = vim.fn.system([[echo "$$"]])
--     local pid_name = vim.fn.system([[ps -o comm= -p $$ | sed 's/:.*$//']])

-- SAVVY: This fcn. checks if user logged on via SSH.
-- - Easiest check is if SSH_CLIENT or SSH_TTY nonempty.
-- - Fallback check is matching sshd against 3 ancestor processes.
--   - FOREX: Some examples:
--     - gpid, ggpid, and gggpid, respectively, from Neovide on local Deb:
--         neovide -- --listen /tmp/nvim.socket-🧸
--         /lib/systemd/systemd --user
--         /sbin/init splash
--     - gpid, ggpid, and gggpid, respectively, from nvim on SSH macOS
--         nvim
--         -bash
--         sshd-session: user@ttys012
--       - Or gggpid on nvim SSH Linux:
--         sshd: user@pts/3
--   - SAVVY: We'll regex for "^sshd:" followed by ":",
--     albeit author submits, I don't know if all SSHd
--     process commands are thusly named.
--
-- CPYST:
-- - Print gpid, ggpid, and gggpid commands:
--   lua print(vim.fn.system([[gpid="$(ps -o ppid= -p ${PPID} | tr -d " ")";ggpid="$(ps -o ppid= -p ${gpid} | tr -d " ")";gggpid="$(ps -o ppid= -p ${ggpid} | tr -d " ")";(ps -o command= -p ${gpid};ps -o command= -p ${ggpid};ps -o command= -p ${gggpid};)]]))
-- - Filter gpid, ggpid, and gggpid sshd commands:
--   lua print(vim.fn.system([[gpid="$(ps -o ppid= -p ${PPID} | tr -d " ")";ggpid="$(ps -o ppid= -p ${gpid} | tr -d " ")";gggpid="$(ps -o ppid= -p ${ggpid} | tr -d " ")";(ps -o command= -p ${gpid};ps -o command= -p ${ggpid};ps -o command= -p ${gggpid};) | grep -e "^sshd\(\-session\)\?: .*$";]]))

function M.IsUserLoggedOnViaSSH()
  if
    (vim.env.SSH_CLIENT and vim.env.SSH_CLIENT ~= "")
    or (vim.env.SSH_TTY and vim.env.SSH_TTY ~= "")
  then
    return true
  else
    -- DUNNO/2024-10-28: Not sure this branch is ever followed.
    -- - I'd expect that SSH_CLIENT/SSH_TTY always set by sshd.
    vim.fn.system([[
      gpid="$(ps -o ppid= -p ${PPID} | tr -d " ")";
      ggpid="$(ps -o ppid= -p ${gpid} | tr -d " ")";
      gggpid="$(ps -o ppid= -p ${ggpid} | tr -d " ")";
      (ps -o command= -p ${gpid};
       ps -o command= -p ${ggpid};
       ps -o command= -p ${gggpid};
      ) | grep -q -e "^sshd\(\-session\)\?: .*";]])

    if vim.v.shell_error == 0 then
      return true
    end

    return false
  end
end

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

function M.AltKeyDesc(desc, lhs)
  return desc .. (not M.IsUsingMetaKeys() and (" " .. lhs) or "")
end

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

M.PrepareAltKeySequences()

return M
