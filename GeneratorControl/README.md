# Generator Control

## Charge Controller
Turns a Redstone signal on or off based on the energy stored in a GregTech Battery Buffer.

In your `/home` directory, create two files `BOT_TOKEN` and `CHAT_ID` that contain the Telegram Bot Token and the Chat ID where your messages should be sent to.

When the Battery Buffer RF storage falls under 10% (configurable), it turns on the Redstone signal and sends a silent Telegram message.  
When the Battery Buffer RF storage is more than 90% (configurable), it turns off the Redstone signal and sends a silent Telegram message.  
When the Battery Buffer RF storage falls under 2%, it sends a non-silent Telegram message, saying the buffer ran dry and turns off the Redstone signal.

## Charge Display
Displays the charge information sent by the Charge Controller.