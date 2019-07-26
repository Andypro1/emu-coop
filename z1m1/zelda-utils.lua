local itemTable = require "z1m1/item-table"

---- configuration

local second_quest = false
local host = nil
local config = nil
local show_item_classes = ""
local zelda_level = nil
local zelda_room = nil
local ganon_room = nil
local use_effects = false

---- state

local mode1 = nil;
local mode2 = nil;
local game_state = nil
local game_state_addr = 0x0650
local game_state_size = 0x01B0


local player = {}
local status = {}

local old_fanfare = nil
local got_item_pos = nil
local picked_up = false


-- collected equipment

player.equips = {}

player.equips.sword = {false, false, false}
player.equips.candle = {false, false}
player.equips.arrows = {false, false}
player.equips.ring = {false, false}
player.equips.boom = {false, false}

player.equips.recorder = {false}
player.equips.bow = {false}
player.equips.magickey = {false}
player.equips.raft = {false}
player.equips.ladder = {false}
player.equips.rod = {false}
player.equips.book = {false}
player.equips.bracelet = {false}

-- current inventory

player.inv = {}

player.inv.sword = 0
player.inv.recorder = 0
player.inv.candle = 0
player.inv.arrows = 0
player.inv.bow = 0
player.inv.magickey = 0
player.inv.raft = 0
player.inv.ladder = 0
player.inv.rod = 0
player.inv.book = 0
player.inv.ring = 0
player.inv.bracelet = 0
player.inv.boom = 0

player.inv.max_hearts = 3
player.inv.max_bombs = 8

player.inv.triforces = {}
player.inv.triforces[1] = false
player.inv.triforces[2] = false
player.inv.triforces[3] = false
player.inv.triforces[4] = false
player.inv.triforces[5] = false
player.inv.triforces[6] = false
player.inv.triforces[7] = false
player.inv.triforces[8] = false

player.triforce_count = 0

player.inv.compasses = {}

player.inv.compasses[1] = false
player.inv.compasses[2] = false
player.inv.compasses[3] = false
player.inv.compasses[4] = false
player.inv.compasses[5] = false
player.inv.compasses[6] = false
player.inv.compasses[7] = false
player.inv.compasses[8] = false
player.inv.compasses[9] = false

player.inv.maps = {}

player.inv.maps[1] = false
player.inv.maps[2] = false
player.inv.maps[3] = false
player.inv.maps[4] = false
player.inv.maps[5] = false
player.inv.maps[6] = false
player.inv.maps[7] = false
player.inv.maps[8] = false
player.inv.maps[9] = false

player.stat = {}

player.stat.subhearts = 0x02FF
player.stat.bombs = 0
player.stat.keys = 0
player.stat.money = 0

player.stat.bait = 0
player.stat.shield = 0
player.stat.letter = 0
player.stat.potion = 0

---- variables

local is_active = false
local should_restore_game_state = false
local should_restore_inventory = false
local should_restore_status = false
local should_write_info = true
local should_write_hash = true
local did_write_stats = false
local did_start_credits = false
local money_tgt = nil

local room_item = nil
local cave_items = {}
cave_items[1] = nil
cave_items[2] = nil
cave_items[3] = nil

local cur_room_info = nil

local overworld_room = 0xFF

local old_level
local old_triforce
local old_loc_type = 0;
local old_map_coord = 0;
local old_cave_mode
local old_item_num
local old_item_vis
local old_item_x
local old_item_y

local bubble_chaos_ctr = 0

local other_dungeon_item
local triforces_added = false
local triforces_removed = false

local room_item_display = "--"    -- used for debugging

local must_draw_exits = true
local hide_map_markers = true

local counted_death = false
local can_continue = true

local function get_picked_up_cave_item()
	local temp = got_item_pos
	got_item_pos = nil
	return temp
end

local function read_player_status()

	local hearts_hi = (memory.readbyte(0x066F) % 16)
	local hearts_lo = memory.readbyte(0x0670)
	status.subhearts = 256 *hearts_hi + hearts_lo
	status.bombs = memory.readbyte(0x0658)
	status.keys = memory.readbyte(0x066E)
	status.money = memory.readbyte(0x066D)
	status.bait = memory.readbyte(0x065D)
	status.shield = memory.readbyte(0x0676)
	status.letter = memory.readbyte(0x0666)
	status.potion = memory.readbyte(0x065E)

	return status

end

local function read_game_state()

	local game_state = {}

	for a=game_state_addr,(game_state_addr+game_state_size-1) do
		game_state[a] = memory.readbyte(a)
	end

	return game_state

end

local function get_mode_info()
	return { mode1 = memory.readbyte(0x0011), mode2 = memory.readbyte(0x0012) };
end

