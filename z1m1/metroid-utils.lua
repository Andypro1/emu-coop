local itemTable = require "z1m1/item-table"

local samus = {}
local map = {}
local curItem = nil;

local item_y = nil;
local item_x = nil;
local handled_pickup = false;
local bossJustKilled = false;

local areas = {}
areas[0] = "B"
areas[1] = "N"
areas[2] = "K"
areas[3] = "T"
areas[4] = "R"

local game_state_addr = 0x6800
local game_state_size = 0x0100

local function read_game_state()
	local game_state = {}

	for a=game_state_addr,(game_state_addr+game_state_size-1) do
		game_state[a] = memory.readbyte(a)
	end

	return game_state
end

local function get_samus_rx()
	local room_x = memory.readbyte(0x0050)
	local scroll_dir = memory.readbyte(0x0049)
	local scroll_x = memory.readbyte(0x00FD)
	local ssx = memory.readbyte(0x0051)

	if (scroll_dir == 3 and scroll_x ~= 0) then 
		room_x = room_x - 1
	end

	return math.floor(room_x + (scroll_x + ssx) / 256)
end

local function get_samus_ry()
	local room_y = memory.readbyte(0x004F)
	local scroll_dir = memory.readbyte(0x0049)
	local scroll_y = memory.readbyte(0x00FC)
	local ssy = memory.readbyte(0x0052)

	if (scroll_dir == 1 and scroll_y ~= 0) then 
		room_y = room_y - 1
	end

	return math.floor(room_y + (scroll_y + ssy) / 240)
end

local function read_samus_state()
	samus.area   = areas[ memory.readbyte(0x0074) % 0x10 ]
	samus.room_y = get_samus_ry()
	samus.room_x = get_samus_rx()

	samus.mode   = memory.readbyte(0x0300) --  samus mode byte
	samus.table  = memory.readbyte(0x030C) --  samus nametable flag
	samus.ypos   = memory.readbyte(0x030D)  -- y position of samus within room
	samus.xpos   = memory.readbyte(0x030E)  -- x position of samus within room

	return samus
end

-- local function analyze_room(area, room_y, room_x)
-- 	if (memory.readbyte(0x0748) ~= 0xff) and (memory.readbyte(0x074B) == samus.table) then
-- 		message("found item 1.");
-- 		curItem = memory.readbyte(0x0748);
-- 	elseif (memory.readbyte(0x0750) ~= 0xff) and (memory.readbyte(0x0753) == samus.table) then
-- 		message("found item 2.");
-- 		curItem = memory.readbyte(0x0750);
-- 	else
-- 		curItem = nil;
-- 	end;
-- end;

