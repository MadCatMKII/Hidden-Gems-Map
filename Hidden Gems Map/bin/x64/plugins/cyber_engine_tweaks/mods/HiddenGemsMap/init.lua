local Cron = require('external/Cron')
local GameSession = require('external/GameSession')
local GameUI = require('external/GameUI')
local Logging = require('modules/Logging')
local Manager = require('modules/Manager')
local Observers = require('modules/Observers')
local Settings = require('modules/Settings')
local Vars = require('modules/Vars')

local HiddenGemsMap = {
    version = '1.0.0',
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
        -- Sets the hide or unhide of Militech data terminals
        terminals = true
    }
}

function HiddenGemsMap:new()

    ---comment
    function HiddenGemsMap.loadData()
        Vars.cet = self.cet
        Vars.language = Game.NameToString(Game.GetSettingsSystem():GetVar("/language", "OnScreen"):GetValue())
        for record in db:rows('SELECT * FROM localization') do
            local id, localization = table.unpack(record)
            localization = json.decode(localization)
            Vars.texts[id] = localization
        end
        for record in db:rows('SELECT * FROM hidden_gems') do
            local id, tag, gemId, titleId, descId, typemap, coords, logic, icon, range = table.unpack(record)
            coords = json.decode(coords)
            logic = json.decode(logic)
            local row = {}
            row.tag = tag
            row.gemId = gemId
            row.title = string.format(Vars.texts[titleId][Vars.language], gemId)
            row.desc = Vars.texts[descId][Vars.language]
            row.typemap = typemap
            row.position = Vector4.new(coords.x, coords.y, coords.z, 1.0)
            row.logic = logic
            row.icon = icon
            row.range = range
            Vars.gems[id] = row
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
        success, Vars.inventory = Game.GetTransactionSystem():GetItemList(Game.GetPlayer())
        success, Vars.stash = Game.GetTransactionSystem():GetItemList(stash)
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
    end

    ---comment
    function HiddenGemsMap.pause()
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
            GameSession.Listen(function(state)
                if not self.settings.disable then
                    local event = GameSession.ExportState(state)
                    if (event:find('event = "Resume"') ~= nil) then
                        Logging.console('Resuming rotines.', 2)
                        self.resume()
                        Logging.console('Resumed rotines.', 2)
                    elseif (event:find('event = "Pause"') ~= nil)  then
                        Logging.console('Pausing rotines.', 2)
                        self.pause()
                        Logging.console('Paused rotines.', 2)
                    elseif (event:find('event = "End"') ~= nil) or (event:find('event = "SessionEnd"') ~= nil) then
                        Logging.console('Ending rotines.', 2)
                        Manager.clearPins()
                        self.reloaded = true
                        Logging.console('Ended rotines.', 2)
                    end
                end
            end)
            GameUI.Listen(function(state)
                if not self.settings.disable then
                    GameUI.PrintState(state)
                     local event = GameUI.ExportState(state)
                    if (event:find('event = "WheelOpen"')) then
                        self.pause()
                    elseif (event:find('event = "PopupOpen"')) then
                        self.pause()
                    elseif (event:find('event = "WheelClose"')) then
                        self.resume()
                    elseif (event:find('event = "PopupClose"')) then
                        self.resume()
                    elseif (event:find('event = "MenuClose"')) and (event:find('lastMenu = "MainMenu"')) then
                        self.loadData()
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