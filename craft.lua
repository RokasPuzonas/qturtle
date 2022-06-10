assert(turtle, "The quickturtle library is for turtles only")

local expect = require("cc.expect")

local crafting_grid = {1, 2, 3, 5, 6, 7, 9, 10, 11}
local non_crafting_grid = {4, 8, 12, 13, 14, 15, 16}

local function countAllItems()
	local itemCounts = {}

	for i=1, 16 do
		local detail = turtle.getItemDetail(i)
		if detail then
			itemCounts[detail.name] = itemCounts[detail.name] or 0
			itemCounts[detail.name] = itemCounts[detail.name] + detail.count
		end
	end

	return itemCounts
end

local function calculcateMaxCraftsAmount(storedItems, minRequiredItems)
	local amount = 64
	for name, minAmount in pairs(minRequiredItems) do
		amount = math.min(amount, math.floor((storedItems[name] or 0) / minAmount))
	end
	return math.max(amount, 1)
end

local function transferToAnySlot(from_slot, available_slots, target_left_amount)
	target_left_amount = target_left_amount or 0
	turtle.select(from_slot)
	for _, to_slot in pairs(available_slots) do
		turtle.transferTo(to_slot, turtle.getItemCount(from_slot) - target_left_amount)
		if turtle.getItemCount(from_slot) == target_left_amount then break end
	end
end

local function countItems(items)
	local count = {}
	for _, name in pairs(items) do
		count[name] = (count[name] or 0) + 1
	end
	return count
end

local function dropUnneededItems(slot, stored_items, needed_items)
	-- If there are no items in this slot, do nothing
	local detail = turtle.getItemDetail(slot)
	if not detail then return end

	-- Check how many items are unneeded
	-- If there are enough items, do nothing
	local name = detail.name
	local unneeded = stored_items[name] - needed_items[name]
	if unneeded <= 0 then return end

	-- Drop the unneeded amount and update stored items table
	turtle.select(slot)
	stored_items[name] = stored_items[name] - math.min(unneeded, turtle.getItemCount())
	turtle.drop(unneeded)
end

local function getItemName(slot)
	local detail = turtle.getItemDetail(slot)
	return detail and detail.name
end

local function craft(recipe, craft_amount)
	if not turtle.craft then
		return false, "crafting table not found"
	end

	if craft_amount ~= nil then
		expect.expect(craft_amount, "number", "nil")
		craft_amount = math.floor(craft_amount)
		expect.range(craft_amount, 1, 64)
	end

	local min_required_items = countItems(recipe)
	local stored_items = countAllItems()
	local needed_items

	-- Ensure that there are enough items before doing anything
	do
		-- If amount was not given, calculate how many items can be crafted
		if not craft_amount then
			craft_amount = calculcateMaxCraftsAmount(stored_items, min_required_items)
		end

		-- Calculate the needed amounts of each item
		needed_items = {}
		for name, min_amount in pairs(min_required_items) do
			needed_items[name] = min_amount * craft_amount
		end

		-- Check if there are enough items for crafting the amount of items wanted
		for name, needed_amount in pairs(needed_items) do
			local missing_amount = needed_amount - (stored_items[name] or 0)
			if missing_amount > 0 then
				return false, ("not enough %s, missing %s"):format(name, missing_amount)
			end
		end
	end

	-- Remove every item that is not going to be used up in the recipe
	do
		-- 1. First prioritize removing items from non crafting slots
		for _, slot in ipairs(non_crafting_grid) do
			dropUnneededItems(slot, stored_items, needed_items)
		end
		-- 2. If there are still items that need to be removed remove them from crafting slots
		for _, slot in ipairs(crafting_grid) do
			dropUnneededItems(slot, stored_items, needed_items)
		end
	end

	-- Rearrange items into their correct slots
	for i, slot in pairs(crafting_grid) do
		local recipe_item = recipe[i]

		-- If the slot is supposed to be empty, remove move all items to
		-- a temporary slot
		if not recipe_item then
			if turtle.getItemCount(slot) > 0 then
				transferToAnySlot(slot, non_crafting_grid)
			end
		else
			-- Place item in temporary slot if it's name does not match
			local current_item = getItemName(slot)
			if current_item and current_item ~= recipe_item then
				transferToAnySlot(slot, non_crafting_grid)
			end

			-- If current slot is empty or not full, find items from other slots
			-- First grab items from temporary slots
			if turtle.getItemCount(slot) < craft_amount then
				for _, search_slot in pairs(non_crafting_grid) do
					if getItemName(search_slot) == recipe_item then
						local missing_amount = craft_amount - turtle.getItemCount(slot)
						turtle.select(search_slot)
						turtle.transferTo(slot, missing_amount)
						-- If there are enough items, search can be stopped
						if turtle.getItemCount(slot) == craft_amount then break end
					end
				end
			end

			-- If current slot is empty or not full, find items from other slots
			-- Then grab items from other crafting grid slots
			if turtle.getItemCount(slot) < craft_amount then
				for j, search_slot in pairs(crafting_grid) do
					local slot_item_name = getItemName(search_slot)
					if slot_item_name == recipe_item then
						local missing_amount = craft_amount - turtle.getItemCount(slot)

						-- Determine how many items can be taken from this slot
						-- 1. If the item present in this slot is correct with the recipe
						--    Only take as many items that are extra in that slot
						-- 2. If the item present in this slot is not correct with the recipe
						--    Take as much as you need
						local transfer_amount
						if recipe[j] ~= slot_item_name then
							transfer_amount = missing_amount
						else
							local extra_amount = turtle.getItemCount(search_slot) - craft_amount
							transfer_amount = math.min(missing_amount, extra_amount)
						end

						if transfer_amount > 0 then
							turtle.select(search_slot)
							turtle.transferTo(slot, transfer_amount)
							-- If there are enough items, search can be stopped
							if turtle.getItemCount(slot) == craft_amount then break end
						end
					end
				end
			end
		end
	end

	-- Try crafting
	-- return turtle.craft(craft_amount)
end

return craft
