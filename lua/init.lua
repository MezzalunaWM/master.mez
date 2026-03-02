---@module 'master'

---@class Master
---@field default_config MasterConfig
---@field config MasterConfig
---@field state MasterState
---@field builtins Builtins
local M = {};

-- M.builtins = require("master.builtins")

---@class MasterConfig
---@field master_ratio number
---@field tag_count number
---@field focus_on_spawn boolean
---@field refocus_on_kill boolean
---@field screen_gap number
---@field tile_gap number
local default_config = {
	master_ratio = 0.5,
	tag_count = 5,
	focus_on_spawn = true,
	refocus_on_kill = true,
	screen_gap = 12,
	tile_gap = 7
}

---@class MasterTag
---@field master number | nil
---@field stack number[]
---@field floating number[]

---@param config MasterConfig
---@return MasterState
local create_state = function(config)
	---@type MasterTag[]
	local tags = {}

	for i = 1,config.tag_count do
		tags[i] = {
			master = nil,
			floating = {},
			stack = {}
		}
	end

	return {
		tag_id = 1,
		tags = tags,
		master_ratio = config.master_ratio
	}
end

---@class MasterState
---@field tag_id number
---@field tags MasterTag[]
---@field master_ratio number

---@param config MasterConfig
M.setup = function(config)
	--- Here we need to validate the config
	--- DON'T FORGET TO VALIDATE THE CONFIG

	config = default_config

	M.state = create_state(config)

	---@param tag_id number
	local tile_tag = function(tag_id)
		local tag = M.state.tags[tag_id]

		local res = mez.output.get_resolution(0)

		if #tag.stack == 0 then
			print("MASTER: tiling just master")
			mez.view.set_position(tag.master, config.screen_gap, config.screen_gap)
			mez.view.set_size(
				tag.master,
				res.width - config.screen_gap * 2,
				res.height - config.screen_gap * 2)
		else
			print("MASTER: master and stack")
			mez.view.set_position(tag.master, config.screen_gap, config.screen_gap)
			mez.view.set_size(
				tag.master,
				res.width * M.state.master_ratio - config.screen_gap - config.tile_gap,
				res.height - config.screen_gap * 2)

			local stack_x = (res.width * (1 - M.state.master_ratio))
			local stack_width = res.width * (1 - M.state.master_ratio) - config.tile_gap - config.screen_gap
			local stack_height = (res.height - (config.screen_gap * 2) - ((#tag.stack - 1) * config.tile_gap)) / #tag.stack

			for i, view_id in ipairs(tag.stack) do
				mez.view.set_position(view_id,
					stack_x,
					(stack_height + config.tile_gap) * (i - 1) + config.screen_gap)

				mez.view.set_size(view_id, stack_width, stack_height)
			end
		end
	end

	mez.hook.add("ViewMapPre", {
		callback = function(view_id)

			local tag = M.state.tags[M.state.tag_id]

			if tag.master == nil then
				tag.master = view_id
			else
				table.insert(tag.stack, #tag.stack + 1, view_id)
			end

			if config.focus_on_spawn then mez.view.set_focused(view_id) end

			tile_tag(M.state.tag_id)
		end
	})

	mez.hook.add("ViewUnmapPost", {
		callback = function(view_id)
			---@type number | nil
			local tag_idx = nil

			---@type "master" | "stacking" | "floating" | nil
			local type = nil

			---@type number | nil
			local view_idx = nil

			print("made it here")

			for i, curr_tag in ipairs(M.state.tags) do
				local t = M.state.tags[i]

				--- If view is the master
				if view_id == curr_tag.master then
					tag_idx = i
					type = "master"
					break
				end

				--- If view is floating
				for j, curr_view in ipairs(t.floating) do
					if curr_view == view_id then
						tag_idx = i
						type = "floating"
						view_idx = j
						break;
					end
				end

				--- If view is stacking 
				for j, curr_view in ipairs(t.stack) do
					if curr_view == view_id then
						tag_idx = i
						type = "stacking"
						view_idx = j
						break;
					end
				end
			end

			local tag = M.state.tags[tag_idx]

			--- Now remove the view and retile if needed
			if type == "floating" then
				table.remove(tag.floating, view_idx)
			elseif type == "master" then
				tag.master = table.remove(tag.stack, 1)
				tile_tag(tag_idx)

				if config.refocus_on_kill then 
					mez.view.set_focused(tag.master) 
				end
			elseif type == "stacking" then
				local is_last = #tag.stack == view_idx
				table.remove(tag.stack, view_idx)
				tile_tag(tag_idx)

				if config.refocus_on_kill then
					if #tag.stack == 0 then
						mez.view.set_focus(tag.master)
					else
						mez.view.set_focused(is_last and view_idx - 1 or view_idx)
					end
				end
			end
		end
	})
end

return M
