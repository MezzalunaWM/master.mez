---@module 'master'

---@class Master
---@field default_config MasterConfig
---@field config MasterConfig
---@field state MasterState
local M = {}

---@module 'master.utils'
local utils = require("master.utils")

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

---@class MasterState
---@field tag_id number
---@field tags MasterTag[]
---@field master_ratio number


---@param tag_id number
M.tile_tag = function(tag_id)
	local tag = M.state.tags[tag_id]

	local res = mez.output.get_resolution(0)

	if tag.master == nil then return end

	if #tag.stack == 0 then
		mez.view.set_position(tag.master, M.config.screen_gap, M.config.screen_gap)
		mez.view.set_size(
			tag.master,
			res.width - M.config.screen_gap * 2,
			res.height - M.config.screen_gap * 2
		)
	else
		mez.view.set_position(tag.master, M.config.screen_gap, M.config.screen_gap)
		mez.view.set_size(
			tag.master,
			res.width * M.state.master_ratio - M.config.screen_gap - M.config.tile_gap,
			res.height - M.config.screen_gap * 2
		)

		local stack_x = (res.width * (1 - M.state.master_ratio))
		local stack_width = res.width * (1 - M.state.master_ratio) - M.config.tile_gap - M.config.screen_gap
		local stack_height = (res.height - (M.config.screen_gap * 2) - ((#tag.stack - 1) * M.config.tile_gap)) / #tag.stack

		for i, view_id in ipairs(tag.stack) do
			mez.view.set_position(view_id,
			stack_x,
			(stack_height + M.config.tile_gap) * (i - 1) + M.config.screen_gap)

			mez.view.set_size(view_id, stack_width, stack_height)
		end
	end
end

---@param view_id number
M.add_view = function(view_id)
	local tag = M.state.tags[M.state.tag_id]

	if tag.master == nil then
		tag.master = view_id
	else
		table.insert(tag.stack, #tag.stack + 1, view_id)
	end

	if M.config.focus_on_spawn then mez.view.set_focused(view_id) end

	M.tile_tag(M.state.tag_id)
end

M.focus_next = function()
	local view_id = mez.view.get_focused_id()
	local type, tag_idx, view_idx = utils.find_view(M.state, view_id)
	local tag = M.state.tags[tag_idx]

	if type == "floating" then
		if view_idx == #tag.floating then
			if tag.master ~= nil then
				mez.view.set_focused(tag.master)
			else
				mez.view.set_focused(tag.floating[1])
			end
		else
			mez.view.set_focused(tag.floating[view_idx + 1])
		end
	elseif type == "master" then
		if #tag.stack ~= 0 then
			mez.view.set_focused(tag.stack[1])
		elseif #tag.floating ~= 0 then
			mez.view.set_focused(tag.floating[1])
		else
			mez.view.set_focused(tag.master)
		end
	elseif type == "stacking" then
		if view_idx == #tag.stack then
			if #tag.floating ~= 0 then
				mez.view.set_focused(tag.floating[1])
			else
				mez.view.set_focused(tag.master)
			end
		else
			mez.view.set_focused(tag.stack[view_idx + 1])
		end
	end
end

M.focus_prev = function()
	local view_id = mez.view.get_focused_id()
	local type, tag_idx, view_idx = utils.find_view(M.state, view_id)
	local tag = M.state.tags[tag_idx]

	if type == "floating" then
		if view_idx == 1 then
			if #tag.stack ~= 0 then
				mez.view.set_focused(tag.stack[#tag.stack])
			elseif tag.master ~= nil then
				mez.view.set_focused(tag.master)
			else
				mez.view.set_focused(tag.floating[#tag.floating])
			end
		else
			mez.view.set_focused(tag.floating[view_idx - 1])
		end
	elseif type == "master" then
		if #tag.floating ~= 0 then
			mez.view.set_focused(tag.floating[#tag.floating])
		elseif #tag.stack ~= 0 then
			mez.view.set_focused(tag.stack[#tag.stack])
		else
			mez.view.set_focused(tag.master)
		end
	elseif type == "stacking" then
		if view_idx == 1 then
			mez.view.set_focused(tag.master)
		else
			mez.view.set_focused(tag.stack[view_idx - 1])
		end
	end
end

---@param view_id number
M.remove_view = function(view_id)
	local type, tag_idx, view_idx = utils.find_view(M.state, view_id)

	local tag = M.state.tags[tag_idx]

	--- Now remove the view and retile if needed
	if type == "floating" then
		table.remove(tag.floating, view_idx)
	elseif type == "master" then
		tag.master = table.remove(tag.stack, 1)
		M.tile_tag(tag_idx)

		if M.config.refocus_on_kill then
			mez.view.set_focused(tag.master)
		end
	elseif type == "stacking" then
		local is_last = #tag.stack == view_idx
		table.remove(tag.stack, view_idx)
		M.tile_tag(tag_idx)

		if M.config.refocus_on_kill then
			if #tag.stack == 0 then
				mez.view.set_focused(tag.master)
			else
				mez.view.set_focused(tag.stack[is_last and view_idx - 1 or view_idx])
			end
		end
	end
end

---@param tag_idx number
M.enable_tag = function (tag_idx)
	local disable_tag = M.state.tags[M.state.tag_id]
	local enable_tag = M.state.tags[tag_idx]

	for _, v in ipairs(disable_tag.floating) do
		mez.view.set_enabled(v, false)
	end

	if disable_tag.master ~= nil then
		mez.view.set_enabled(disable_tag.master, false)

		for _, v in ipairs(disable_tag.stack) do
			mez.view.set_enabled(v, false)
		end
	end


	for _, v in ipairs(enable_tag.floating) do
		mez.view.set_enabled(v, true)
	end

	if disable_tag.master ~= nil then
		mez.view.set_enabled(disable_tag.master, true)

		for _, v in ipairs(disable_tag.stack) do
			mez.view.set_enabled(v, true)
		end
	end

	M.state.tag_id = tag_idx
end

---@param view_id number
M.zoom = function (view_id)
	if view_id == 0 then view_id = mez.view.get_focused_id() end
	local type, tag_idx, view_idx = utils.find_view(M.state, view_id)

	print("tag_id: " .. M.state.tag_id)
	print("tag_idx: " .. tag_idx)

	if type == "floating" or type == "master" or M.state.tag_id ~= tag_idx then return end

	print("getting here")

	local tag = M.state.tags[M.state.tag_id]

	local m = tag.master
	tag.master = table.remove(tag.stack, view_idx)
	table.insert(tag.stack, 1, m)

	M.tile_tag(tag_idx)
end

---@param config MasterConfig
M.setup = function(config)
	--- Here we need to validate the config
	--- DON'T FORGET TO VALIDATE THE CONFIG

	--- TODO: Take the user config into consideration
	M.config = default_config

	M.state = {
		tag_id = 1,
		tags = utils.replicate({
			master = nil,
			floating = {},
			stack = {}
		}, M.config.tag_count),
		master_ratio = M.config.master_ratio
	}

	mez.hook.add("ViewMapPre", { 
		callback = function(view_id)
			local res, err = pcall(M.add_view, view_id)
			if err then
				print(err)
			end
		end
	})

	mez.hook.add("ViewUnmapPost", { 
		callback = function(view_id)
			local res, err = pcall(M.remove_view, view_id)
			if err then
				print(err)
			end
		end
	})

	mez.input.add_keymap("alt", "j", {
		press = function ()
			local res, err = pcall(M.focus_next)
			if err then
				print(err)
			end
		end
	})

	mez.input.add_keymap("alt", "k", {
		press = function ()
			local res, err = pcall(M.focus_prev)
			if err then
				print(err)
			end
		end
	})

	for i = 1, M.config.tag_count do
		mez.input.add_keymap("alt", i, {
			press = function ()
				print("from: " .. M.state.tag_id)
				print("to: " .. i)
				local res, err = pcall(M.enable_tag, i)
				if err then
					print(err)
				end
			end
		})
	end

	mez.input.add_keymap("alt", "Return", {
		press = function ()
			local res, err = pcall(M.zoom, 0)
			if err then
				print(err)
			end
		end
	})
end

return M
