--lua 5.3

local component = require "component";
local thread = require("thread")
local event = require "event";

local multiserver = {serverStarted = false};
local slaves = {};
local serverPort = 0;

function hasValue(arr, value)
	flag = false;
	for i, v in ipairs(arr) do
		if v == value then
			flag = true;
			break;
		end
	end

	return flag;
end

function log(message, from)
    print("["..from.."] : "..message);
end

function multiserver.enableListeningToSlaves()
	while true do
		local _, _, from, _, _, message = event.pull(1, "modem_message");
		if hasValue(slaves, from) then
			log(message, "slave-"..from);
		end
	end
end

function multiserver.start(port)
	serverPort = port
    log("Starting calculation server...", "service");
    component.modem.open(port);
    log("Searching for my slaves...", "master");
	print("Press any key to stop the searching process");

    searchingThread = thread.create(function ()
		while true do
			component.modem.broadcast(port, "I am your master now, bitches!");
			local _, _, from, _, _, message = event.pull(1, "modem_message");
			if message == "I wanna be your slave, master" and ~hasValue(slaves, from) then
				log("Now we have a new slave in our dungeon: "..from, "master");
				table.insert(slaves, from);
			end

			os.sleep();
		end
	end);

	os.sleep(.5);
	event.pull("key_up");
	searchingThread:suspend();

	log("We have "..#slaves.." slaves", "master");
	log("Server started", "service");
	multiserver.serverStarted = true;
end

function multiserver.getComputers()
	return slaves;
end

function multiserver.sendCommand(command)
	for i, slave in ipairs(slaves) do
		component.modem.send(slave, serverPort, command);
	end
end

return multiserver;