local function convert_q2_level_num(b)

	if (b == 1) then return 1 end
	if (b == 2) then return 3 end
	if (b == 3) then return 2 end
	if (b == 4) then return 5 end
	if (b == 5) then return 4 end
	if (b == 6) then return 6 end
	if (b == 7) then return 8 end
	if (b == 8) then return 7 end

	return b

end

local function get_cur_level()

	local q = memory.readbyte(0x062D)
	local b = memory.readbyte(0x0010)

	if (q == 1) then
		b = convert_q2_level_num(b)
	end

	return b

end

local function analyze_room(cur_level, cur_map_coord, cur_loc_type, cur_item_vis)
	-- if((memory.readbyte(0x0422) < 0x5f) or (memory.readbyte(0x0423) < 0x5f) or (memory.readbyte(0x0424) < 0x5f)) then
    --     emu.message("Set room items " .. string.format("0x%x", memory.readbyte(0x0422)) .. " " .. string.format("0x%x", memory.readbyte(0x0423)) .. " " .. string.format("0x%x", memory.readbyte(0x0424)));
	-- end;

	if(memory.readbyte(0x0422) < 0x5f) then
		cave_items[1] = memory.readbyte(0x0422)
	end;

	if(memory.readbyte(0x0423) < 0x5f) then
		cave_items[2] = memory.readbyte(0x0423)
	end;

	if(memory.readbyte(0x0424) < 0x5f) then
		cave_items[3] = memory.readbyte(0x0424)
	end;
end


local function cave_client_process(menued)
	local link_x       = memory.readbyte(0x0070)
	local link_y       = memory.readbyte(0x0084)
	local new_fanfare  = memory.readbyte(0x0506)
	local link_at_pos = nil

	for i=0,2 do
		local x0 = 0x50 + 0x20 * i
		local x1 = 0x60 + 0x20 * i

		if (x0 < link_x and link_x < x1 and link_y < 0xA5) then
            link_at_pos = i
        end
	end

	-- pick up?
	if (link_at_pos ~= nil) then
        if (old_fanfare == 0x00 and new_fanfare > 0x00) then
			got_item_pos = link_at_pos
			picked_up = true
		end
	end

	old_fanfare = new_fanfare
end


