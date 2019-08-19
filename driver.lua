local z1m1Driver  = require "z1m1/diagnostics"
local z1m1Message = require "z1m1/messages"

-- ACTUAL WORK HAPPENS HERE

function memoryRead(addr, size)
	if not size or size == 1 then
		return memory.readbyte(addr)
	elseif size == 2 then
		return memory.readword(addr)
	elseif size == 4 then
		return memory.readdword(addr)
	else
		error("Invalid size to memoryRead")
	end
end

function memoryWrite(addr, value, size)
	if not size or size == 1 then
		memory.writebyte(addr, value)
	elseif size == 2 then
		memory.writeword(addr, value)
	elseif size == 4 then
		memory.writedword(addr, value)
	else
		error("Invalid size to memoryWrite")
	end
end

function recordChanged(record, value, previousValue, receiving)
	-- if driverDebug then print("record " .. tostring(record) .. " value: " .. tostring(value) ..
	-- 	" previousValue: " .. tostring(previousValue) .. " receiving: " .. tostring(receiving)) end

	local allow = true

	if type(record.kind) == "function" then
		allow, value = record.kind(value, previousValue, receiving)
	elseif record.kind == "high" then
		allow = value > previousValue
	elseif record.kind == "add" then
		if previousValue == nil then previousValue = 0 end;
		if record.toAdd == nil then record.toAdd = 0 end;

		value = previousValue + record.toAdd;
	elseif record.kind == "bitOr" then
		local maskedValue         = value                        -- Backup value and previousValue
		local maskedPreviousValue = previousValue

		if record.mask then                                      -- If necessary, mask both before checking
			maskedValue = AND(maskedValue, record.mask)
			maskedPreviousValue = AND(maskedPreviousValue, record.mask)
		end

		maskedValue = OR(maskedValue, maskedPreviousValue)

		allow = maskedValue ~= maskedPreviousValue               -- Did operated-on bits change?
		value = OR(previousValue, maskedValue)                   -- Copy operated-on bits back into value
	elseif record.kind == "passthrough" then
		allow = true
	elseif record.kind == "notzero" then
		allow = value ~= 0;
	else
		allow = value ~= previousValue;
	end

	if allow and record.cond then
		allow = performTest(record.cond, value, record.size)
	end

	return allow, value
end

--  Removed the "allow/disallow" notion from the z1m1 method
--  because we cannot guarantee that the "value" param sent to this method
--  from this client is the desired value.
function recordChangedz1m1(record, value, previousValue, receiving)
	-- if driverDebug then print("record " .. tostring(record) .. " value: " .. tostring(value) ..
	-- 	" previousValue: " .. tostring(previousValue) .. " receiving: " .. tostring(receiving)) end

	if record.kind == "add" then
		if previousValue == nil then previousValue = 0 end;
		if record.toAdd == nil then record.toAdd = 0 end;
		if record.mask == nil then record.mask = 0xff end;

		local opposingMask = 0xff - record.mask;

		--  Apply relevant mask to previous value before operation
		local maskedPrevious = AND(previousValue, record.mask);
		local toRestoreLater = AND(previousValue, opposingMask);

		if (maskedPrevious + record.toAdd) > record.mask then --prevent overflows
			value = previousValue;
		else --perform addition
			value = OR(
				AND(maskedPrevious + record.toAdd, record.mask),
				toRestoreLater	
			);
		end;

	-- elseif record.kind == "low-nybble-add" then --TODO: Broken logic
	-- 	if previousValue == nil then previousValue = 0 end;
	-- 	if record.toAdd == nil then record.toAdd = 0 end;

	-- 	local prevLowNybble = AND(previousValue, 0x0f);

	-- 	value = AND(prevLowNybble + record.toAdd, 0x0f) + AND(value, 0xf0);
	elseif record.kind == "bitOr" then
		local maskedValue         = value                        -- Backup value and previousValue
		local maskedPreviousValue = previousValue

		if record.mask then                                      -- If necessary, mask both before checking
			maskedValue = AND(maskedValue, record.mask)
			maskedPreviousValue = AND(maskedPreviousValue, record.mask)
		end

		maskedValue = OR(maskedValue, maskedPreviousValue)
		value = OR(previousValue, maskedValue)                   -- Copy operated-on bits back into value
	elseif record.kind == "copyfrom" then
		value = memoryRead(record.from);
	end

	return value;
end