local function process_game(itemsToSync)
	local load_room_y  = memory.readbyte(0x004F)
	local load_room_x  = memory.readbyte(0x0050)
	local door_status  = memory.readbyte(0x0056)
	local samus        = read_samus_state()
	local inNormalPlay = false;

	-- read secondary mode byte
	local mode2 = memory.readbyte(0x001E)

	if mode2 == 0x05 then
		inNormalPlay = false;
	end;

	-- 0x08 -> starting / fading in 
	if (mode2 == 0x08) then
		last_samus_room_x = nil
		last_samus_room_y = nil

		just_spawned = true;
		inNormalPlay = false;
	end

	-- 0x03 -> normal play mode
	if (mode2 == 0x03) then
		local new_room_loaded = false;
		handled_pickup = false;  --  Set this to false in normal gameplay to prepare
								 --  for the next item pickup state
		local area_num = memory.readbyte(0x0074) % 0x10
		local exit_room = false
		local hide_items = false


		if (just_spawned) then
			just_spawned = false
		end
 
		-- new room loaded?
		if (load_room_x ~= last_room_x or load_room_y ~= last_room_y) then
			prev_room_x = last_room_x
			prev_room_y = last_room_y

			last_room_x = load_room_x
			last_room_y = load_room_y

			new_room_loaded = true
		end

		-- samus moved to a new room?
		if (samus.room_y ~= last_samus_room_y or samus.room_x ~= last_samus_room_x) then
			-- local index = 32*samus.room_y+samus.room_x
			-- local n = map[ index ]

			-- --8x = open on left
			-- --4x = open on right
			-- --2x = open on top
			-- --1x = open on bottom

			-- if (n == nil) then
			-- 	n = area_num
			-- end

			-- if (last_samus_room_x ~= nil and last_samus_room_y ~= nil) then
			-- 	if (samus.room_x > last_samus_room_x) then n = OR(n, 0x80) end
			-- 	if (samus.room_x < last_samus_room_x) then n = OR(n, 0x40) end
			-- 	if (samus.room_y > last_samus_room_y) then n = OR(n, 0x20) end
			-- 	if (samus.room_y < last_samus_room_y) then n = OR(n, 0x10) end
			-- end

			-- -- update map
			-- map[ index ] = n

			last_samus_room_x = samus.room_x
			last_samus_room_y = samus.room_y
		end

		-- need to analyze the room (for item slots)?
		if (new_room_loaded) then
			bossJustKilled = false;

			--analyze_room(samus.area, load_room_y, load_room_x)

			-- save internal game state
			game_state = read_game_state()
		end

		-- -- are we in a door
		-- if (door_status > 0x00) then
		-- 	-- in right door
		-- 	if (door_status == 0x01 and memory.readbyte(0xFD) < 128) then
		-- 		hide_items = true
		-- 	end

		-- 	-- in left door
		-- 	if (door_status == 0x02 and memory.readbyte(0xFD) > 128) then
		-- 		hide_items = true
		-- 	end
		-- end

		if (samus.room_y == 0x1D) and (bossJustKilled == false) then
			if (area_num == 2 and memory.readbyte(0x6B02) == 0x08) then
				--  Kraid's room

				if (AND(memory.readbyte(0x687B), 0x0f) > 0x00) then --Kraid just killed
					if driverDebug then print("Bye Kraid.") end

					--  Boss room missile pickup
					table.insert(itemsToSync, 0x5d);
					bossJustKilled = true;
				end;
			elseif (area_num == 4 and memory.readbyte(0x6B02) == 0x09) then
				--  Ridley's room

				if (AND(memory.readbyte(0x687C), 0x0f) > 0x00) then --Ridley just killed
					if driverDebug then print("Bye Ridley.") end
					
					--  Boss room missile pickup
					table.insert(itemsToSync, 0x5e);
					bossJustKilled = true;
				end;
			end;
		end;

		-- get coords of item near samus
		if (memory.readbyte(0x0748) ~= 0xFF and memory.readbyte(0x074B) == samus.table) then
			item_y = memory.readbyte(0x0749);
			item_x = memory.readbyte(0x074A);
			curItem = memory.readbyte(0x0748);
		elseif (memory.readbyte(0x0750) ~= 0xFF and memory.readbyte(0x0753) == samus.table) then
			item_y = memory.readbyte(0x0751);
			item_x = memory.readbyte(0x0752);
			curItem = memory.readbyte(0x0750);
		else
			item_y = 0;
			item_x = 0;
			curItem = nil;
		end

		inNormalPlay = true;
	end

	-- 0x09 -> picking up item
	if (mode2 == 0x09 and samus.mode < 0x07) then
		if (item_x ~= nil) and (item_y ~= nil) and (curItem ~= nil) and (handled_pickup == false) then
			local dist_y = math.abs(samus.ypos - item_y)
			local dist_x = math.abs(samus.xpos - item_x)

			--if driverDebug then print(dist_y .. ", " .. dist_x) end

			-- are we actually close to an item?
			if (dist_y < 24 and dist_x < 16) then
				table.insert(itemsToSync, curItem);

				should_restore_inventory = true
				handled_pickup           = true
			end;
		end;

		inNormalPlay = true;
	end;

	counted_death = false;

	return inNormalPlay;
end


return {
	process_game = process_game
};