-- This script requires the BatteryBufferDriver mod to work: https://github.com/iComputerfreak/BatteryBufferDriver

-- To display the charge values sent by this script, use the chargeDisplay.lua script
-- The script can be found here: https://gist.github.com/iComputerfreak/2821836ed3b29a3b1ed2c76c2570b16e

local sides = require("sides")
local component = require("component")
local event = require("event")
local m = component.modem
local inet = require("internet")
local filesystem = require("filesystem")
local redstone = component.redstone


-- Read the Telegram Bot Token from the file "BOT_TOKEN"
local tokenFile = io.open("/home/BOT_TOKEN")
local TOKEN = tokenFile:read("*l") -- read the whole line
tokenFile:close()
local chatIDFile = io.open("/home/CHAT_ID")
local CHAT_ID = chatIDFile:read("*l")
chatIDFile:close()

local TELEGRAM_URL = "https://api.telegram.org/bot" .. TOKEN .. "/sendMessage"

-- Which side the battery buffer is connected to (currently only TOP works)
local BUFFER_SIDE = sides.top
-- Which side the Redstone I/O should output
local REDSTONE_OUTPUT_SIDE = sides.top

-- The strength of the modem signal (0 to disable, increase if the computer with the chargeDisplay.lua script doesn't retrieve the information)
local STRENGTH = 20
-- Whether the script should send a pulse to turn on/off the generator instead of setting the signal directly to on/off
local USE_PULSE = false

-- If the percentage values should be checked per battery instead of per buffer
local CHECK_PER_BATTERY = false
-- The value at which the generator should turn on
local MIN_CHARGE_PERCENT = 10
-- The value at which the generator should turn off
local MAX_CHARGE_PERCENT = 90


local running = false

function getTime ()
  local file = io.open("/tmp/clock.dt", "w")
  file:write('')
  file:close()
  local lastmod = tonumber(string.sub(fs.lastModified("/tmp/clock.dt"), 1, -4))
  -- Convert to UTC + 1
  lastmod = lastmod + 3600
  return os.date("%Y-%m-%d %H:%M:%S", lastmod)
end

function timestamp()
    return "[" .. getTime() .. "] "
end

function sendMessage(message, silent)
	silent = silent or false
	local data = {}
	data["chat_id"] = CHAT_ID
	data["text"] = message
	data["disable_notification"] = silent
	inet.request(TELEGRAM_URL, data)
end

function getCharge()
	return component.battery_buffer.getCharge()
end

function getPercent(charge, capacity)
	local percent = charge * 100
	percent = percent / capacity
	return percent
end

function getChargeOfBattery(i)
	return component.battery_buffer.getSingleCharge(i)
end

function getCapacity()
	return component.battery_buffer.getCapacity()
end

function getCapacityOfBattery(i)
	return component.battery_buffer.getSingleCapacity(i)
end


-- The number of batteries actually in the buffer
function getBatteryCount()
	return component.battery_buffer.getBatteryCount()
end

function shouldTurnOn()
	if running then
		-- If the generator is already on, don't turn it on again
		return false
	end
	
	if CHECK_PER_BATTERY then
		-- Check if any battery is under the minimum
		for i = 0,(getBatteryCount() - 1) do
			local percent = getPercent(getChargeOfBattery(i), getCapacityOfBattery(i))
			if percent <= MIN_CHARGE_PERCENT then
				-- If one battery is too low, return true
				return true
			end
		end
	else
		local percent = getPercent(getCharge(), getCapacity())
		return percent <= MIN_CHARGE_PERCENT
	end
	
	return false
end

function shouldTurnOff()
	if running == false then
		-- If the generator is already off, don't turn it off again
		return false
	end
		
    if CHECK_PER_BATTERY then
		-- Check if each battery is already over the maximum
		for i = 0,(getBatteryCount() - 1) do
			local percent = getPercent(getChargeOfBattery(i), getCapacityOfBattery(i))
			if percent < MAX_CHARGE_PERCENT then
				-- If one battery is too low, return false
				return false
			end
		end
	else
		local percent = getPercent(getCharge(), getCapacity())
		return percent >= MAX_CHARGE_PERCENT
	end
	
	return true
end

function isRunningDry()
	return getPercent(getCharge(), getCapacity()) < 2
end

function sendCharge()
	m.broadcast(123, getCharge(), getCapacity(), running, false)
end

function turnOn()
	redstone.setOutput(REDSTONE_OUTPUT_SIDE, 15)
	if USE_PULSE then
		component.redstone.setOutput(REDSTONE_OUTPUT_SIDE, 0)
	end
	running = true
end

function turnOff()
	if USE_PULSE then
		component.redstone.setOutput(REDSTONE_OUTPUT_SIDE, 15)
	end
	component.redstone.setOutput(REDSTONE_OUTPUT_SIDE, 0)
	running = false
end

require("term").clear()
print("Starting Charge Control v1.0...")
-- In case the generator is already running when the PC boots, turn it off, so everything is synced
turnOff()
m.setStrength(STRENGTH)
while true do
	if isRunningDry() then
		turnOff()
		break
	end
	
	if shouldTurnOn() then
		turnOn()
		print(timestamp() .. "Turning generator on...")
		sendMessage("Generator turned on", true)
	end
	
	if shouldTurnOff() then
		turnOff()
		print(timestamp() .. "Turning generator off...")
		sendMessage("Generator turned off", true)
	end
	
	sendCharge()
end

print("Battery Buffer has run dry!")
sendMessage("The buffer has run dry! Generator turned off.")