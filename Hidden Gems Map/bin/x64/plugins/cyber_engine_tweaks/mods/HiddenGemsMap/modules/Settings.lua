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
    local subSettings = '/main/Settings'
    local subConcealable = '/main/Concealable'
    local tags = {
        'dev_easter_egg',
        'dev_room_01',
        'card_player_robots',
        'button_easter_egg',
        'ep1_growl',
        'mws_se5_03_game_started',
        'blade_runner_easter_egg',
        'wst_cat_dtn_01_scene',
        'dev_room_02',
        'mdt_ep1_barghest_base',
        'mdt_ep1_barricade',
        'mdt_ep1_brainporium',
        'mdt_ep1_kress_street',
        'mdt_ep1_luxor_high_wellness_spa',
        'mdt_ep1_overpass',
        'mdt_ep1_parking_garage',
        'mdt_ep1_stadium',
        'mdt_ep1_terra_cognita',
        'wst_cat_ep1_01_scene'
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
        return string.format(texts.ShowDesc, Settings.getTitle(tag))
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

    if texts ~= nil then
        NativeSettings.addTab(tab, texts.Tab)

        if NativeSettings.pathExists(subSettings) then
            NativeSettings.removeSubcategory(subSettings)
        end
        NativeSettings.addSubcategory(subSettings, texts.Settings)

        NativeSettings.addSwitch(subSettings, texts.DisableLabel, texts.DisableDesc, disable, false, function(state)
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
        NativeSettings.addSelectorString(subSettings, texts.LogLabel, texts.LogDesc, list, debug, 1, function(value)
            debug = value
            main.settings.debug = debug
            Settings.save(main)
        end)

        NativeSettings.addRangeInt(subSettings, texts.FreqLabel, texts.FreqDesc, 15, 60, 1, frequency, 5,
         function(value)
            frequency = value
            main.changed = true
            main.settings.frequency = frequency
            Settings.save(main)
        end)

        if NativeSettings.pathExists(subConcealable) then
            NativeSettings.removeSubcategory(subConcealable)
        end
        NativeSettings.addSubcategory(subConcealable, texts.Concealable)

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