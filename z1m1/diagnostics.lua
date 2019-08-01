local metroidutils = require "z1m1/metroid-utils"
local zeldautils   = require "z1m1/zelda-utils"

local itemsToSync    = {};
local gameMode       = 0;
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
        -- gui.text(5, 224, "Game: " .. "LoZ", null, null, "bottomright");

        --  FOR DEBUG ONLY: Max life, rupees, bombs, keys at all times for testing
        -- memory.writebyte(0x0658, 0xff);
        -- memory.writebyte(0x066d, 0xff);
        -- memory.writebyte(0x066e, 0xff);
        -- memory.writebyte(0x066f, 0xff);

        zeldautils.process_game(itemsToSync);
    elseif(gameCheck == 0x03) then -- Metroid
        gameMode = 1;
        -- gui.text(1, 204, "I1: " .. string.format("x%x", memory.readbyte(0x0748)) .. " I2: " .. string.format("x%x", memory.readbyte(0x0750)) ..
        -- "NT1: " .. string.format("x%x", memory.readbyte(0x074B)) .. " NT2: " .. string.format("x%x", memory.readbyte(0x0753)) .. " XY1: " ..
        -- string.format("x%x", memory.readbyte(0x0749)) .. "," .. string.format("x%x", memory.readbyte(0x074A)));
        -- gui.text(1, 214, " XY2: " .. string.format("x%x", memory.readbyte(0x0751)) ..
        -- "," .. string.format("x%x", memory.readbyte(0x0752)) .. " " .. tostring(itemsToSync) ..
        -- " samus.table: " .. memory.readbyte(0x030c));

        --  FOR DEBUG ONLY:  Full equipment and missiles
        -- memory.writebyte(0x6878, 0xff);
        -- memory.writebyte(0x6879, 0xff);
        -- memory.writebyte(0x687a, 0xff);

        --  Metroid item detection testing:
        local mode2 = memory.readbyte(0x001e);

        metroidutils.process_game(itemsToSync);
    else --invalid game mode
        gameMode = 2;
    end;
end;

return {
    z1m1 = z1m1,
    whichGame = whichGame,
    items = itemsToSync,
    ZeldaCache = ZeldaCache,
    MetroidCache = MetroidCache,
    HyruleProgress = HyruleProgress,
    ZebesProgress = ZebesProgress,
    IsSyncPortalDisabled = IsSyncPortalDisabled,
    DisableSyncPortal = DisableSyncPortal
};