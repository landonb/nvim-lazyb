-- vim:tw=0:ts=2:sw=2:et:ai:ft=lua
-- Author: Landon Bouma <https://tallybark.com/>
-- Project: https://github.com/landonb/nvim-lazyb#🧸

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

---@class lazyb.util.ctrl2pua-keys
local M = {}

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

-- KLUGE: <Shift-Ctrl> keybindings.
-- - CXREF: See Alacritty substitutions for the terminal:
--     [[keyboard.bindings]]
--       ~/.depoxy/ambers/home/.config/alacritty/alacritty.toml @ 402
-- - CXREF: See Hammerspoon substitution for Neovide (and MacVim):
--     macvim_shift_ctrl_kludge_get_eventtap
--       ~/.depoxy/ambers/home/.hammerspoon/depoxy-hs.lua @ 166
--   You'll find more in the DepoXy project:
--     https://github.com/DepoXy/depoxy#🍯
--   Specifically the three files:
--     https://github.com/DepoXy/depoxy/blob/release/home/.config/alacritty/alacritty.toml#L282-L350
--     https://github.com/DepoXy/depoxy/blob/release/home/.hammerspoon/depoxy-hs.lua#L124-L175
--     https://github.com/DepoXy/vim-depoxy/blob/release/plugin/vim-shift-ctrl-bindings.vim

-- \uE000  \uE001  \uE002  \uE003  \uE004  \uE005  \uE006  \uE007
--   A      B      C      D      E      F      G      H 
-- \uE008  \uE009  \uE00A  \uE00B  \uE00C  \uE00D  \uE00E  \uE00F
--   I      J      K      L      M      N      O      P 
-- \uE010  \uE011  \uE012  \uE013  \uE014  \uE015  \uE016  \uE017
--   Q      R      S      T      U      V      W      X 
-- \uE018  \uE019  \uE01A  \uE01B  \uE01C
--   Y      Z      ;      '      | 

M.ctrl_keys = {
  A = "",
  B = "",
  C = "",
  D = "",
  E = "",
  F = "",
  G = "",
  H = "",
  I = "",
  J = "",
  K = "",
  L = "",
  M = "",
  N = "",
  O = "",
  P = "",
  Q = "",
  R = "",
  S = "",
  T = "",
  U = "",
  V = "",
  W = "",
  X = "",
  Y = "",
  Z = "",
  -- ["`"] = "",
  -- ["~"] = "",
  -- ["1"] = "",
  -- ["!"] = "",
  -- ["2"] = "",
  -- ["@"] = "",
  -- ["3"] = "",
  -- ["#"] = "",
  -- ["4"] = "",
  -- ["$"] = "",
  -- ["5"] = "",
  -- ["%"] = "",
  -- ["6"] = "",
  -- ["^"] = "",
  -- ["7"] = "",
  -- ["&"] = "",
  -- ["8"] = "",
  -- ["*"] = "",
  -- ["9"] = "",
  -- ["("] = "",
  -- ["0"] = "",
  -- [")"] = "",
  -- ["-"] = "",
  -- ["_"] = "",
  -- ["="] = "",
  -- ["+"] = "",
  -- ["["] = "",
  -- ["{"] = "",
  -- ["]"] = "",
  -- ["}"] = "",
  -- ["\\"] = "",
  ["|"] = "",
  [";"] = "",
  -- [":"] = "",
  ["'"] = "",
  -- ['"'] = "",
  -- [","] = "",
  -- ["<"] = "",
  -- ["."] = "",
  -- [">"] = "",
  -- ["/"] = "",
  -- ["?"] = "",
}

-- MAYBE: Return error instead if char not registered.
function M.lookup(char)
  return M.ctrl_keys[char] or "<S-C-" .. char .. ">"
end

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

return M
