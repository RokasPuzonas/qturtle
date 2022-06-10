assert(turtle, "The quickturtle library is for turtles only")
local qturtle = {}
local craftingGrid = {1, 2, 3, 5, 6, 7, 9, 10, 11}

-- Can pass a 'n' paramter, to tell that it to repeat that action
-- if 'n' is negative it will execute the opposite of that function
local function createRepeatableFunction(positiveFunc, negativeFunc)
	return function(n)
		local func = positiveFunc
		n = n or 1
		if n < 0 and negativeFunc then
			func = negativeFunc
			n = -n
		end

		for i=1, n do
			if func() == false then
				return false, i-1
			end
		end

		return true
	end
end

-- Mines in one place forever until there is not block there
local function createEnhancedDig(digFunc)
	return function(force)
		if force then
			while digFunc() do end
		else
			return digFunc()
		end
	end
end

-- If an item name is given, it will find it and place it
local function createEnhancedPlace(placeFunc)
	return function(itemName)
		if itemName and not qturtle.findAndSelectItem(itemName) then
			return false, "Item not found"
		end
		return placeFunc()
	end
end

function qturtle.turnAround()
	turtle.turnLeft()
	turtle.turnLeft()
end

function qturtle.findItem(itemName)
	for i=1, 16 do
		local detail = turtle.getItemDetail(i)
		if detail and detail.name == itemName then
			return i
		end
	end
end

function qturtle.findAndSelectItem(itemName)
	local selectedDetail = turtle.getItemDetail()
	if selectedDetail and selectedDetail.name == itemName then
		return true
	end

	local slot = qturtle.findItem(itemName)
	if not slot then return false end
	turtle.select(slot)
	return true
end

function qturtle.findEmptySlot()
	for i=1, 16 do
		if turtle.getItemCount(i) == 0 then
			return i
		end
	end
end

function qturtle.doItemsMatch(slot1, slot2)
	local detail1 = turtle.getItemDetail(slot1)
	local detail2 = turtle.getItemDetail(slot2)
	return (not detail1 and not detail2) or (detail1 and detail2 and detail1.name == detail2.name)
end

function qturtle.stackItems()
	for i=1, 15 do
		local spaceLeft = turtle.getItemSpace(i)
		if spaceLeft > 0 and turtle.getItemDetail(i) then
			for j=i+1, 16 do
				if qturtle.doItemsMatch(i, j) then
					spaceLeft = spaceLeft - turtle.getItemCount()
					turtle.select(j)
					turtle.transferTo(i)
					if spaceLeft <= 0 then break end
				end
			end
		end
	end
end

function qturtle.createRecipe()
	local recipe = { }

	for i, slot in ipairs(craftingGrid) do
		local detail = turtle.getItemDetail(slot)
		if detail then
			recipe[i] = detail.name
		end
	end

	return recipe
end

qturtle.turnLeft = createRepeatableFunction(turtle.turnLeft, turtle.turnRight)
qturtle.turnRight = createRepeatableFunction(turtle.turnRight, turtle.turnLeft)

qturtle.forward = createRepeatableFunction(turtle.forward, turtle.back)
qturtle.back = createRepeatableFunction(turtle.back, turtle.forward)

qturtle.dig = createEnhancedDig(turtle.dig)
qturtle.digUp = createEnhancedDig(turtle.digUp)
qturtle.digDown = createEnhancedDig(turtle.digDown)

qturtle.place = createEnhancedPlace(turtle.place)
qturtle.placeUp = createEnhancedPlace(turtle.placeUp)
qturtle.placeDown = createEnhancedPlace(turtle.placeDown)

qturtle.craftRecipe = require("craft")

function qturtle.goDig()
	qturtle.dig(true)
	turtle.forward()
end

function qturtle.goDigDown()
	qturtle.dig(true)
	turtle.down()
end

function qturtle.goDigUp()
	qturtle.digUp(true)
	turtle.up()
end


return qturtle
