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

-- --  Settle "engine" to prevent flood timeouts on those items which can change rapidly
-- spec.sync[0x0015] = {timer=1, cond={"modulo", mod = 30}}

-- spec.sync[0x066D] = {settle=1} -- Rupees
-- spec.sync[0x066E] = {name="a key"}  -- Keys

-- --  Bombs
-- spec.sync[0x0658] = {}
-- spec.sync[0x067C] = {name="Bomb upgrade", kind="high"}

-- --  Hearts
-- spec.sync[0x0670] = {settle=1}  --  Fractional health
-- spec.sync[0x066F] = {}  --  Int health and heart containers
-- spec.sync[0x0012] = {cond={"test", gte = 0x11, lte = 0x11}, kind="passthrough"}  --  death

-- spec.sync[0x6804] = {}  -- tunic color (partner can immediately tell ring has been acquired)

return spec
