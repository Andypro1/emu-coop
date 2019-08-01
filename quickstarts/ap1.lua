--  Edit the following configuration object to configure this quickstart file
local data = {
	specGuid = "746cc905-ec55-418b-9098-efe01d573fd7",
	server   = "andypro.noip.me",
	port     = 6667,
	nick     = "Andypro1",
	partner  = "Andypro2"
};

--  Edit the following if you want to see diagnostic output from the network library
--  or from the coop driver script
pipeDebug = false
driverDebug = true

package.path = "../?.lua;" .. package.path;

class   = require "pl.class"
pretty  = require "pl.pretty"
List    = require "pl.list"
stringx = require "pl.stringx"
tablex  = require "pl.tablex"

require "version"
require "util"

require "modes.index"
require "dialog"
require "pipe"
require "driver"

if emu.emulating() then
	local spec = nil -- Mode specification
	
	--  Select the approprate coop mode from the quickstart specGuid
	for i,v in ipairs(modes) do
		if v.guid == data.specGuid then
			spec = v;
		end
	end

	if spec then
		print("Playing " .. spec.name);

		local failed = false;

		function scrub(invalid) errorMessage(invalid .. " not valid") failed = true end;

		if failed then -- NOTHING
		elseif not nonempty(data.server) then scrub("Server")
		elseif not nonzero(data.port) then scrub("Port")
		elseif not nonempty(data.nick) then scrub("Nick")
		elseif not nonempty(data.partner) then scrub("Partner nick")
		end;

		--  Remove illegal whitespace characters from NICKs (fixes FCEUX dialog UI tabbing bug)
		data.nick = data.nick:gsub("%s+", "");
		data.partner = data.partner:gsub("%s+", "");
		
		function connect()
			local socket = require "socket";
			local server = socket.tcp();
			result, err = server:connect(data.server, data.port);

			if not result then errorMessage("Could not connect to IRC: " .. err) failed = true return end;

			statusMessage("Connecting to server...");

			mainDriver = GameDriver(spec, data.forceSend, data); -- Notice: This is a global, specs can use it
			IrcPipe(data, mainDriver):wake(server);
		end

		if not failed then connect() end;

		if failed then gui.register(printMessage) end;
	end;
else
	errorMessage("Cannot run", "No ROM is running.");
end;
