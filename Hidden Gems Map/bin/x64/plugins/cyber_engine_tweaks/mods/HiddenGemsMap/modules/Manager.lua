local Cron = require('external/Cron')
local Logging = require('modules/Logging')
local Utils = require('modules/Utils')
local Vars = require('modules/Vars')

local Manager = {}

--- Creates the pin for a hidden gem on the map
---@param gem any
function Manager.createPin(gem)
	local pin = {}
	local data = NewObject('gamemappinsMappinData')
	Logging.log(string.format('Pin creation -> %s -> %s', gem.tag, gem.position), 3)
	data.mappinType = TweakDBID.new('Mappins.DefaultStaticMappin')
	data.variant = Enum.new('gamedataMappinVariant', gem.typemap)
    data.visibleThroughWalls = true
	pin.id = Game.GetMappinSystem():RegisterMappin(data, gem.position)
	Game.GetMappinSystem():SetMappinActive(pin.id, true)
	pin.tag = gem.tag
	pin.position = gem.position
	pin.variant =  gem.typemap
	pin.range = gem.range
	pin.active =  true
	pin.title = gem.title
	pin.desc = gem.desc
	pin.style = {}
	pin.style.color = Vars.color
	pin.style.icon = gem.icon
	Vars.pins[pin.tag] = pin
	Logging.log(string.format('Pin created -> %s -> %s', pin.tag, pin.title), 3)
end

--- Gets a pin by its tag identifier
---@param tag string
---@return any
function Manager.getPinByTag(tag)
	return Vars.pins[tag]
end

--- Checks a pin existence by its tag identifier
---@param tag string
---@return boolean
function Manager.existPinbyTag(tag)
    return Vars.pins[tag] ~= nil
end

--- Removes a pin by its tag identifier
---@param tag string
function Manager.removePinByTag(tag)
	local pin = Manager.getPinByTag(tag)
	Logging.log(string.format('Pin remotion -> %s -> %s', pin.tag, pin.position), 3)
	Game.GetMappinSystem():UnregisterMappin(pin.id)
	Vars.pins[tag] = nil
	Logging.log(string.format('Pin removed -> %s -> %s', pin.tag, pin.title), 3)
end

--- Validates if an expression is true
---@param expression any
---@return boolean
function Manager.validateExpression(expression)
    if expression[1] == 'Setting' then
        if expression[3] == '=' then
            if expression[4] == 1 then
                return Vars.settings.concealable[expression[2]]
            elseif expression[4] == 0 then
                return not Vars.settings.concealable[expression[2]]
            end
        end
    elseif expression[1] == 'Shard' then
        if expression[3] == '=' then
            if expression[4] == 1 then
                return Utils.haveShard(expression[2])
            elseif expression[4] == 0 then
                return not Utils.haveShard(expression[2])
            end
        end
    elseif expression[1] == 'Fact' then
        if expression[3] == '=' then
            return  Utils.sameAsFact(expression[4], expression[2])
        elseif expression[3] == '>' then
            return  Utils.greaterThanFact(expression[4], expression[2])
        elseif expression[3] == '<' then
            return  Utils.lesserThanFact(expression[4], expression[2])
        end
    elseif expression[1] == 'Item' then
        if expression[3] == '=' then
            if expression[4] == 1 then
                return  Utils.haveItem(expression[2])
            elseif expression[4] == 0 then
                return  not Utils.haveItem(expression[2])
            end
        end
    elseif expression[1] == 'Recipe' then
        if expression[3] == '=' then
            if expression[4] == 1 then
                return  Utils.haveRecipe(expression[2])
            elseif expression[4] == 0 then
                return  not Utils.haveRecipe(expression[2])
            end
        end
    elseif expression[1] == 'Vehicle' then
        if expression[3] == '=' then
            if expression[4] == 1 then
                return  Utils.haveVehicle(expression[2])
            elseif expression[4] == 0 then
                return  not Utils.haveVehicle(expression[2])
            end
        end
    end
end

--- Updates the pin for a hidden gem on the map
---@param gem any
function Manager.updatePin(gem, notify)
    local create = true
    local remove = true
    local setting = false
    Logging.log(string.format('Check started -> %s -> %s', gem.title, gem.tag), 4)
    for _, exp in pairs(gem.logic.requirements) do
        create = create and Manager.validateExpression(exp)
        Logging.log(string.format('Req -> %s %s %s %s -> %s', exp[1], exp[2], exp[3], exp[4], create), 4)
    end
    if create and not Manager.existPinbyTag(gem.tag) then
        Manager.createPin(gem)
    end
    for _, exp in pairs(gem.logic.goals) do
        remove = remove and Manager.validateExpression(exp)
        Logging.log(string.format('Goal -> %s %s %s %s -> %s', exp[1], exp[2], exp[3], exp[4], remove), 4)
        setting = setting or exp[1] == 'Setting'
    end
    if remove and #gem.logic.goals > 0 then
        if Manager.existPinbyTag(gem.tag) then
            Manager.removePinByTag(gem.tag)
            if not setting and notify then
                Utils.notify(gem.title)
            end
        end
    end
    if not create and Manager.existPinbyTag(gem.tag) then
        Manager.removePinByTag(gem.tag)
    end
    Logging.log(string.format('Check concluded -> %s -> %s', gem.title, gem.tag), 4)
end

--- Updates all pins for hidden gems on the map
function Manager.updatePins()
    for _, gem in pairs(Vars.gems) do
        Manager.updatePin(gem, false)
    end
end

--- Schedules updates to all pins for hidden gems on the map
function Manager.schedulePins()
    local unit = (Vars.settings.frequency - 0.05) / #Vars.gems
    local delay = 0
    local timers = {}
    for _, gem in pairs(Vars.gems) do
        local id = Cron.After(delay, function ()
            if not Vars.clear then
                Manager.updatePin(gem, true)
            end
        end, { tick = 1 })
        timers[id] = id
        delay = delay + unit
    end
    Vars.timers = timers
end

--- Clears all pins for hidden gems on the map
function Manager.clearPins()
    Vars.clear = true
    for _, timer in pairs(Vars.timers) do
        Cron.Halt(timer)
    end
    Cron.Halt(Vars.ticker)
    for _, pin in pairs(Vars.pins) do
        Manager.removePinByTag(pin.tag)
    end
end

return Manager