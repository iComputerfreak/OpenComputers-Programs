local component = require("component")
local event = require("event")
local computer = require("computer")
local inet = require("internet")
local fs = require("filesystem")
local sides = require("sides")

local modem = component.modem
local redstone = component.redstone

local RADAR_PORT = 100
local COOLDOWN = 180

local REDSTONE_INPUT = sides.top
local REDSTONE_OUTPUT = sides.west

-- Telegram Setup
local tokenFile = io.open("/home/BOT_TOKEN")
local TOKEN = tokenFile:read("*l")
io.close(tokenFile)
local chatIDFile = io.open("/home/CHAT_ID")
local CHAT_ID = chatIDFile:read("*l")
io.close(chatIDFile)
local TELEGRAM_URL = "https://api.telegram.org/bot" .. TOKEN .. "/sendMessage"

local lastNotification = computer.uptime() - COOLDOWN

function init ()
  modem.open(RADAR_PORT)
end

function playersOnline ()
  return redstone.getInput(REDSTONE_INPUT) > 0
end

function getTime ()
  local file = io.open("/tmp/clock.dt", "w")
  file:write('')
  file:close()
  local lastmod = tonumber(string.sub(fs.lastModified("/tmp/clock.dt"), 1, -4))
  -- Convert to UTC + 1
  lastmod = lastmod + 3600
  return os.date("%Y-%m-%d %H:%M:%S", lastmod)
end

function sendTelegram (message)
  if computer.uptime() - lastNotification > COOLDOWN then
    local data = {}
    data["chat_id"] = CHAT_ID
    data["text"] = message
    inet.request(TELEGRAM_URL, data)
    lastNotification = computer.uptime()
  end
end

function sendIngame (chunkID, newState)
  -- Output a Redstone signal to trigger a Notification Block
  redstone.setOutput(REDSTONE_OUTPUT, 15)
  os.sleep(0.5)
  redstone.setOutput(REDSTONE_OUTPUT, 0)
end

function reportIntruder (chunkID, newState)
  local action = ""
  if newState then
    action = "entered"
  else
    action = "left"
  end
  print("[" .. getTime() .. "] " .. "Intruder Alert! Someone " .. action .. " Chunk " .. chunkID .. ".")
  if playersOnline() then
    sendIngame(chunkID, newState)
  else
    sendTelegram("Intruder Alert!")
  end
end

init()
print("Listening for Chunk updates...")
while true do
  local _, _, from, port, _, chunkID, newState = event.pull("modem_message")
  reportIntruder(chunkID, newState)
end