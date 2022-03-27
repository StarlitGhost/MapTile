# MapTile
A Windower 4 addon that displays your current zone and map tile position as a draggable text object.

It also tries to keep itself centered relative to where you place it (intended for placement above/below the ffxidb minimap).

## How to install:
1. Download the repository
2. Place in `Windower/addons/MapTile`

## How to make it load automatically:
1. Open `Windower/scripts/init.txt` (create it if it doesn't exist)
2. Add the line `lua l maptile` to the end of it

## How to manually enable in-game:
1. Login to your character in FFXI
2. Type `//lua l maptile` in chat

## Settings:
For now, edit `Windower/addons/MapTile/data/settings.xml` and use `//lua r maptile` in-game.

I'll be adding some `maptile` chat commands to set things in-game soon.
