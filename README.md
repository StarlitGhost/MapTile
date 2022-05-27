# WhereAmI
A Windower 4 addon that displays your current zone, sub-map number, and map tile position as a draggable text object.

(originally intended for placement above/below the ffxidb minimap, but you do you!)

## How to install:
1. Download the repository [here](https://github.com/StarlitGhost/WhereAmI/archive/refs/heads/master.zip)
2. Extract and place in `Windower/addons/WhereAmI`

## How to make it load automatically:
1. Open `Windower/scripts/init.txt` (create it if it doesn't exist)
2. Add the line `lua l whereami` to the end of it

## How to manually enable in-game:
1. Login to your character in FFXI
2. Type `//lua l whereami` in chat

## Settings:
- `//wai align <left/center/right>` - set the text alignment
- `//wai expand <on/off/toggle>` - expand abbreviations
- `//wai reset` - resets position and alignment to top left corner of UI

For font/color settings, edit `Windower/addons/WhereAmI/data/settings.xml` and use `//lua r whereami` in-game.
