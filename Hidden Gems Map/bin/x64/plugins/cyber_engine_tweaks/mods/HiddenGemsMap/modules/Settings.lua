local Logging = require('modules/Logging')
local Manager = require('modules/Manager')
local Utils = require('modules/Utils')
local Vars = require('modules/Vars')

local Settings = {}

---comment
---@param main any
function Settings.setup(main)
    local NativeSettings = GetMod('nativeSettings')
    local loc = Vars.localization
    local tab = '/main'
    local subSettings = '/main/Settings'
    local subConcealable = '/main/Concealable'

    ---comment
    function Settings.refresh()
	    NativeSettings.refresh()
    end

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
    if settings ~= nil and settings.concealable ~= nil and #settings.concealable == #Vars.concealable then
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
    local concealable = main.settings.concealable

    if loc ~= nil then
        NativeSettings.addTab(tab, loc.Tab)

        if NativeSettings.pathExists(subSettings) then
            NativeSettings.removeSubcategory(subSettings)
        end
        NativeSettings.addSubcategory(subSettings, loc.Subcategory)

        NativeSettings.addSwitch(subSettings, loc.DisableLabel, loc.DisableDesc, disable, false,
            function(state)
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
            end
        )

        local list = {[1] = loc.Default, [2] = loc.Load, [3] = loc.Pins, [4] = loc.Decisions}
        NativeSettings.addSelectorString(subSettings, loc.LogLabel, loc.LogDesc, list, debug, 1,
            function(value)
                debug = value
                main.settings.debug = debug
                Settings.save(main)
            end
        )

        NativeSettings.addRangeInt(subSettings, loc.FreqLabel, loc.FreqDesc, 15, 60, 1, frequency, 5,
            function(value)
                frequency = value
                main.changed = true
                main.settings.frequency = frequency
                Settings.save(main)
            end
        )

        if NativeSettings.pathExists(subConcealable) then
            NativeSettings.removeSubcategory(subConcealable)
        end
        NativeSettings.addSubcategory(subConcealable, loc.Concealable)

        for i = 1, #Vars.concealable, 1 do
            local title = 'Unknown Hidden Gem'
            local desc = 'Unknown Hidden Gem'
            for _, gem in pairs(Vars.gems) do
                if gem.tag == Vars.concealable[i].tag then
                    title = string.format('%s\n%s', gem.title, Vars.concealable[i].loc)
                    desc = gem.title
                    break
                end
            end
            desc = string.format(loc.ShowDesc, desc)
            NativeSettings.addSwitch(subConcealable, title, desc, concealable[i], true,
                function(state)
                    concealable[i] = state
                    main.settings.concealable = concealable
                    Manager.updatePins()
                    Settings.save(main)
                end)
        end
    end
end

---comment
---@param main any
function Settings.save(main)
    Vars.settings = main.settings
    Utils.writeJson(main.filename, main.settings)
end

return Settings