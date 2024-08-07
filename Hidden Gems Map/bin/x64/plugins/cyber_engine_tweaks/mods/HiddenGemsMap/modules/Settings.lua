local Logging = require('modules/Logging')
local Manager = require('modules/Manager')
local Utils = require('modules/Utils')
local Vars = require('modules/Vars')

local Settings = {}

--- Sets up settings screen tab
---@param main any
function Settings.setup(main)
    local NativeSettings = GetMod('nativeSettings')
    local loc = Vars.localization
    local tab = '/main'
    local subSettings = '/main/Settings'
    local subConcealable = '/main/Concealable'

    --- Refreshs the settings screen tab
    function Settings.refresh()
	    NativeSettings.refresh()
    end

    -- Checks for Cyber Engine Tweaks required version
    local cet = tonumber((GetVersion():gsub('^v(%d+)%.(%d+)%.(%d+)(.*)', function(major, minor, patch, wip)
        return ('%d.%02d%02d%d'):format(major, minor, patch, (wip == '' and 0 or 1))
    end)))
    if cet < main.cet then
        Logging.console(string.format('Cyber Engine Tweaks version %s or higher is required', main.cet), 1)
        return
    end

    -- Checks for Native Settings UI presence
    if not NativeSettings then
        Logging.console('Native Settings UI missing. Resuming with settings from file.', 1)
        return
    end

    -- Loads or creates the settings file
    local settings = Utils.readJson(main.filename)
    if settings ~= nil and settings.concealable ~= nil and #settings.concealable == (#Vars.concealable + 1) then
        for key, _ in pairs(settings) do
            if settings[key] ~= nil then
                main.settings[key] = settings[key]
            end
		end
        Vars.settings = main.settings
    else
        Settings.save(main)
	end

    -- Loads all settings to local variables
    local disable = main.settings.disable
    local debug = main.settings.debug
    local frequency = main.settings.frequency
    local concealable = main.settings.concealable

    if loc ~= nil then
        -- Sets up the settings tab
        NativeSettings.addTab(tab, loc.Tab)

        -- Sets up the settings subcategory
        if NativeSettings.pathExists(subSettings) then
            NativeSettings.removeSubcategory(subSettings)
        end
        NativeSettings.addSubcategory(subSettings, loc.Subcategory)

        -- Sets up the disable switch
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

        -- Sets up the logging level selector
        local list = {[1] = loc.Default, [2] = loc.Load, [3] = loc.Pins, [4] = loc.Decisions}
        NativeSettings.addSelectorString(subSettings, loc.LogLabel, loc.LogDesc, list, debug, 1,
            function(value)
                debug = value
                main.settings.debug = debug
                Settings.save(main)
            end
        )

        -- Sets up the update frequency configurer
        NativeSettings.addRangeInt(subSettings, loc.FreqLabel, loc.FreqDesc, 15, 60, 1, frequency, 5,
            function(value)
                frequency = value
                main.changed = true
                main.settings.frequency = frequency
                Settings.save(main)
            end
        )

        -- Sets up the concealable subcategory
        if NativeSettings.pathExists(subConcealable) then
            NativeSettings.removeSubcategory(subConcealable)
        end
        NativeSettings.addSubcategory(subConcealable, loc.Concealable)

        -- Sets up the Missing Persons and Pacifica Typhoon switch
        loc.FilterLabel = string.format(loc.FilterLabel, 'Missing Persons', 'Pacifica Typhoon')
        loc.FilterDesc = string.format(loc.FilterDesc, loc.FilterLabel)
        NativeSettings.addSwitch(subConcealable, loc.FilterLabel, loc.FilterDesc, concealable[1], true,
            function(state)
                concealable[1] = state
                main.settings.concealable = concealable
                Manager.updatePins()
                Settings.save(main)
            end
        )

        -- Sets up the remaining concealable switchs
        for i = 1, #Vars.concealable, 1 do
            local title = 'Unknown Hidden Gem'
            local desc = 'Unknown Hidden Gem'
            for _, gem in pairs(Vars.gems) do
                if string.find(gem.tag, Vars.concealable[i].tag) then
                    title = string.format('%s\n%s', gem.title, Vars.concealable[i].loc)
                    desc = gem.title
                    break
                end
            end
            desc = string.format(loc.ShowDesc, desc)
            NativeSettings.addSwitch(subConcealable, title, desc, concealable[i + 1], true,
                function(state)
                    concealable[i + 1] = state
                    main.settings.concealable = concealable
                    Manager.updatePins()
                    Settings.save(main)
                end
            )
        end
    else
        Logging.console('Error on the settings localization loading.', 1)
        return
    end
end

--- Saves settings on a file
---@param main any
function Settings.save(main)
    Vars.settings = main.settings
    Utils.writeJson(main.filename, main.settings)
end

return Settings