-- STOP! Are you about to edit this file?
-- If you change ANYTHING, please please PLEASE run the following script:
-- https://www.guidgenerator.com/online-guid-generator.aspx
-- and put in a new GUID in the "guid" field.

-- Author: Andypro1 on Github
-- Data source: mostly http://datacrystal.romhacking.net/wiki/The_Legend_of_Zelda:RAM_map
--				and    https://datacrystal.romhacking.net/wiki/Metroid:RAM_map
-- This file is available under Creative Commons CC0

local itemList = require "z1m1/item-table"

local spec = {
	guid = "746cc905-ec55-418b-9098-efe01d573fd7",
	format = "1.0",
	name = "Z1M1 Crossover Randomizer (sync items, progress)",
	--match = {"stringtest", addr=0xffeb, value="ZELDA"},

	gameItems = itemList.items,

	sync = {}
};

for i = 0x067f, 0x06fe do
	spec.sync[i] = {kind = "bitOr", mask = OR(0x80,0x10), gameMode = 0};
end

-- dungeon map data is between 0x6ff and 0x7fe (top left to bottom right, all
-- the dungeons are in a single 2d array with each other)
-- each tile has the following attributes that could be synced:
-- 0x80 some enemies killed in room
-- 0x40 all enemies killed in room
-- 0x20 room visited (shows up on map)
-- 0x10 item collected
-- 0x08 top key door unlocked
-- 0x04 bottom key door unlocked
-- 0x02 left key door unlocked
-- 0x01 right key door unlocked
for i = 0x06ff, 0x07c0 do
	spec.sync[i] = {kind="bitOr", mask=0x3f, gameMode = 0}; -- all but enemy kills? Play around with different masks maybe.
end

--spec.sync[0x07c1] = { kind="bitOr", mask=0x6f, gameMode = 0};  --  Do NOT sync the item in Ganon's room
																 --  uncomment to try syncing room and Ganon
																 --  death state without syncing item state.

for i = 0x07c2, 0x07fe do
	spec.sync[i] = {kind="bitOr", mask=0x3f, gameMode = 0}; -- all but enemy kills? Play around with different masks maybe.
end

for i = 0x6886, 0x68fc do
	spec.sync[i] = { kind="notzero", gameMode = 1};
end;

spec.sync[0x6987] = { kind="notzero", gameMode = 1};  --  Kraid/Ridley present byte

-- spec.sync[0x6804] = {}  -- tunic color (partner can immediately tell ring has been acquired)

return spec;