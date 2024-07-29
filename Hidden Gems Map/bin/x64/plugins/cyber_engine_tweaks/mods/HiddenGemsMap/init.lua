local Cron = require('external/Cron')
local GameUI = require('external/GameUI')
local Logging = require('modules/Logging')
local Manager = require('modules/Manager')
local Observers = require('modules/Observers')
local Settings = require('modules/Settings')
local Utils = require('modules/Utils')
local Vars = require('modules/Vars')

local HiddenGemsMap = {
    version = '1.3.7',
    cet = 1.32,
    filename = 'settings.json',
    logname = 'console.log',
    ticker = nil,
    paused = false,
    changed = false,
    reloaded = true,
    settings = {
        -- Sets the mod disabled
        disable = false,
        -- Sets the debug level
        debug = 1,
        -- Sets the map update frequency cycle in seconds
        frequency = 15.0,
        -- Sets the show or hide of specific pins
        concealable = {true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true,
            true, true, true }
    }
}

function HiddenGemsMap:new()

    ---comment
    function HiddenGemsMap.loadData()
        Vars.cet = self.cet
        Vars.language = Game.NameToString(Game.GetSettingsSystem():GetVar("/language", "OnScreen"):GetValue())
        local column = string.gsub(Vars.language, '-', '_')
        for record in db:rows(string.format('SELECT field, %s FROM settings', column)) do
            local field, localization = table.unpack(record)
            Vars.localization[field] = localization
        end
        for record in db:rows(string.format('SELECT id, tag, %s FROM concealable', column)) do
            local id, tag, localization = table.unpack(record)
            Vars.concealable[id] = {}
            Vars.concealable[id].tag = tag
            Vars.concealable[id].loc = localization
        end
        for record in db:rows(string.format('SELECT id, %s FROM localization', column)) do
            local id, localization = table.unpack(record)
            Vars.texts[id] = localization
        end
        for record in db:rows('SELECT * FROM hidden_gems') do
            local id, tag, gemId, titleId, descId, typemap, coords, logic, icon, range = table.unpack(record)
            coords = json.decode(coords)
            logic = json.decode(logic)
            local row = {}
            row.tag = tag
            row.gemId = gemId
            row.title = string.format(Vars.texts[titleId], gemId)
            row.desc = Vars.texts[descId]
            row.typemap = typemap
            row.position = Vector4.new(coords.x, coords.y, coords.z, 1.0)
            row.logic = logic
            row.icon = icon
            row.range = range
            Vars.gems[id] = row
        end
        for record in db:rows('SELECT lockey FROM shards') do
            local lockey = table.unpack(record)
            table.insert(Vars.lockeys, lockey)
        end
        for record in db:rows('SELECT tdbid FROM items') do
            local tdbid = table.unpack(record)
            table.insert(Vars.tdbids, tostring(TweakDBID(tdbid)))
        end
    end

    ---comment
    function HiddenGemsMap.update()
        local success
        local data = CodexListSyncData.new()
        local stash = Game.FindEntityByID(EntityID.new({ hash = 16570246047455160070ULL }))
        Vars.shards = {}
        Vars.inventory = {}
        Vars.stash = {}
        Vars.shards = CodexUtils.GetShardsDataArray(GameInstance.GetJournalManager(), data)
        Logging.log(string.format('Found %s shards in codex.', #Vars.shards), 2)
        Vars.shards = Utils.filterShards(Vars.shards)
        Logging.log(string.format('Filtered %s shards in codex.', #Vars.shards), 2)
        success, Vars.inventory = Game.GetTransactionSystem():GetItemList(Game.GetPlayer())
        if (success) then
            Logging.log(string.format('Found %s items in inventory.', #Vars.inventory), 2)
            Vars.inventory = Utils.filterItems(Vars.inventory)
            Logging.log(string.format('Filtered %s items in inventory.', #Vars.inventory), 2)
        else
            Logging.log('Fail to obtain items in inventory.', 2)
        end
        success, Vars.stash = Game.GetTransactionSystem():GetItemList(stash)
        if (success) then
            Logging.log(string.format('Found %s items in stash.', #Vars.stash), 2)
            Vars.stash = Utils.filterItems(Vars.stash)
            Logging.log(string.format('Filtered %s items in stash.', #Vars.stash), 2)
        else
            Logging.log('Fail to obtain items in stash.', 2)
        end
    end

    ---comment
    function HiddenGemsMap.resume()
        if self.reloaded then
            self.update()
            Manager.updatePins()
            self.reloaded = false
        end
        if self.changed then
            Cron.Halt(self.ticker)
            self.paused = false
            self.changed = false
        end
        Logging.console('Resuming rotines.', 2)
        if self.paused then
            Cron.Resume(self.ticker)
            for _, timer in pairs(Vars.timers) do
                Cron.Resume(timer)
            end
        else
            self.ticker = Cron.Every(self.settings.frequency, function(timer)
                Vars.timers = {}
                Logging.log(string.format('Tick #%d from a %.2f seconds cycle.', timer.tick, timer.interval), 3)
                Manager.schedulePins()
                timer.tick = timer.tick + 1
            end, { tick = 1 })
        end
        self.paused = false
        Logging.console('Resumed rotines.', 2)
    end

    ---comment
    function HiddenGemsMap.pause()
        Logging.console('Pausing rotines.', 2)
        for _, timer in pairs(Vars.timers) do
            Cron.Pause(timer)
        end
        Cron.Pause(self.ticker)
        self.paused = true
        self.update()
        if self.reloaded then
            Manager.updatePins()
            self.reloaded = false
        end
        Logging.console('Paused rotines.', 2)
    end

    ---comment
    registerForEvent('onInit', function()
        self.loadData()
        Vars.logname = self.logname
        Logging.create('Starting log...\n')
        Settings.setup(self)
        Observers.setup()
        if not self.settings.disable then
            Logging.console('Mod inicializing.', 2)
            GameUI.Listen(function(state)
                if not self.settings.disable then
                    local event = GameUI.ExportState(state)
                    if (event:find('event = "WheelOpen"')) then
                        self.pause()
                    elseif (event:find('event = "PopupOpen"')) then
                        self.pause()
                    elseif (event:find('event = "MenuOpen"')) then
                        self.pause()
                    elseif (event:find('event = "WheelClose"')) then
                        self.resume()
                    elseif (event:find('event = "PopupClose"')) then
                        self.resume()
                    elseif (event:find('event = "MenuClose"')) then
                        self.resume()
                    elseif (event:find('event = "SessionEnd"')) then
                        Logging.console('Ending rotines.', 2)
                        Manager.clearPins()
                        self.paused = false
                        Logging.console('Ended rotines.', 2)
                    elseif (event:find('event = "SessionStart"')) then
                        Logging.console('Starting rotines.', 2)
                        self.reloaded = true
                        self.resume()
                        Vars.clear = false
                        Logging.console('Started rotines.', 2)
                    elseif (event:find('event = "MenuClose"')) then
                        if (event:find('lastMenu = "Hub"')) then
                            self.reloaded = true
                            self.resume()
                        elseif (event:find('lastMenu = "MainMenu"')) then
                            self.loadData()
                        end
                    elseif (event:find('event = "MenuNav"')) and (event:find('lastSubmenu = "Settings"')) then
                        self.loadData()
                        Settings.setup(self)
                        Settings.refresh()
                    end
                end
            end)
            Logging.console('Mod initialized.', 2)
        end
    end)

    ---comment
    registerForEvent('onUpdate', function(delta)
         -- This is required for Cron to function
        Cron.Update(delta)
    end)

    ---comment
    registerForEvent('onShutdown', function()
        Manager.clearPins()
        Logging.conclude('Closing log...')
    end)

    return self
end

return HiddenGemsMap:new()