local Logging = require('modules/Logging')
local Manager = require('modules/Manager')
local Utils = require('modules/Utils')
local Vars = require('modules/Vars')

local Settings = {}

---comment
---@param main any
function Settings.setup(main)
    local NativeSettings = GetMod('nativeSettings')
    local texts = Utils.readJson(string.format('languages/%s.json', Vars.language))
    local tab = '/main'
    local subcategory = '/main/Settings'

    local cet = tonumber((GetVersion():gsub('^v(%d+)%.(%d+)%.(%d+)(.*)', function(major, minor, patch, wip)
        return ('%d.%02d%02d%d'):format(major, minor, patch, (wip == '' and 0 or 1))
    end)))
    if cet < main.cet then
        Logging.console(string.format('Cyber Engine Tweaks version %s or higher is required', main.cet), 1)
        return
    end

    if not NativeSettings then
        Logging.console('Native Settings UI missing. Resuming with settings from file.', 1)
        return
    end

    local settings = Utils.readJson(main.filename)
    if settings ~= nil then
        for key, _ in pairs(settings) do
            if settings[key] ~= nil then
                main.settings[key] = settings[key]
            end
		end
        Vars.settings = main.settings
    else
        Settings.save(main)
	end
    local disable = main.settings.disable
    local debug = main.settings.debug
    local frequency = main.settings.frequency
    local terminals = main.settings.terminals

    if texts ~= nil then
        if not NativeSettings.pathExists(tab) then
            NativeSettings.addTab(tab, texts.Tab)
        end

        if NativeSettings.pathExists(subcategory) then
            NativeSettings.removeSubcategory(subcategory)
        end

        NativeSettings.addSubcategory(subcategory, texts.Subcategory)

        NativeSettings.addSwitch(subcategory, texts.DisableLabel, texts.DisableDesc, disable, false, function(state)
            disable = state
            if disable then
                Manager.clearPins()
                Logging.conclude('Closing log...')
                Logging.console('Mod disabled.', 2)
            else
                Logging.create('Starting log...\n')
                Logging.console('Mod loaded.', 2)
                Manager.updatePins()
                Logging.console('Mod initialized.', 2)
            end
            main.settings.disable = disable
            Settings.save(main)
        end)

        local list = {[1] = texts.Default, [2] = texts.Load, [3] = texts.Pins, [4] = texts.Decisions}
        NativeSettings.addSelectorString(subcategory, texts.LogLabel, texts.LogDesc, list, debug, 1, function(value)
            debug = value
            main.settings.debug = debug
            Settings.save(main)
        end)

        NativeSettings.addRangeInt(subcategory, texts.FreqLabel, texts.FreqDesc, 15, 60, 1, frequency, 5, function(value)
            frequency = value
            main.changed = true
            main.settings.frequency = frequency
            Settings.save(main)
        end)

        NativeSettings.addSwitch(subcategory, texts.TermLabel, texts.TermDesc, terminals, true, function(state)
            terminals = state
            main.settings.terminals = terminals
            Manager.updatePins()
            Settings.save(main)
        end)
    end
end

---comment
---@param main any
function Settings.save(main)
    Vars.settings = main.settings
    Utils.writeJson(main.filename, main.settings)
end

return Settings