-- vim:tw=0:ts=2:sw=2:et:ai:ft=lua
-- Author: Landon Bouma <https://tallybark.com/>
-- Project: https://github.com/landonb/nvim-lazyb#🧸

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

---@class lazyb.util.alt2meta-keys
local M = {}

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

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
    return M.alt_keys[char]
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

function M.IsUsingMetaKeys()
  return vim.g.neovide
    and (
      vim.g.neovide_input_macos_option_key_is_meta == "both"
      or vim.g.neovide_input_macos_option_key_is_meta == "only_left"
    )
end

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

function M.AltKeyDesc(desc, lhs)
  return desc .. (not M.IsUsingMetaKeys() and (" " .. lhs) or "")
end

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

M.PrepareAltKeySequences()

return M