function performTest(record, valueOverride, sizeOverride)
	if not record then return true end

	if record[1] == "test" then
		local value = valueOverride or memoryRead(record.addr, sizeOverride or record.size)
		return (not record.gte or value >= record.gte) and
			   (not record.lte or value <= record.lte)
	elseif record[1] == "stringtest" then
		local test = record.value
		local len = #test
		local addr = record.addr

		for i=1,len do
			if string.byte(test, i) ~= memory.readbyte(addr + i - 1) then
				return false
			end
		end
		return true
	elseif record[1] == "modulo" then
		return valueOverride % record.mod == 0
	else
		return false
	end
end

class.GameDriver(Driver)
function GameDriver:_init(spec, forceSend, ircInfo)
	self.spec = spec
	self.sleepQueue = {}
	self.forceSend = forceSend
	self.ircInfo = ircInfo;
	self.didCache = false

	-- Tracks memory locations until a settling period has elapsed, then allows further updates
	self.settlingAddresses = {}
end

function GameDriver:checkFirstRunning() -- Do first-frame bootup-- only call if isRunning()
	if not self.didCache then
		if driverDebug then print("First moment running.") end

		for k,v in pairs(self.spec.sync) do -- Enter all current values into cache so we don't send pointless 0 values later
			local value = memoryRead(k, v.size)
			if not v.cache then v.cache = value end

			if self.forceSend then -- Restoring after a crash send all values regardless of importance
				if value ~= 0 then -- FIXME: This is adequate for all current specs but maybe it will not be in future?!
					if driverDebug then print("Sending address " .. string.format("0x%02X", k) .. " at startup") end

					self:sendTable({addr=k, value=value})
				end
			end
		end

		if self.spec.startup then
			self.spec.startup(self.forceSend)
		end

		self.didCache = true
	end
end

function GameDriver:childTick()
	if self:isRunning() then
		self:checkFirstRunning()

		if #self.sleepQueue > 0 then
			local sleepQueue = self.sleepQueue
			self.sleepQueue = {}
			for i, v in ipairs(sleepQueue) do
				self:handleTable(v)
			end
		end
	end
end


function GameDriver:childWake()
	self:sendTable({"hello", version=version.release, guid=self.spec.guid});

	--  NOTE:  This is where the spec loaded by the GameDriver captures
	--  memory changes and takes action in :caughtWrite via the local callback() method above
	if self.spec.guid ~= "746cc905-ec55-418b-9098-efe01d573fd7" then
		for k,v in pairs(self.spec.sync) do
			local syncTable = self.spec.sync -- Assume sync table is not replaced at runtime
			local baseAddr = k - (k%2)       -- 16-bit aligned equivalent of address
			local size = v.size or 1

			local function callback(a,b) -- I have no idea what "b" is but snes9x passes it
				-- So, this is pretty awful: There is a bug in some versions of snes9x-rr where you if you have registered a registerwrite for an even and odd address,
				-- SOMETIMES (not always) writing to the odd address will trigger the even address's callback instead. So when we get a callback we trigger the underlying
				-- callback twice, once for each byte in the current word. This does mean caughtWrite() must tolerate spurious extra calls.
				for offset=0,1 do
					local checkAddr = baseAddr + offset
					local record = syncTable[checkAddr]
					if record then self:caughtWrite(checkAddr, b, record, size) end
				end
			end

			memory.registerwrite (k, size, callback)
		end
	else -- Initialize z1m1 game caches with disk data, if it exists

		--  TODO: dedupe this code
		--  TODO2: Big problem here.  When the game banks get swapped,
		--  all of the spec memory triggers huge numbers of callbacks as the memory is overwritten
		--  with the other game.  Either have to selectively remove and restore the callbacks during
		--  game transition, or make the map progress follow the z1m1 item paradigm for syncing instead.
		for k,v in pairs(self.spec.sync) do
			local syncTable = self.spec.sync -- Assume sync table is not replaced at runtime
			local baseAddr = k - (k%2)       -- 16-bit aligned equivalent of address
			local size = v.size or 1

			local function callback(a,b) -- I have no idea what "b" is but snes9x passes it
				-- So, this is pretty awful: There is a bug in some versions of snes9x-rr where you if you have registered a registerwrite for an even and odd address,
				-- SOMETIMES (not always) writing to the odd address will trigger the even address's callback instead. So when we get a callback we trigger the underlying
				-- callback twice, once for each byte in the current word. This does mean caughtWrite() must tolerate spurious extra calls.
				for offset=0,1 do
					local checkAddr = baseAddr + offset
					local record = syncTable[checkAddr]
					if (record ~= nil) and (z1m1Driver.IsSyncPortalDisabled() == false)
						and (record.gameMode ~= nil) then
						if record.gameMode == z1m1Driver.whichGame() then
							if z1m1Driver.InNormalGameplayMode() then
								-- if driverDebug then print("cb: " .. tostring(record.gameMode) .. ", " .. z1m1Driver.whichGame()) end
		
								self:caughtWrite(checkAddr, b, record, size);
							end;
						end;
					end
				end
			end

			memory.registerwrite (k, size, callback);
		end


		--  Load and restore disk caches, if present
		local zeldaFile = io.open("z1m1." .. self.ircInfo.nick .. ".Zelda.cache", "rb");
		local zeldaContent = nil;
		
		if zeldaFile ~= nil then
			zeldaContent = zeldaFile:read("*all")
			zeldaFile:close();
		end;

		local hyruleFile = io.open("z1m1." .. self.ircInfo.nick .. ".HyruleProgress.cache", "rb");
		local hyruleContent = nil;
		
		if hyruleFile ~= nil then
			hyruleContent = hyruleFile:read("*all")
			hyruleFile:close();
		end;

		local metroidFile = io.open("z1m1." .. self.ircInfo.nick .. ".Metroid.cache", "rb");
		local metroidContent = nil;
		
		if metroidFile ~= nil then
			metroidContent = metroidFile:read("*all")
			metroidFile:close();
		end;

		local zebesFile = io.open("z1m1." .. self.ircInfo.nick .. ".ZebesProgress.cache", "rb");
		local zebesContent = nil;
		
		if zebesFile ~= nil then
			zebesContent = zebesFile:read("*all")
			zebesFile:close();
		end;

		if zeldaContent ~= nil then
			z1m1Driver.ZeldaCache = pretty.read(zeldaContent);
			if driverDebug then print("Restored ZeldaCache: " .. tostring(z1m1Driver.ZeldaCache)) end;
		end;

		if metroidContent ~= nil then
			z1m1Driver.MetroidCache = pretty.read(metroidContent);
			if driverDebug then print("Restored MetroidCache: " .. tostring(z1m1Driver.MetroidCache)) end;
		end;

		if hyruleContent ~= nil then
			z1m1Driver.HyruleProgress = pretty.read(hyruleContent);
			if driverDebug then print("Restored HyruleProgress: " .. tostring(z1m1Driver.HyruleProgress)) end;
		end;

		if zebesContent ~= nil then
			z1m1Driver.ZebesProgress = pretty.read(zebesContent);
			if driverDebug then print("Restored ZebesProgress: " .. tostring(z1m1Driver.ZebesProgress)) end;
		end;
	end;
