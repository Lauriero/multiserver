local component = require "component";
local event = require "event";

function string.split(inputstr, sep)
    if sep == nil then
        sep = "%s"
    end

    local t={}
    for str in string.gmatch(inputstr, "([^,]+)") do
        table.insert(t, str);
    end

    return t
end

function log(message, from)
    print("["..from.."] : "..message);
end

--Commands list--
local commands = {};

function commands.voice()
    print("Gaf-gaf");
	component.modem.send(master, port, "Gaf-gaf");
end

--Starting--
log("Slave script started", "service");

log("Give me a port where I will be waiting for my master on", "slave");
port = tonumber(io.read());

component.modem.open(port);
log("I waiting for my master on "..port, "slave");

local master = "";
while true do
    ----------------Waiting for incoming message-------------
    local _, _, from, _, _, message = event.pull("modem_message");

    ---------------On master coming--------------------------
    if message == "I am your master now, bitches!" and master == "" then
        component.modem.send(from, port, "I wanna be your slave, master");
        master = from;
        log("My master is "..master, "slave");
        log("Waiting commands...", "slave");
    end

    --------------On master command---------------------------
    if from == master and message ~= "" and message ~= "I am your master now, bitches!" then
		--Remove spaces--
		message = string.gsub(message, " ", "");

		local separator_index, _ = string.find(message, "|");
		--If command with parameters--
		if separator_index ~= nil then
		    command_params = string.split(message:sub(separator_index + 1), ",");
		    command_name = message:sub(1, separator_index - 1);
		else
		    command_name = message;
		end

		if commands[command_name] == nil then
		    log("I don't know the command what master says me", "slave");
			component.modem.send(master, port, "I don't know this command, master");
		else
		    log("Doing what master said", "slave");
			component.modem.send(master, port, "Yes, master");
		    commands[command_name](command_params);
		end
    end

    os.sleep();
end
