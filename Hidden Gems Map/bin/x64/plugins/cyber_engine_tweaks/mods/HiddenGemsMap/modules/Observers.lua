
local Logging = require('modules/Logging')
local Mappins = require('modules/Mappins')
local Vars = require('modules/Vars')

local Observers = {}

---comment
function Observers.setup()
    Logging.console('Observers setup.', 2)

    ---comment
    ---@param this any
    ObserveAfter('BaseMappinBaseController', 'UpdateRootState', function(this)
        if not Vars.settings.disable then
            Mappins.BaseMappinBaseController_UpdateRootState(this)
        end
    end)

    ---comment
    ---@param self any
    ---@param data any
    ---@param menu any
    ObserveAfter('WorldMapTooltipController', 'SetData', function(self, data, menu)
        if not Vars.settings.disable then
		    Mappins.WorldMapTooltipController_SetData(self, data, menu)
        end
	end)

    Logging.console('Observers setted.', 2)
end

return Observers
