-- This script displays the information sent by this script: https://gist.github.com/iComputerfreak/077d9c28e0c99f00453d0dc1a6fc8f07

local event = require("event")
local term = require("term")
local component = require("component")
local m = component.modem
local gpu = component.gpu
local unicode = require("unicode")

-- The width of the display (in characters)
local WIDTH = 28
-- The amount of characters in the first column (max length of characters before the values)
local firstCol = 10

m.open(123)
gpu.setResolution(WIDTH,7)

function comma_value(v)
    local s = string.format("%d", math.floor(v))
    local pos = string.len(s) % 3
    if pos == 0 then pos = 3 end
    return string.sub(s, 1, pos)
    .. string.gsub(string.sub(s, pos+1), "(...)", ",%1")
end

function center(str)
	local strLen = unicode.len(str)
	local maxPad = (WIDTH - strLen) / 2
	return padding(str, (maxPad + strLen))
end

function padding(str, upTo)
	local result = str
	local length = upTo - unicode.len(str)
	if length <= 0 then
		return str
	end
	for i = 1,length do
		result = " "..result
	end
	return result
end

term.clear()
print("")
print("")
print(" Retrieving information...  ")
print("")
print("")
while true do
    local _, _, from, port, _, charge, capacity, running = event.pull("modem_message")
	
	local percent = math.floor((charge * 100) / capacity + 0.5)
	
	local upTo = WIDTH - firstCol
	local firstPadding = (WIDTH - 16) / 2
	
    term.clear()
	print("")
    print("Charge:   " .. padding(comma_value(charge), upTo))
    print("Capacity: " .. padding(comma_value(capacity), upTo))
	print("Charge:   " .. padding(percent .. "%", upTo))
	print("")
	if running then
		gpu.setForeground(0x00FF00)
		print(padding("Generator running", (17 + firstPadding)))
	else
		gpu.setForeground(0xFF0000)
		print(padding("Generator paused", (16 + firstPadding)))
	end
	gpu.setForeground(0xFFFFFF)
    os.sleep(1)
end