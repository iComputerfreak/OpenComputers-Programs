# RadarMap
Uses a Hologram Projector to display incoming redstone signals as dots on a vanilla Minecraft map in an Item Frame.  
![Screenshot](https://i.imgur.com/3nyV1Wv.png)
Here: somewhere in Map 2.  
The numbers and markers on the map are Wool Blocks placed in the world.

## Screenshots
[A few Screenshots on Imgur](https://imgur.com/gallery/cMYWHkq)

## Setup
This setup assumes, you want to use a 2x2 map. This way you can monitor an area of 16x16 chunks.  
The scripts are written in a way that should allow customization to use more than 2x2 maps, but the Hologram Projector only supports a height of 32 pixels, so you will need to change the scale and other constants, so that one chunk on the map will be marked with 1 pixel instead of 2x2 pixels (default).  
Only square maps are supported. For other formats, you will need to change some code.

### Preparation
You will need a Player Detector from any mod in each chunk (placed in the middle with radius 8). This detector needs to send the redstone signal (preferably wireless) to your Redstone I/O ports.

### Servers
You need 3 Server Racks in total. Two of them will house the 4 Servers (and their corresponding Terminal Servers) that monitor the Redstone I/O components (the Radar Controllers). The other Rack will host the server with the Hologram Controller, that receives the incoming network messages and updates the Hologram Projector accordingly.

The 4 Radar Controller Servers need a Network and a Graphics Card each. They also need enough Component Buses to connect the 32 Redstone I/O components.
Then you connect each Radar Controller to one exclusive side in the Rack. You connect the Terminal Server to the same side and then the Network Card of the Server to a shared network side.

#### Example Rack Configuration
- Radar Controller 1: Connected to `back`
- Radar Controller 1 (Network Card): Connected to `left`
- Radar Controller 1 Terminal Server: Connected to `back`
- Radar Controller 2: Connected to `bottom`
- Radar Controller 2 (Network Card): Connected to `left`
- Radar Controller 2 Terminal Server: Connected to `bottom`

This way the Servers can communicate with their Terminal Servers and send Network Packets to a different side (to the Hologram Controller).

Now you place the third Rack and put in the Server that will play the Hologram Controller and it's Terminal Server. Connect them to a common side and the Network card of the Hologram Controller Server to an other side.

The first side will be connected to the Hologram Projector.
The other side has to be connected to the other two Racks (Network Card side to Network Card Side). You can also use a Relay in between to buffer network packages etc.

Now you connect cables to the two Radar Controller Racks. Each cable connects 32 Redstone I/O components with one of the servers. (Don't place the Redstone I/O yet!)

Make sure that all racks have power and only those cables connect that should connect.

### Redstone I/O
On each of the four Radar Controller Servers do the following:
- Start the `radarSetup.lua` script
- Connect the 32 Redstone I/O in the correct order (left to right, or whatever)
- Connect the wireless receiver of Chunk 1 to the first Redstone I/O (west side)
- Connect the wireless receiver of Chunk 2 to the first Redstone I/O (east side)
- Connect the wireless receiver of Chunk 3 to the second Redstone I/O (west side)
- Connect the wireless receivers of Chunk 4-64 accordingly

The sides (SIDE_1 = west and SIDE_2 = east) can be configured in `radarController.lua`  
When you placed all 32 Redstone I/O, the script will exit. You now have an `addresses.txt` file in your `/home` directory, listing all the Redstone I/O addresses in the correct order.

### Radar Controller Setup
Change the variable `HOLOGRAM_CONTROLLER` in `radarController.lua` to the address of your Server that will play the Hologram Controller.

### Hologram Controller Setup
The `hologramController` is configured to project a hologram over a 2x2 map, that is placed on a wall above the Hologram Projector with one vertical space in between and the Projector under the map on the left side.

Front View (`M` = Map, `0` = Air, `P` = Projector):
```
MM
MM
00
P0
```

In the `hologramController.lua` script you have to change the `radarControllers` table to contain the addresses of the **Network Cards** of the four Radar Controller Servers in the **correct** order.

### Starting the programs
Now you should be good to go. Start up the `radarController.lua` program on all four Radar Controller Servers and the `hologramController.lua` program on the Hologram Controller.

The Hologram should now mark every chunk on your 2x2 map, that contains a player (that sends a wireless redstone signal).

### Test Map
If you have problems setting this up, take a look at my example build in the `Radar Test.zip` world folder.  
The test world uses MC 1.12.2 (Forge 14.23.5.2847) and the following Mods:
- Draconic Evolution
- Ender IO
- JEI
- OpenComputers
- RFTools

and their dependencies. (There are some other Mods installed, but you don't need them to use the world)

The test world also shows dropped items on the radar (for testing purposes). To change that, you have to change the filter settings in the Draconic Evolution Entity Detectors. Also only the first 16 Chunks have Entity Detectors and only Server 2 has a working Redstone I/O setup.

If the test world doesn't work or you have problems or questions setting things up, feel free to open an Issue about it here.
