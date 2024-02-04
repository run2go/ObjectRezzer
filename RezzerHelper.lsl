// RezzerHelper.lsl
// Author & Repository: https://github.com/run2go/ObjectRezzer
// License: MIT
// Version: 0.1.0

// Configuration Parameters
integer CHANNEL = 4588; // Comms channel for the communication
integer DEBUG = TRUE; // Toggle debug messages

// Helper Variables
key kObject;
key kLastOwner;

DebugMessage(string msg) { if (DEBUG) llRegionSayTo(kLastOwner, 0, msg); } // Helper function for debug messages

integer ReturnObject(key objectID) {    
    integer ERR = llReturnObjectsByID([objectID]);
    if (ERR < 0) {
        if (ERR==ERR_GENERIC) DebugMessage("Generic error.");
        else if (ERR==ERR_PARCEL_PERMISSIONS) DebugMessage("Script lacks parcel permissions.");
        else if (ERR==ERR_MALFORMED_PARAMS) DebugMessage("Parameters are malformed.");
        else if (ERR==ERR_RUNTIME_PERMISSIONS) DebugMessage("Script lacks the runtime permissions.");
        else if (ERR==ERR_THROTTLED) DebugMessage("Task has been throttled. Try again later.");
        return FALSE;
    }
    objectID = NULL_KEY;
    return TRUE;
}

default {
    state_entry() {
        kObject = llGetKey();
        kLastOwner = llList2Key(llGetObjectDetails(kObject, [OBJECT_LAST_OWNER_ID]), 0); // Get last owner key
        llRegionSayTo(kLastOwner, 0, (string)kLastOwner);
        llListen(CHANNEL, "", "", "");
        llRequestPermissions(kLastOwner, PERMISSION_RETURN_OBJECTS);
    }
    run_time_permissions(integer perm) {
        if (perm & PERMISSION_RETURN_OBJECTS) {
            llRegionSayTo(kLastOwner, 0, "Return Permissions aqcuired");
            llRegionSay(CHANNEL, "reg"); // Send msg to Rezzer.lsl
        }
    }
    touch_start(integer total_number) { if (llDetectedKey(0) == kLastOwner) llResetScript(); }
    
    listen(integer c, string n, key id, string msg) {
        key targetKey = (key)msg;
        if (llGetOwnerKey(id) == kLastOwner && targetKey != NULL_KEY) {
            integer returnResponse = ReturnObject(targetKey);
            llRegionSay(CHANNEL, (string)returnResponse);
        }
        DebugMessage(msg);
    }
}
