---@module 'master'

---@class MasterUtils
local M = {}

---@param view_id number
---@param state MasterState
---@return "master" | "floating" | "stacking" | nil view_type
---@return number | nil tag_index
---@return number | nil view_index
M.find_view = function(state, view_id)
	for i, curr_tag in ipairs(state.tags) do
		local t = state.tags[i]

		if view_id == curr_tag.master then
			return "master", i, nil
		end

		for j, curr_view in ipairs(t.floating) do
			if curr_view == view_id then
				return "floating", i, j
			end
		end

		for j, curr_view in ipairs(t.stack) do
			if curr_view == view_id then
				return "stacking", i, j
			end
		end
	end

	return nil, nil, nil
end

---@param item any
---@param repetitions number
---@return any[]
M.replicate = function(item, repetitions)
	local t = {}

	for i = 1, repetitions do
		t[i] = item
	end

	return t
end

return M
