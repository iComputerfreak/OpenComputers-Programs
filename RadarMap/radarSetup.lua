local component = require("component")
local event = require("event")
local computer = require("computer")
local fs = require("filesystem")

local MAX_COMPONENTS = 64
local i = 1

local path = "/home/addresses.txt"
fs.remove(path)
local file = io.open(path, "w")

while i <= MAX_COMPONENTS do
  print("Please connect the Redstone I/O for Chunk " .. i .. " & " .. (i + 1) .. ".")
  local eventType, address, componentType = event.pull("component_added")
  print(componentType .. " " .. address .. " registered.")
  file:write(address .. "\n")
  computer.beep()
  i = i + 2
end

print("Setup completed.")
file:close()