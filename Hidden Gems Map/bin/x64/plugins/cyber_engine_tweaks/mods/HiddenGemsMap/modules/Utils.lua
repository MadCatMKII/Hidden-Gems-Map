local Vars = require('modules/Vars')

local Utils = {}

---comment
---@param color any
---@return any
function Utils.getColorStyle(color)
	return Color.ToHDRColorDirect(Color.new({ Red = color.red, Green = color.green, Blue = color.blue, Alpha = 1 }))
end

---comment
---@param origin any
---@param destination any
---@return number
function Utils.calculateDistance(origin, destination)
	local powX2 = ((origin.x - destination.x)^2)
	local powY2 = ((origin.y - destination.y)^2)
	local powZ2 = ((origin.z - destination.z)^2)
	return math.sqrt(powX2 + powY2 + powZ2)
end

---comment
---@param p1 any
---@param p2 any
---@return boolean
function Utils.isSamePosition(p1, p2)
	local result = false
	if math.floor(p1.x) == math.floor(p2.x) then
        if math.floor(p1.y) == math.floor(p2.y) then
            result = math.floor(p1.z) == math.floor(p2.z)
		end
	end
    return result
end

---comment
---@param p1 any
---@param p2 any
---@param radius number
---@param zradius number
---@return boolean
function Utils.isNearPosition(p1, p2, radius, zradius)
	local result = false
	if (p1.x >= p2.x - radius) and (p1.x <= p2.x + radius) then
        if (p1.y >= p2.y - radius) and (p1.y <= p2.y + radius) then
			if zradius ~= nil and zradius ~= 0 then
                result = (p1.z >= p2.z - zradius) and (p1.z <= p2.z + zradius)
            else
                result = (p1.z >= p2.z - radius) and (p1.z <= p2.z + radius)
			end
		end
	end
    return result
end

---comment
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

---comment
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

---comment
---@param expected integer
---@param fact string
---@return boolean
function Utils.sameAsFact(expected, fact)
    local actual = Game.GetQuestsSystem():GetFactStr(fact)
    return actual == expected
end

---comment
---@param expected integer
---@param fact string
---@return boolean
function Utils.greaterThanFact(expected, fact)
    local actual = Game.GetQuestsSystem():GetFactStr(fact)
    return actual > expected
end

---comment
---@param expected integer
---@param fact string
---@return boolean
function Utils.lesserThanFact(expected, fact)
    local actual = Game.GetQuestsSystem():GetFactStr(fact)
    return actual < expected
end

---comment
---@param vehicle string
---@return boolean
function Utils.haveVehicle(vehicle)
	return Game.GetVehicleSystem():IsVehiclePlayerUnlocked(string.format('Vehicle.%s', vehicle))
end

---comment
---@param baseId string
---@return boolean
function Utils.haveItem(baseId)
	local tdbid = tostring(TweakDBID(string.format('Items.%s', baseId)))
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

---comment
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

---comment
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