local function process_playing(itemsToSync)

	local in_cave = false
	local cur_level = get_cur_level()
	local paused = memory.readbyte(0x00E0) == 1
	local in_ganon_room = false
	local item_got
	local slot_hit
	local cur_cave_mode
    local cur_map_coord;
    local cur_loc_type;
    local cur_triforce;

	local menued
	local playing

	local menu_byte = memory.readbyte(0x00E1)

    local mi = get_mode_info();

    mode1 = mi.mode1;
    mode2 = mi.mode2;

    --gui.text(20, 20, "mode1: " .. mode1 .. " mode2: " .. mode2);

    if(mode1 == 0x01 and mode2 == 0x05) then
        cur_map_coord = memory.readbyte(0x00EB)
        cur_loc_type = 0;
        cur_triforce = false;
    elseif(mode1 == 0x00 and mode2 == 0x11) then
        cur_map_coord = old_map_coord;
        cur_loc_type = old_loc_type;
        cur_triforce = false;
    elseif(mode1 == 0x01 and (mode2 == 0x0b or mode2 == 0x0c)) then
        -- overworld cave
        cur_map_coord = memory.readbyte(0x00EB)
        cur_loc_type = 1;
        cur_triforce = false;
    elseif(mode1 == 0x01 and mode2 == 0x09) then
        -- dungeon basement
        cur_map_coord = memory.readbyte(0x00EC)
        cur_loc_type = 1;
        cur_triforce = false;
    elseif(mode1 == 0x01 and mode2 == 0x12) then
        cur_map_coord = old_map_coord;
        cur_loc_type = old_loc_type;
        cur_triforce = true;
    else
		-- Instead of analyzing an invalid state, just return
		return;
    end;

	if (cur_level == 0) then
		menued = menu_byte == 8
		playing = menu_byte == 0
	else
		menued = menu_byte == 7
		playing = menu_byte == 0
	end

	local cur_item_num = memory.readbyte(0xAB)
	local cur_item_vis = memory.readbyte(0xBF) == 0x00
	local cur_item_x   = memory.readbyte(0x83)
	local cur_item_y   = memory.readbyte(0x97)

	local link_x = memory.readbyte(0x70)
	local link_y = memory.readbyte(0x84)

    -- gui.text(100, 10, "cur_map_coord: " .. cur_map_coord);
    --gui.text(10, 20, "link_x: " .. link_x .. " link_y: " .. link_y);

	local link_map_x = cur_map_coord % 16
	local link_map_y = math.floor(cur_map_coord / 16)

	-- overworld specific
	if (cur_level == 0) then
		-- overworld room ...
		if (cur_loc_type == 0) then

			overworld_room = cur_map_coord

			-- -- restore triforces?
			-- if (triforces_removed or triforces_added) then

			-- 	core_client.write_player_inventory(player.inv)
			-- 	triforces_removed = false
			-- 	triforces_added = false
			-- end
		end

		-- overworld cave ...
		if (cur_loc_type == 1) then
			in_cave = true
			cur_cave_mode = memory.readbyte(0x0413) % 0x10
		end
	end

	-- analyze room for items

	local item_appeared = cur_item_vis == true and old_item_vis == false

	if (
		old_loc_type ~= cur_loc_type or 
		old_map_coord ~= cur_map_coord or 
		old_cave_mode ~= cur_cave_mode or
		old_item_num ~= cur_item_num or
		item_appeared
		) then

		analyze_room(cur_level, cur_map_coord, cur_loc_type, cur_item_vis)

		-- get latest internal game state
		game_state = read_game_state()
	end

	-- process room/cave after analyze
    if (in_cave) then
		cave_client_process(playing == false, false)
	end

	-- check for pickups
    if (old_map_coord == cur_map_coord and old_loc_type == cur_loc_type) then
		local item_disappeared = cur_item_vis == false and old_item_vis == true

		-- local cur_item_num = memory.readbyte(0xAB)
		-- local cur_item_vis = memory.readbyte(0xBF) == 0x00
		-- local cur_item_x   = memory.readbyte(0x83)
		-- local cur_item_y   = memory.readbyte(0x97)
		-- gui.text(10, 10, string.format("0x%x", memory.readbyte(0xAB)) .. " " .. string.format("0x%x", memory.readbyte(0xBF)) .. " " .. string.format("0x%x", memory.readbyte(0x83)) .. " " .. string.format("0x%x", memory.readbyte(0x97)));

		if ((item_disappeared or (cur_item_y == 0xFF and old_item_y < 0xFF) or
			(cur_triforce == true and old_triforce == false))
			and cur_item_num < 0x60) then
            --emu.message("Got room item: " .. string.format("0x%x", cur_item_num) .. " " .. string.format("%s", tostring(item_disappeared)) .. " " .. cur_item_y .. " " .. old_item_y);
			--emu.message("Got room item: " .. string.format("0x%x", cur_item_num));
			item_got = cur_item_num
			other_dungeon_item = false
        else
            local got_cave_item = get_picked_up_cave_item()

            if (got_cave_item ~= nil) then
                --emu.message("Got item: 0x" .. string.format("%x", cave_items[got_cave_item+1]));
				--emu.message(string.format("I procured %s from %s", cave_items[got_cave_item+1], "Hyrule"));
				item_got = cave_items[got_cave_item+1]
			end
		end
	end

	--item obtained?
	if (item_got ~= nil) then
		--emu.message("I got " .. itemTable.items[item_got].desc);
		table.insert(itemsToSync, item_got);
		--emu.message(tostring(itemsToSync));
        --emu.message("Got item " .. string.format("0x%x", item_got));
		-- host.global_item_obtained(item_got)

		-- if (cur_room_info.type == "CI") then
		-- 	-- this is a "take any" cave
		-- 	-- mark both item as obtained
		-- 	host.mark_item_as_obtained(cave_items[1])
		-- 	host.mark_item_as_obtained(cave_items[3])
		-- end

		-- if (cur_level > 0) then

		-- 	--room_client.handle_dungeon_pickup(cur_loc_type == 1)

		-- 	if (cur_triforce) then
		-- 		-- we need to mark this room as "all enemies killed"
		-- 		core_client.change_room_flag(0xC0, true)
		-- 	end

		-- end

		-- update hud accordingly

		-- local items_here = count_items_for_room(cur_level, cur_map_coord, 0) + count_items_for_room(cur_level, cur_map_coord, 1)
		-- hud.set_item_dot(cur_level, link_map_y, link_map_x, items_here > 0)

		-- local goals_here = count_goals_for_room(cur_level, cur_map_coord, 0) + count_goals_for_room(cur_level, cur_map_coord, 1)
		-- hud.set_goal_dot(cur_level, link_map_y, link_map_x, goals_here > 0, 1)

		item_got = nil
	else
		player.stat = read_player_status()
	end

	-- store current values as old values

	old_level     = cur_level
	old_triforce  = cur_triforce
	old_loc_type  = cur_loc_type
	old_map_coord = cur_map_coord
	old_cave_mode = cur_cave_mode
	old_item_num  = cur_item_num
	old_item_vis  = cur_item_vis
	old_item_y    = cur_item_y
	old_item_x    = cur_item_x

	counted_death = false
end;


return {
	process_game = process_playing
}