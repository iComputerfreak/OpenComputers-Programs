local component = require("component")
local sides = require("sides")
local computer = require("computer")
local event = require("event")
local inet = require("internet")

local rs = component.redstone

local KEEP_ALIVE_INTERVAL = 60  -- in seconds
local TIMEOUT = 180 -- in seconds
local KEEP_ALIVE_PORT = 101
local REDSTONE_OUTPUT_SIDE = sides.north

local radarControllers = {
"207af2b3-cc47-4287-b189-37e921152061",
"33bac410-07d2-466e-b657-1befdc59a84e",
"c91ac991-d6f2-46cd-bd70-7b71a487b99c",
"1b85cab9-6b59-4325-b2e3-b3e7da34296f"
}

local controllerTIMES = {}

-- Telegram Setup
local tokenFile = io.open("/home/BOT_TOKEN")
local TOKEN = tokenFile:read("*l")
io.close(tokenFile)
local chatIDFile = io.open("/home/CHAT_ID")
local CHAT_ID = chatIDFile:read("*l")
io.close(chatIDFile)
local TELEGRAM_URL = "https://api.telegram.org/bot" .. TOKEN .. "/sendMessage"

function init()
  for i=1, #radarControllers do
    controllerTIMES[i] = computer.uptime()
  end
  component.modem.open(KEEP_ALIVE_PORT)
  rs.setOutput(REDSTONE_OUTPUT_SIDE, 0)
end

function sendTelegram (message)
  local data = {}
  data["chat_id"] = CHAT_ID
  data["text"] = message
  inet.request(TELEGRAM_URL, data)
end

function reportOffline(id)
  print("Radar Controller " .. id .. " is offline.")
  rs.setOutput(REDSTONE_OUTPUT_SIDE, 15)
  sendTelegram("One of the Radar Controllers is offline!")
  os.exit()
end

function gotMessage(id)
  controllerTIMES[id] = computer.uptime()
  print("Radar Controller " .. id .. " is still running.")
end

function checkTime()
  for i=1, #controllerTIMES do
    if (computer.uptime() - controllerTIMES[i] > TIMEOUT) then
      reportOffline(i)
    end
  end
end

-- Program start
init()
print("Listening for keep alive packets on port " .. KEEP_ALIVE_PORT .. "...")
while true do
  -- Listen for network packets and process them
  local _, _, from, port, _, isAlive = event.pull(KEEP_ALIVE_INTERVAL, "modem_message")

  if from ~= nil then
    -- Compares controllerid with authorized controllers from list
    local controllerID = -1
    for i=1, #radarControllers do
      if radarControllers[i] == from then controllerID = i end
    end
    if controllerID == -1 then
      print("Received a message from an unknown Radar Controller on port " .. KEEP_ALIVE_PORT .. ". Address: " .. from .. ".")
    end
    gotMessage(controllerID)
  end
  checkTime()
end
