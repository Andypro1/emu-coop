local metroidutils = require "z1m1/metroid-utils"
local zeldautils   = require "z1m1/zelda-utils"

local itemsToSync    = {};
local gameMode       = 0;
local inNormalPlayMode = false;
local ZeldaCache     = {};
local HyruleProgress = {};
local MetroidCache   = {};
local ZebesProgress  = {};

local syncPortalDisabled = false;

local function inTable(tbl, item)
    for key, value in pairs(tbl) do
        if value == item then return key end
    end;

    return false;
end;

local function tableMin(tbl)
    local min = 999999999;

    for key, value in pairs(tbl) do
        if(value < min) then
            min = value;
        end;
    end;

    return min;
end;

local function avgTable(tbl)
    local sum   = 0;
    local count = 0;

    for key, value in pairs(tbl) do
        sum   = sum + value;
        count = count + 1;
    end;

    if(tbl.count == 0) then
        return 0;
    end;

    return math.floor((sum / count) + 0.5);
end;

local function whichGame()
    return gameMode;
end;

local function InNormalGameplayMode()
    return inNormalPlayMode;
end;

local function IsSyncPortalDisabled()
    return syncPortalDisabled;
end;

local function DisableSyncPortal(isdisabled)
    syncPortalDisabled = isdisabled;
end;

local function z1m1()
    --  Game detection
    local gameCheck = memory.readbyte(0xe440);

    if(gameCheck == 0xa9) then -- Legend of Zelda
        gameMode = 0;

        --  Process zelda gameplay for items.
        --  Check return value for normal gameplay to report to consuming client whether
        --  it's safe to take action on memory change callbacks, etc.
        inNormalPlayMode = zeldautils.process_game(itemsToSync);
    elseif(gameCheck == 0x03) then -- Metroid
        gameMode = 1;

        --  Process metroid gameplay for items.
        --  Check return value for normal gameplay to report to consuming client whether
        --  it's safe to take action on memory change callbacks, etc.
        inNormalPlayMode = metroidutils.process_game(itemsToSync);
    else --invalid game mode
        gameMode = 2;
        inNormalPlayMode = false;
    end;
end;

return {
    z1m1 = z1m1,
    whichGame = whichGame,
    InNormalGameplayMode = InNormalGameplayMode,
    items = itemsToSync,
    ZeldaCache = ZeldaCache,
    MetroidCache = MetroidCache,
    HyruleProgress = HyruleProgress,
    ZebesProgress = ZebesProgress,
    IsSyncPortalDisabled = IsSyncPortalDisabled,
    DisableSyncPortal = DisableSyncPortal
};