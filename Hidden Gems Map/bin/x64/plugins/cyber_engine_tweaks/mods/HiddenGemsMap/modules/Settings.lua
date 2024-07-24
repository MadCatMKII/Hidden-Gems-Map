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
    local tags = {
        'dev_easter_egg',-- 1 - Dev Sightseeing Point
        'dev_room_01', -- 2 - Dev Room Kabuki
        'card_player_robots', -- 3 - Card Player Robots
        'button_easter_egg', -- 4 - Chapter Hill Red Button
        'ep1_growl', -- 5 - Growl FM Party
        'mws_se5_03_game_started', -- 6 - Arasaka Tower 3D
        'blade_runner_easter_egg', -- 7 - Blade Runner Easter Egg
        'wst_cat_dtn_01_scene', -- 8 - Downtown's Cat
        'dev_room_02', -- 9 - Arasaka Memorial
        'mdt_ep1_barghest_base', -- 10 - Barghest Base Data Terminal
        'mdt_ep1_barricade', -- 11 - Barricade Data Terminal
        'mdt_ep1_brainporium', -- 12 - Brainporium Data Terminal
        'mdt_ep1_kress_street', -- 13 - Kress Street Data Terminal
        'mdt_ep1_luxor_high_wellness_spa', -- 14 - Luxor High Wellness Spa Data Terminal
        'mdt_ep1_overpass', -- 15 - Overpass Data Terminal
        'mdt_ep1_parking_garage',  -- 16 - Parking Garage Data Terminal
        'mdt_ep1_stadium', -- 17 - Stadium Data Terminal
        'mdt_ep1_terra_cognita', -- 18 - Terra Cognita Data Terminal
        'wst_cat_ep1_01_scene' -- 19 - Dogtown's Cat
    }

    ---comment
    function Settings.refresh()
	    NativeSettings.refresh()
    end

    ---comment
    ---@param tag string
    ---@return string
    function Settings.getTitle(tag)
	    for _, gem in pairs(Vars.gems) do
            if gem.tag == tag then
			    return gem.title
		    end
        end
    end

    ---comment
    ---@param tag string
    ---@return string
    function Settings.getDesc(tag)
        return string.format(loc.ShowDesc, Settings.getTitle(tag))
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
    if settings ~= nil and settings.concealable ~= nil and #settings.concealable == #tags then
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

        for i = 1, #tags, 1 do
            NativeSettings.addSwitch(subConcealable, Settings.getTitle(tags[i]), Settings.getDesc(tags[i]),
                concealable[i], true, function(state)
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