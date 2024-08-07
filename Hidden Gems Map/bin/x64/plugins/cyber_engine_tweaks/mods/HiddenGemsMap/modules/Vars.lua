local Vars = {
    -- Indicates a pins cleanup process was triggered
    clear = false,
    -- Pins default color
    color = { red = 65, green = 144, blue = 115 },
    -- Concealable pin options table
    concealable = {},
    -- Indicates the mod's routines should be disabled
    disable = false,
    -- Hidden gems table loaded from the database
    gems = {},
    -- Player's item inventory table
    inventory = {},
    -- Stores the game's interface current language
    language = '',
    -- Settings localization table loaded from the database
    localization = {},
    -- Filtered shards table
    lockeys = {},
    -- Log filename
    logname = '',
    -- Map pins table
    pins = {},
    -- Settings table loaded from the settings file
    settings = {},
    -- Player's shards codex table
    shards = {},
    -- Player's item stash table
    stash = {},
    -- Filtered items table
    tdbids = {},
    -- Text localization table loaded from the database
    texts = {},
    -- Mod's timers for the current map refresh cycle
    timers = {}
}

return Vars