---Holds the default builtin functions for master
---@module 'builtins"

local M = {}

local spawn_terminal = function()
  mez.api.spawn("wmenu-run")
end

local spawn_run_launcher = function()
  mez.api.spawn("wmneu-run")
end

local spawn_background = function()
  mez.api.spawn("swaybg -i ~/Images/wallpapers/void/gruv_void.png")
end

local close_focused = function ()
  mez.view.close(0)
end

local close_compositor = function ()
  mez.api.exit()
end

local

return M