end

function GameDriver:isRunning()
	return performTest(self.spec.running)
end

function GameDriver:caughtWrite(addr, arg2, record, size)
	local running = self.spec.running

	if self:isRunning() then -- TODO: Yes, we got record, but double check
		self:checkFirstRunning()

		local allow = true
		local value = nil;

		if (record ~= nil) and (record.value ~= nil) then
			value = record.value;
		else
			value = memoryRead(addr, size);
		end;
		
		if record.timer then
			if value % record.cond.mod == 0 then
				self.settlingAddresses = {}
			end

			return
		end

		if record.cache then
			allow = recordChanged(record, value, record.cache, false)
		end

		--if driverDebug then print("caughtWrite() allow: " .. tostring(allow) .. " r: " .. tostring(record)) end;

		if allow and record.settle then -- ensure memory location has settled before allowing
			allow = self.settlingAddresses[addr] == nil

			if allow then
				self.settlingAddresses[addr] = value
				if driverDebug then print("Added settle to table: " .. string.format("0x%02X", addr)) end
			end
		end

		if allow then
			record.cache = value -- FIXME: Should this cache EVER be cleared? What about when a new game starts?

			self:sendTable({addr=addr, value=value})
		end
	else
		if driverDebug then print("Ignored memory write because the game is not running.") end
	end
end

