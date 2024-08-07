local Vars = require('modules/Vars')

local Utils = {}

--- Convertes RGB color data in HDR color data
---@param color any
---@return any
function Utils.getColorStyle(color)
	return Color.ToHDRColorDirect(Color.new({ Red = color.red, Green = color.green, Blue = color.blue, Alpha = 1 }))
end

--- Calculates distance between two positions
---@param origin any
---@param destination any
---@return number
function Utils.calculateDistance(origin, destination)
	v1 = Vector4.new(origin.x, origin.y, origin.z, 1.0)
	v2 = Vector4.new(destination.x, destination.y, destination.z, 1.0)
	return Vector4.DistanceSquared(v1, v2)
end

--- Checks if two positions are equal
---@param p1 any
---@param p2 any
---@return boolean
function Utils.isSamePosition(p1, p2)
	return Utils.calculateDistance(p1, p2) == 0
end

--- Checks if two positions are near based on a radius distance
---@param p1 any
---@param p2 any
---@param radius number
---@param zradius number
---@return boolean
function Utils.isNearPosition(p1, p2, radius)
	return Utils.calculateDistance(p1, p2) < radius
end

--- Sends a neutral notification to the player
---@param title integer
function Utils.notify(title)
	local blackboardDefs = Game.GetAllBlackboardDefs()
	local blackboardUI = Game.GetBlackboardSystem():Get(blackboardDefs.UI_Notifications)
	local text = Vars.texts[2]
	local message = SimpleScreenMessage.new()
	message.message = string.format(text, title)
	message.isShown = true
	message.duration = 5
	message.type = 'Neutral'
	blackboardUI:SetVariant(blackboardDefs.UI_Notifications.WarningMessage, ToVariant(message), true)
end

--- Checks if a shard exists in player's codex
---@param lockey string
---@return boolean
function Utils.haveShard(lockey)
	for _, shard in pairs(Vars.shards) do
		if shard.data.title == lockey then
			return true
		end
	end
	return false
end

--- Checks if a fact is equal to a threshold in player's background
---@param expected integer
---@param fact string
---@return boolean
function Utils.sameAsFact(expected, fact)
    local actual = Game.GetQuestsSystem():GetFactStr(fact)
    return actual == expected
end

--- Checks if a fact is above a threshold in player's background
---@param expected integer
---@param fact string
---@return boolean
function Utils.greaterThanFact(expected, fact)
    local actual = Game.GetQuestsSystem():GetFactStr(fact)
    return actual > expected
end

--- Checks if a fact is below a threshold in player's background
---@param expected integer
---@param fact string
---@return boolean
function Utils.lesserThanFact(expected, fact)
    local actual = Game.GetQuestsSystem():GetFactStr(fact)
    return actual < expected
end

--- Checks if a vehicle exists in player's garage
---@param vehicle string
---@return boolean
function Utils.haveVehicle(vehicle)
	return Game.GetVehicleSystem():IsVehiclePlayerUnlocked(string.format('Vehicle.%s', vehicle))
end

--- Checks if a recipe exists in player's craft book
---@param name string
---@return boolean
function Utils.haveRecipe(name)
	local tdbid
	local known = false
	local crafting = Game.GetScriptableSystemsContainer():Get('CraftingSystem')
	local craftbook = crafting:GetPlayerCraftBook()
	tdbid = TweakDBID(string.format('Items.Common_%s', name))
	known = known or craftbook:KnowsRecipe(tdbid)
	tdbid = TweakDBID(string.format('Items.Uncommon_%s', name))
	known = known or craftbook:KnowsRecipe(tdbid)
	tdbid = TweakDBID(string.format('Items.Rare_%s', name))
	known = known or craftbook:KnowsRecipe(tdbid)
	tdbid = TweakDBID(string.format('Items.Epic_%s', name))
	known = known or craftbook:KnowsRecipe(tdbid)
	tdbid = TweakDBID(string.format('Items.Legendary_%s', name))
	known = known or craftbook:KnowsRecipe(tdbid)
	return known
end

--- Checks if an item exists in player's inventory or stash
---@param record string
---@return boolean
function Utils.haveItem(record)
	local tdbid = tostring(TweakDBID(record))
	for _, item in pairs(Vars.inventory) do
		if tostring(item:GetID().id) == tdbid then
			return true
		end
	end
	for _, item in pairs(Vars.stash) do
		if tostring(item:GetID().id) == tdbid then
			return true
		end
	end
	return false
end

--- Filter items from a list of items
---@param filter table
---@param list table
---@return table
function Utils.filterItems(filter, list)
	local items = {}
	local set = {}
	for _, item in ipairs(list) do
		set[tostring(item:GetID().id)] = item
	end
	for _, tdbid in ipairs(filter) do
		table.insert(items, set[tdbid])
	end
	return items
end

--- Filter shards from a list of shards
---@param filter table
---@param list table
---@return table
function Utils.filterShards(filter, list)
	local shards = {}
	local set = {}
	for _, shard in ipairs(list) do
		set[shard.data.title] = shard
	end
	for _, lockey in ipairs(filter) do
		table.insert(shards, set[lockey])
	end
	return shards
end

--- Reads json data from a file
---@param path string
---@return any
function Utils.readJson(path)
	local file = io.open(path, 'r')
    if file ~= nil then
        local data = file:read('*a')
		local valid, decoded = pcall(function() return json.decode(data) end)
        if valid then
			file:close()
			return decoded
		end
    end
    return nil
end

--- Writes json data overwriting a file
---@param path string
---@param data string
---@return boolean
function Utils.writeJson(path, data)
	local file = io.open(path, 'w+')
	if file ~= nil then
		local valid, encoded = pcall(function() return json.encode(data) end)
		if valid and encoded ~= nil then
			file:write(encoded);
			file:close();
			return true
		end
	end
	return false
end

return Utils