local Vars = require('modules/Vars')

local Logging = {}

---comment
---@param message string
---@return string
function Logging.format(message)
    local time = os.date("*t")
    return string.format('[Hidden Gems Map] %02d:%02d:%02d: %s\n', time.hour, time.min, time.sec, message)
end

---comment
function Logging.create(message)
    local logfile = io.open(Vars.logname, 'w')
    if logfile ~= nil then
        logfile:write(Logging.format(message))
        logfile:close()
    end
end

---comment
function Logging.conclude(message)
    local logfile = io.open(Vars.logname, 'a')
    if logfile ~= nil then
        logfile:write(Logging.format(message))
        logfile:close()
    end
end

---comment
---@param message string
---@param level integer
function Logging.log(message, level)
    if Vars.settings.debug >= level then
        Logging.console(message, level)
        local logfile = io.open(Vars.logname, 'a')
        if logfile ~= nil then
            logfile:write(Logging.format(message))
            logfile:close()
        end
    end
end

---comment
---@param message string
---@param level integer
function Logging.console(message, level)
    if Vars.settings.debug >= level then
        print(Logging.format(message))
    end
end

return Logging