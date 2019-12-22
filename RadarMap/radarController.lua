local component = require("component")
local sides = require("sides")
local fs = require("filesystem")
local event = require("event")

local modem = component.modem

-- The number of chunks, this controller handles
local MAX_CHUNK_INDEX = 64
local SLEEP_TIME = 0.5
-- Side configuration of the Redstone I/O Components
local SIDE_1 = sides.west
local SIDE_2 = sides.east

local HOLOGRAM_CONTROLLER = "85695943-f07e-46ff-ae02-17234de97794"
local RADAR_PORT = 100

-- Runtime variables
local activeChunks = {}
local addresses = {}

function ternary (cond, T, F)
  if cond then return T else return F end
end

-- Initializes the program
function init ()
  -- Read addresses
  local path = "/home/addresses.txt"
  if not fs.exists(path) then
    print("Please run the setup first, to read the Redstone I/O addresses.")
    os.exit()
  end
  local file = io.open(path, "r")

  -- Initialize table and read addresses
  for i=1, MAX_CHUNK_INDEX do
    activeChunks[i] = false
	local r = file:read("*l")
	if r ~= nil then
	  addresses[i] = r
	end
  end
  
  file:close()
  print("Read " .. #addresses .. " addresses.")
  modem.open(100)
end

function getChunkState (chunkID)
  -- local address = addresses[((chunkID - 1) / 2) + 1]
  local address = addresses[math.floor((chunkID - 1) / 2) + 1]
  local side = ternary(chunkID % 2 == 1, SIDE_1, SIDE_2)
  local input = component.proxy(address).getInput(side)
  return input > 0
end

function sendUpdate (chunkID, newState)
  print("Sending update for chunk " .. chunkID .. ": " .. ternary(newState, "ACTIVE", "INACTIVE") .. ".")
  -- Send packet
  modem.send(HOLOGRAM_CONTROLLER, RADAR_PORT, chunkID, newState)
end

-- Updates the hologram map
function update ()
  -- Update Table
  for i=1, MAX_CHUNK_INDEX do
    local newState = getChunkState(i)
	if activeChunks[i] ~= newState then
	  -- Update the table and send the update via network
      activeChunks[i] = newState
	  sendUpdate(i, newState)
	end
  end
end


-- MAIN PROGRAM
init()
while true do
  update()
  os.sleep(SLEEP_TIME)
end