function GameDriver:handleTable(t, isUnrolling)
	if t[1] == "hello" then
		if t.guid ~= self.spec.guid then
			self.pipe:abort("Partner has an incompatible .lua file for this game.")
			print("Partner's game mode file has guid:\n" .. tostring(t.guid) .. "\nbut yours has:\n" .. tostring(self.spec.guid))
		end
		return
	end

	local addr = t.addr;
	local record = self.spec.sync[addr];

	if self:isRunning() then
		self:checkFirstRunning();

		if record then
			--  If we have a gameMode property in this sync table entry, run z1m1 game detection
			if record.gameMode ~= nil then
				--  Check if item belongs to the other game mode
				if record.gameMode ~= z1m1Driver.whichGame() then
					record.addr = addr;  	 --  Include address for later syncing
					record.value = t.value;  --  Include value for later syncing

					--  Add to appropriate progress cache and exit
					if z1m1Driver.whichGame() == 0 then --in Hyrule
						if driverDebug then print("Caching Zebes room data: " .. tostring(record)) end
						table.insert(z1m1Driver.ZebesProgress, record);
						pretty.dump(z1m1Driver.ZebesProgress, "z1m1." .. self.ircInfo.nick .. ".ZebesProgress.cache")
					elseif z1m1Driver.whichGame() == 1 then --in Zebes
						if driverDebug then print("Caching Hyrule room data: " .. tostring(record)) end
						table.insert(z1m1Driver.HyruleProgress, record);
						pretty.dump(z1m1Driver.HyruleProgress, "z1m1." .. self.ircInfo.nick .. ".HyruleProgress.cache")
					end;

					return;
				end;
			end;


			local value = t.value
			local allow = true
			local previousValue = memoryRead(addr, record.size)

			allow, value = recordChanged(record, value, previousValue, true);

			-- if isUnrolling == true then
			-- 	if driverDebug then print("[a,v]: " .. tostring(allow) .. "," .. tostring(value)) end;
			-- end;

			if allow then
				if record.receiveTrigger then -- Extra setup/cleanup on receive
					record.receiveTrigger(value, previousValue)
				end

				local name = record.name
				local names = nil

				if not name and record.nameMap then
					name = record.nameMap[value]
				end

				if name then
					names = {name}
				elseif record.nameBitmap then
					names = {}
					for b=0,7 do
						if 0 ~= AND(BIT(b), value) and 0 == AND(BIT(b), previousValue) then
							table.insert(names, record.nameBitmap[b + 1])
						end
					end
				end

				if names then
					local verb = record.verb or "got"
					for i, v in ipairs(names) do
						message("Partner " .. verb .. " " .. v)
					end
				else
					if driverDebug then print("Updated anonymous address " .. string.format("0x%02X", addr) .. " to " .. string.format("0x%02X", value)) end
				end
				record.cache = value;
				memoryWrite(addr, value, record.size);
			end
		elseif (addr == 0xffff) or (addr == 0xfffe) then --magic value addresses for z1m1 item handling
			local itemid = t.itemid;
			local record = self.spec.gameItems[itemid];
			local allow = true;
			local itemValue = nil;

			--  Short circuit the wonky erroneous bomb pack when entering Zelda for now,
			--  and exit if we receive an item value not supported for syncing
			if (itemid == 0) or (record == nil) then
				return;
			end;

			--  TODO: Refactor magic boolean param
			if isUnrolling == nil then --normal item get; print message
				local location = 0;

				if     addr == 0xfffe then location = 0
				elseif addr == 0xffff then location = 1 end;

				z1m1Message.print(self.ircInfo.partner, record.desc, location);
			end;

			--  Check if item belongs to the other game mode
			if record.game ~= z1m1Driver.whichGame() then
				--  Add to appropriate game cache and exit
				if z1m1Driver.whichGame() == 0 then --in Hyrule
					if driverDebug then print("Caching Zebes item: " .. tostring(itemid)) end
					table.insert(z1m1Driver.MetroidCache, itemid);
					pretty.dump(z1m1Driver.MetroidCache, "z1m1." .. self.ircInfo.nick .. ".Metroid.cache")
				elseif z1m1Driver.whichGame() == 1 then --in Zebes
					if driverDebug then print("Caching Hyrule item: " .. tostring(itemid)) end
					table.insert(z1m1Driver.ZeldaCache, itemid);
					pretty.dump(z1m1Driver.ZeldaCache, "z1m1." .. self.ircInfo.nick .. ".Zelda.cache")
				end;

				return;
			end;


			--  Loop through initial item directives as well as any "more" attributes until no more exist
			local action = record;

			while action ~= nil do
				--  Choose which value to send to recordChangecz1m1().
				--  Begin with the memory value as sent in the table, but override
				--  with a specific value if this item has one
				local newValue      = t.value;
				local previousValue = memoryRead(action.addr);

				if action.value ~= nil then newValue = action.value end;

				local itemValue = recordChangedz1m1(action, newValue, previousValue, true);

				if driverDebug then print("Updating [" .. string.format("0x%02X", action.addr) .. "] to " .. string.format("0x%02X", itemValue)) end

				if itemValue ~= nil then
					memoryWrite(action.addr, itemValue);
				else
					if driverDebug then print("itemValue not defined in item-table.") end;
				end;

				action = action.more;
			end;
		else
			if driverDebug then print("Unknown memory address [" .. string.format("0x%02X", addr) .. "]") end;
			message("Partner changed unknown memory address.")
		end
	else
		if driverDebug then print("Queueing partner memory write because the game is not running.") end
		table.insert(self.sleepQueue, t)
	end
end

function GameDriver:handleError(s, err)
	print("FAILED TABLE LOAD " .. err)
end
