local itemTable = require "z1m1/item-table"

local samus = {}
local map = {}
local curItem = nil;

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

local function analyze_room(area, room_y, room_x)
	local room_key = area .. string.format("%02X", room_y) .. string.format("%02X", room_x)

    local room_info = { item, item_x, item_y };

    if (room_info.item == nil) then
        room_info.item = memory.readbyte(0x0748);
    end

	if (room_info ~= nil) then
		if (room_info.item_y == nil) then
			room_info.item_y = memory.readbyte(0x0749)
		end

		if (room_info.item_x == nil) then
			room_info.item_x = memory.readbyte(0x074A)
		end

		--set_room_item(room_y, room_x, room_info.item, room_info.item_y, room_info.item_x)
		--emu.message("room item found:" .. room_info.item);
		if(room_info.item ~= 0xff) then
			curItem = room_info.item;
		end;
	end
end

local function process_game(itemsToSync)
	local load_room_y  = memory.readbyte(0x004F)
	local load_room_x  = memory.readbyte(0x0050)
	local door_status  = memory.readbyte(0x0056)
	local samus        = read_samus_state()

	-- read secondary mode byte
	local mode2 = memory.readbyte(0x001E)

	-- 0x08 -> starting / fading in 
	if (mode2 == 0x08) then

		last_samus_room_x = nil
		last_samus_room_y = nil

		--restore_state_vars()

		--shortcut fade-in?
		local joystate = joypad.read(1)
		if (joystate.A == true or joystate.B == true) then
			memory.writebyte(0x002C, 0x01)
		end

		-- ensure no items are on the screen
		memory.writebyte(0x0748, 0xFF)
		memory.writebyte(0x0750, 0xFF)

		just_spawned = true

	end

	-- 0x03 -> normal play mode
	if (mode2 == 0x03) then

		local new_room_loaded = false
		local area_num = memory.readbyte(0x0074) % 0x10
		local exit_room = false
		local hide_items = false

		--restore_state_vars()

		if (just_spawned) then
			--apply_palette()
			just_spawned = false
		end
 
		-- new room loaded?
		if (load_room_x ~= last_room_x or load_room_y ~= last_room_y) then

			-- removes drop limits for the room
			memory.writebyte(0x93, 0xFF)
			memory.writebyte(0x94, 0xFF)
			memory.writebyte(0x95, 0x00)
			memory.writebyte(0x96, 0x00)


			if (load_room_y == 0x1D) then

				-- this row contains kraid and ridley

				if (flags.killed_kraid == true) then
					memory.writebyte(0x687B, 0x01)
				else
					memory.writebyte(0x687B, 0x00)
				end

				if (flags.killed_ridley == true) then
					memory.writebyte(0x687C, 0x01)
				else
					memory.writebyte(0x687C, 0x00)
				end

			end

			prev_room_x = last_room_x
			prev_room_y = last_room_y

			last_room_x = load_room_x
			last_room_y = load_room_y

			new_room_loaded = true

		end

		-- samus moved to a new room?
		if (samus.room_y ~= last_samus_room_y or samus.room_x ~= last_samus_room_x) then

			local index = 32*samus.room_y+samus.room_x

			local n = map[ index ]

			--8x = open on left
			--4x = open on right
			--2x = open on top
			--1x = open on bottom

			if (n == nil) then
				n = area_num
			end

			if (last_samus_room_x ~= nil and last_samus_room_y ~= nil) then
				if (samus.room_x > last_samus_room_x) then n = OR(n, 0x80) end
				if (samus.room_x < last_samus_room_x) then n = OR(n, 0x40) end
				if (samus.room_y > last_samus_room_y) then n = OR(n, 0x20) end
				if (samus.room_y < last_samus_room_y) then n = OR(n, 0x10) end
			end

			-- update map
			map[ index ] = n

			last_samus_room_x = samus.room_x
			last_samus_room_y = samus.room_y

		end


		-- need to analyze the room (for item slots)?

		if (new_room_loaded) then

			handled_pickup = false

			analyze_room(samus.area, load_room_y, load_room_x)

			-- save internal game state

			game_state = read_game_state()

		end

		-- tourian specific logic

		if (area_num == 0x03) then

			if (samus.room_y == 0x0B) then

				-- do mother brain enhancements

				ai_brain.process()

				-- disable cannons in mother brain room

				if (config["disable_cannons"] == true) then

					memory.writebyte(0x0465, 0x00)
					memory.writebyte(0x0475, 0x00)
					memory.writebyte(0x0485, 0x00)
					memory.writebyte(0x0495, 0x00)

				end

			end

			-- check if samus is in exit room

			if (samus.room_y == 0x03 and samus.room_x == escape_room_x) then

				-- is samus on elevator?
				if (memory.readbyte(0x0307) == 1) then

					if (flags["finished_tourian"] == false) then
						raise_event("game_complete")
						flags["finished_tourian"] = true
					end

					-- check for exit condition
					if (samus.ypos < 0x10 ) then

						if (flags["roll_credits"] == false) then

							game_state = core_client.read_game_state()

							-- update exit count
							stats.exits = stats.exits + 1

							-- tell core that we've hit an exit
							host.exit_reached("metroid", "tourian_exit")

							-- update host with latest stats
							host.set_global_value("metroid.stats", stats)

							is_active = false

							-- all done -- exit!
							return

						end

					end

				end

			end

		end

		-- are we in a door

		if (door_status > 0x00) then

			-- in right door
			if (door_status == 0x01 and memory.readbyte(0xFD) < 128) then
				hide_items = true
			end

			-- in left door
			if (door_status == 0x02 and memory.readbyte(0xFD) > 128) then
				hide_items = true
			end

		end

		-- hiding items during part of door transition because of item weirdness

		if (hide_items == true) then
			memory.writebyte(0x0748, 0xFF)
			memory.writebyte(0x0750, 0xFF)
		end

		-- check for boss rooms

		if (samus.room_y == 0x1D) then

			if (area_num == 2 and memory.readbyte(0x6B02) == 0x08) then

				-- we are in kraid's room

				if (flags.killed_kraid == false) then

					-- perform augmented ai for kraid
					ai_kraid.process()

					-- lock the item in kraid's room until he is dead
					if (config["mirrored"]) then
						memory.writebyte(0x62C2, 0x04)
						memory.writebyte(0x62C3, 0x05)
						memory.writebyte(0x62E2, 0x06)
						memory.writebyte(0x62E3, 0x07)
					else
						memory.writebyte(0x62DC, 0x04)
						memory.writebyte(0x62DD, 0x05)
						memory.writebyte(0x62FC, 0x06)
						memory.writebyte(0x62FD, 0x07)
					end

					-- check for kraid's death
					if (memory.readbyte(0x687B) > 0x00) then
						player.inv.missile_cap = player.inv.missile_cap + 75
						memory.writebyte(0x687A, player.inv.missile_cap)
						flags.killed_kraid = true
					end

				else

					-- unlock the item in kraid's room
					if (config["mirrored"]) then
						if (memory.readbyte(0x62C2) == 0x04) then
							memory.writebyte(0x62C2, 0x70)
							memory.writebyte(0x62C3, 0x71)
							memory.writebyte(0x62E2, 0x72)
							memory.writebyte(0x62E3, 0x73)
						end
					else
						if (memory.readbyte(0x62DC) == 0x04) then
							memory.writebyte(0x62DC, 0x70)
							memory.writebyte(0x62DD, 0x71)
							memory.writebyte(0x62FC, 0x72)
							memory.writebyte(0x62FD, 0x73)
						end
					end

				end

			end

			if (area_num == 4 and memory.readbyte(0x6B02) == 0x09) then

				-- we are in ridley's room

				if (flags.killed_ridley == false) then

					-- perform augmented ai for ridley
					ai_ridley.process()

					-- locks the door behind ridley until he is dead
					if (config["mirrored"]) then
						memory.writebyte(0x03AF, 0x0A)
					else
						memory.writebyte(0x03BF, 0x0A)
					end

					-- check for ridley death
					if (memory.readbyte(0x687C) > 0x00) then
						player.inv.missile_cap = player.inv.missile_cap + 75
						memory.writebyte(0x687A, player.inv.missile_cap)
						flags.killed_ridley = true
					end

				end

			end

		end


		-- get coords of item near samus

		if (memory.readbyte(0x0748) ~= 0xFF and memory.readbyte(0x074B) == samus.table) then
			item_y = memory.readbyte(0x0749)
			item_x = memory.readbyte(0x074A)

		elseif (memory.readbyte(0x0750) ~= 0xFF and memory.readbyte(0x0753) == samus.table) then
			item_y = memory.readbyte(0x0751)
			item_x = memory.readbyte(0x0752)

		end

		--core_client.process()

	end

	-- 0x09 -> picking up item
	if (mode2 == 0x09 and samus.mode < 0x07) then

		if (handled_pickup == false) then

			local room_key = samus.area .. string.format("%02X", samus.room_y) .. string.format("%02X", samus.room_x)

			--local room = config.rooms[room_key]
            local room = { item, item_x, item_y };

            -- if (room.item == nil) then
            --     room.item = memory.readbyte(0x0748);
            -- end

			--if (room ~= nil) then

				local dist_y = math.abs(samus.ypos - item_y)
				local dist_x = math.abs(samus.xpos - item_x)

				-- are we actually close to an item?
				if (dist_y < 24 and dist_x < 16) then

					-- tell core we got the item
					--host.global_item_obtained(room.item)
                    emu.message(string.format("I procured %s from %s", itemTable.items[curItem], "Zebes"));
					table.insert(itemsToSync, itemTable.items[curItem]);

					should_restore_inventory = true

					handled_pickup = true

					-- remove item from screen
					--room_client.set_no_room_item(samus.room_y, samus.room_x)

					-- clear dots on the map
					--hud.set_item_dot(samus.room_y, samus.room_x, false)
					--hud.set_goal_dot(samus.room_y, samus.room_x, false)

					--apply_palette()

				end

			--end

		end

		--shortcut fanfare?
		local inputs = memory.readbyte(0x0012)
		if (AND(inputs, 0x80) == 0x80 or AND(inputs, 0x40) == 0x40) then
			memory.writebyte(0x002C, 0x01)
		end

		--core_client.process()

	end

	--room_client.process()

	local paused = memory.readbyte(0x0031) == 1
	if (paused == true or pause_for_map == false) then
		--hud.process(paused, samus.room_x, samus.room_y)
	end

	counted_death = false

	if (use_effects) then

		process_effect_pool("good")
		process_effect_pool("evil")

	end

end



return {
	process_game = process_game
}
