---@module 'master'

---@class Master
---@field default_config MasterConfig
---@field config MasterConfig
---@field state MasterState
---@field builtins MasterBuiltins
local M = {};

M.builtins = require("master.builtins")

---@class MasterConfig
---@field master_ratio number
---@field tag_count number
local default_config = {
  master_ratio = 0.5,
  tag_count = 5,
  applications = {
    terminal = "alacritty",
    browser = "zen"
  },
  binds = {
    spawn_terminal = { lhs = { mod = "alt", key = "Return" }, rhs = M.builtins.spawn_terminal },
    spawn_run_launcher = { lhs = { mod = "alt", key = "p" }, rhs = M.builtins.spawn_run_launcher },
    close_focused = { lhs = { mods = "alt|shift", key = "C", rhs = M.builtins.close_focused },
  }
}

---@class Tag
---@field floating number[]
---@field stack number[]

---@class MasterState
---@field tag_id number
---@field tags Tag[]
M.state = {
  tag_id = 1,
  tags = {}
}

M.setup = function(config)

end

return M

