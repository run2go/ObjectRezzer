// RezzerHelper.lsl
// Author & Repository: https://github.com/run2go/ObjectRezzer
// License: MIT

// Configuration Parameters
integer CHANNEL = 4588; // Comms channel for the communication

// Helper Variables
key kObject;
list lObjectDetails;
key kLastOwner;

integer ReturnObject(key objectID) {    
    integer ERR = llReturnObjectsByID([objectID]);
    if (ERR < 0) {
        if (ERR==ERR_GENERIC) llOwnerSay("Generic error.");
        else if (ERR==ERR_PARCEL_PERMISSIONS) llOwnerSay("Script lacks parcel permissions.");
        else if (ERR==ERR_MALFORMED_PARAMS) llOwnerSay("Parameters are malformed.");
        else if (ERR==ERR_RUNTIME_PERMISSIONS) llOwnerSay("Script lacks the runtime permissions.");
        else if (ERR==ERR_THROTTLED) llOwnerSay("Task has been throttled. Try again later.");
        return FALSE;
    }
    objectID = NULL_KEY;
    return TRUE;
}


default
{
    state_entry() {
        kObject = llGetKey();
        lObjectDetails = llGetObjectDetails(kObject, ([OBJECT_LAST_OWNER_ID]));
        kLastOwner = llList2Key(lObjectDetails, 0);
        llListen(CHANNEL, "", "", "");
        llRegionSay(CHANNEL, (string)llGetKey());
    }
    listen(integer c, string n, key id, string msg) {
        if (llGetOwnerKey(id) == kLastOwner) {
            integer returnResponse = ReturnObject((key)msg);
            llRegionSay(CHANNEL, (string)returnResponse);
        }
    }
}
