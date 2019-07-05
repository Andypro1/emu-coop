local metroidutils = require "z1m1/metroid-utils"
local zeldautils   = require "z1m1/zelda-utils"

local itemsToSync = {};

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

local function InitGlobals()
    gameMode         = 0;
end;

local function z1m1()
     if(gameMode == nil) then InitGlobals(); end;

    --  Game detection
    local gameCheck = memory.readbyte(0xe440);

    --  Metroid item testing
    local new_room_loaded = false;
    local handled_pickup = nil;

    if(gameCheck == 0xa9) then
        gameMode = 0;
        -- gui.text(5, 224, "Game: " .. "LoZ", null, null, "bottomright");

        --  Max life, rupees, bombs, keys at all times for testing
        -- memory.writebyte(0x0658, 0xff);
        -- memory.writebyte(0x066d, 0xff);
        -- memory.writebyte(0x066e, 0xff);
        -- memory.writebyte(0x066f, 0xff);

        zeldautils.process_game(itemsToSync);
    elseif(gameCheck == 0x03) then
        gameMode = 1;
        -- gui.text(5, 224, "Game: " .. "Metroid", null, null, "bottomright")

        -- memory.writebyte(0x6878, 0xff);
        -- memory.writebyte(0x6879, 0xff);
        -- memory.writebyte(0x687a, 0xff);

        --  Metroid item detection testing:
        local mode2 = memory.readbyte(0x001E);

        metroidutils.process_game(itemsToSync);
    end;


    -- if(next(itemsToSync) ~= nil) then
    --     emu.message("itemsToSync has item.");
    -- end;
   -- emu.frameadvance();
end;

return {
    z1m1 = z1m1,
    items = itemsToSync
};