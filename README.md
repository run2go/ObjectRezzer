# ObjectRezzer
LSL Object Rezzer which allows to handle Objects without modification permissions (meant for "no mod" furniture in SL)

The #Furniture notecard is used to define & keep track of object names, target position and rotation.
Each line is being used for one object, separated into four sections each:
- Button/Label Name
- Object Name
- Target Position
- Target Rotation

## Setup

1. Create a new object for the ObjectRezzer and place the furniture/objects you want to rez inside its contents.
2. Place the Rezzer.lsl Script alongside the furniture pieces in the contents tab.
3. (Optional) If the parcel is deeded to a group, rez a second object for the RezzerHelper.lsl script.
   - Put the helper script into the contents and deed it to the land group.
   - Grant return permissions to the helper object owner by the land group.
