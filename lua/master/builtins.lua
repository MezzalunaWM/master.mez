---Holds the default builtin functions for master
---@module 'builtins"

local M = {}

local close_focused = function ()
  mez.view.close(0)
end

local close_compositor = function ()
  mez.api.exit()
end

return M
