local component = require("component")
local sides = require("sides")
local event = require("event")

local hologram = component.hologram
local modem = component.modem

-- CONSTANTS
local RADAR_PORT = 100
-- The watched area will be a square of MAP_SIZE x MAP_SIZE chunks
local MAP_SIZE = 8
-- Number of maps used. If you use a 2x2 map, set this value to 2.
local MAP_COUNT = 2
local MAX_CHUNK_INDEX = (MAP_SIZE * MAP_SIZE)
-- The number of pixels used as width to create the overlay over a chunk on the map
local CHUNK_RESOLUTION = 2
-- The translation (offset) of the hologram as a whole. Unit: Hologram size
local OFFSET_X = 0.0
local OFFSET_Y = 0.75
local OFFSET_Z = 0.0
-- The scale of the hologram
local SCALE = 1.0
local OVERLAY_COLOR = 1
local OVERLAY_COLOR_HEX = 0xff0000
-- Pixel offset inside the projection frame
-- Create a dice out of the cuboid
local PIXEL_OFFSET_X = 16
local PIXEL_OFFSET_Y = 0
local PIXEL_OFFSET_Z = 18
local THICKNESS = 1

local radarControllers = {
"207af2b3-cc47-4287-b189-37e921152061",
"33bac410-07d2-466e-b657-1befdc59a84e",
"c91ac991-d6f2-46cd-bd70-7b71a487b99c",
"1b85cab9-6b59-4325-b2e3-b3e7da34296f"
}

function init ()
  hologram.clear()
  hologram.setPaletteColor(OVERLAY_COLOR, OVERLAY_COLOR_HEX)
  hologram.setTranslation(OFFSET_X, OFFSET_Y, OFFSET_Z)
  hologram.setScale(SCALE)
  modem.open(RADAR_PORT)
end

function translate(y)
  return (MAP_SIZE * MAP_COUNT * CHUNK_RESOLUTION + 1) - y
end

-- Sets a chunk in the hologram to a given state (on or off)
function setChunkHologram (controllerID, chunkID, newState)
  -- coordinate starting from zero
  local x = PIXEL_OFFSET_X + ((chunkID - 1) % MAP_SIZE) * CHUNK_RESOLUTION + 1
  local y = PIXEL_OFFSET_Y + (math.floor((chunkID - 1) / MAP_SIZE)) * CHUNK_RESOLUTION + 1
  local z = PIXEL_OFFSET_Z
  local color = 0
  if newState then
    color = OVERLAY_COLOR
  end
  
  -- Map Offset
  local controller = controllerID - 1
  x = (controller % MAP_COUNT) * MAP_SIZE * CHUNK_RESOLUTION + x
  y = (math.floor(controller / MAP_COUNT)) * MAP_SIZE * CHUNK_RESOLUTION + y
  
  for i=x, (x + CHUNK_RESOLUTION - 1) do
    for j=y, (y + CHUNK_RESOLUTION - 1) do
	  for k=z, (z + THICKNESS - 1) do
	    if i < 1 or translate(j) < 1 or k < 1 or i > 48 or translate(j) > 32 or k > 48 then
		  print("Trying to set illegal coordinates! (" .. i .. ", " .. translate(j) .. ", " .. k .. ")")
		end
        hologram.set(i, translate(j), k, color)
	  end
    end
  end
end

init()
print("Listening for Update packets on port " .. RADAR_PORT .. "...")
while true do
  -- Listen for network packets and process them
  local _, _, from, port, _, chunkID, newState = event.pull("modem_message")
  local controllerID = -1
  for i=1, #radarControllers do
    if radarControllers[i] == from then controllerID = i end
  end
  if controllerID == -1 then
    print("Received a message from an unknown Radar Controller on port " .. RADAR_PORT .. ". Address: " .. from .. ".")
    os.exit()
  end
  if chunkID < 1 or chunkID > MAX_CHUNK_INDEX then
    print("Controller " .. controllerID .. " sent an update for an invalid chunk ID (" .. chunkID .. ").")
  end
  setChunkHologram(controllerID, chunkID, newState)
end