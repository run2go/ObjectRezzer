// Rezzer.lsl
// Author & Repository: https://github.com/run2go/ObjectRezzer
// License: MIT
// Version: 0.1.0

// Configuration Parameters
integer CHANNEL = 4588; // Comms channel for the communication
integer DEBUG = TRUE; // Toggle debug messages

// Helper Variables
key kObjectOwner;
key kLandOwner;
key kLandGroup;
integer bGroupOwned = FALSE;
key kRezzerHelper = NULL_KEY;
list objectData;
key currentObjectID = NULL_KEY;
string currentObjectName = "NULL";
integer dialogChannel;
string gName;
integer gLine = 0;
key gQueryID;
integer gListener; // Keep track of script menus
integer gListenHelper; // Allow RezzerHelper.lsl to register
integer nDuplicates = 0;

DebugMessage(string msg) { if (DEBUG) llRegionSayTo(kObjectOwner, 0, msg); } // Helper function for debug messages

string trimQuotes(string input) { return llGetSubString(input, 1, -2); } // Trim quotes around a string

RezObject(integer button) {
    // Object is already rezzed? Delete it first
    if (llKey2Name(currentObjectID) == currentObjectName) llOwnerSay("Object already rezzed");
    //else if (currentObjectID != NULL_KEY) ReturnObject(currentObjectID);
    else {
        currentObjectName = llList2String(objectData, button + 1);
        vector objectPos = (vector)llList2String(objectData, button + 2);
        vector objectRotVector = (vector)llList2String(objectData, button + 3);
        rotation objectRot = llEuler2Rot(objectRotVector * DEG_TO_RAD);
        rotation rezzerRot = llGetRot();
        rotation offsetRot = rezzerRot * objectRot; // Calculate the offset based on the rezzer's position and rotation
        //llSensor(currentObjectName, NULL_KEY, ( PASSIVE ), 15.0, PI); // Start a sensor to get the rezzed key
        //llSetTimerEvent(0.1); // Remove unregistered existing object(s) first .. recursion until all objects are gone?
        llRezObject(currentObjectName, objectPos, ZERO_VECTOR, offsetRot, 0); // Rez the object
        //llSensor(currentObjectName, NULL_KEY, ( PASSIVE | SCRIPTED ), 15.0, PI); // Start a sensor to get the rezzed key
        llSensor("", NULL_KEY, ( PASSIVE ), 15.0, PI); // Start a sensor to get the rezzed key
        llSetTimerEvent(2); // Issue a TimerEvent after 2s
    }
    //DebugMessage("\n" + llDumpList2String(objectData, "\n"));
}

ReturnObject(key objectID) {
    if (!bGroupOwned) {
        integer ERR = llReturnObjectsByID([objectID]);
        if (ERR < 0) {
            if (ERR==ERR_GENERIC) DebugMessage("Generic error.");
            else if (ERR==ERR_PARCEL_PERMISSIONS) DebugMessage("Script lacks parcel permissions.");
            else if (ERR==ERR_MALFORMED_PARAMS) DebugMessage("Parameters are malformed.");
            else if (ERR==ERR_RUNTIME_PERMISSIONS) DebugMessage("Script lacks the runtime permissions.");
            else if (ERR==ERR_THROTTLED) DebugMessage("Task has been throttled. Try again later.");
        }
        currentObjectID = NULL_KEY;
    }
    else if (kRezzerHelper != NULL_KEY) llRegionSayTo(kRezzerHelper, CHANNEL, objectID); // Pass objectID to RezzerHelper.lsl
    else llRegionSayTo(kLandOwner, 0, "Missing RezzerHelper Object for group owned land.");
}

default {
    on_rez(integer start_param) { llResetScript(); }
    state_entry() { // Import data from notecard during startup
        gName = llGetInventoryName(INVENTORY_NOTECARD, 0); // Select the first notecard in the object's inventory
        gQueryID = llGetNotecardLine(gName, gLine); // Request first line
        gListenHelper = llListen(CHANNEL, "", "", "");
        kObjectOwner = llGetOwner();
        kLandOwner = llGetLandOwnerAt(llGetPos());
        kLandGroup = llList2Key(llGetParcelDetails(llGetPos(), [PARCEL_DETAILS_GROUP]), 0);
        if (kLandOwner == kLandGroup) bGroupOwned = TRUE;
        else llRequestPermissions(kLandOwner, PERMISSION_RETURN_OBJECTS);
    }

    dataserver(key query_id, string data) {
        if (query_id == gQueryID) {
            if (data != EOF) { // Not at the end of the notecard
                list entry = llCSV2List(data);
                entry = llListReplaceList(entry, [trimQuotes(llList2String(entry, 0)), trimQuotes(llList2String(entry, 1))], 0, 1);
                objectData += entry;
                ++gLine;
                gQueryID = llGetNotecardLine(gName, gLine);
            } // else llOwnerSay("Notecard Imported.");
        }
    }
    
    run_time_permissions(integer perm) {
        if (perm & PERMISSION_RETURN_OBJECTS) llRegionSayTo(kLandOwner, 0, "Return Permissions aqcuired");
    }
    
    touch_start(integer total_number) { // Display a dialog with buttons for each object name
        dialogChannel = (integer)("0x" + llGetSubString(llGetKey(), 0, 7)); // Create a unique channel for the dialog
        llListenRemove(gListener); // Kill active listener
        key user = llDetectedKey(0);
        gListener = llListen(dialogChannel, "", user, ""); // Setup listener first
        
        integer numObjects = llGetListLength(objectData) / 4; // 4 data entries per object
        list buttonLabels = ["[Clear]"];
        integer i;
        for (i = 0; i < numObjects; ++i) {
            string buttonName = llList2String(objectData, i * 4);
            buttonLabels += llGetSubString(buttonName, 0, 23); // Trim object names incase they are too long
        }
        llDialog(llGetOwner(), "Select an object to rez:", buttonLabels, dialogChannel);
        llSetTimerEvent(60.0); // 1min Timeout per dialog prompt
    }
    
    timer() {
        llSensorRemove(); // Tear down sensor if active
        llListenRemove(gListener); // Stop listening to menus
        //llListenRemove(gListenHelper); // Disable listener for helper object
        llSetTimerEvent(0); // Stop the timer now that its job is done
    }
    
    sensor(integer detected) {
        integer i;
        for (i = 0; i <= detected; i++) {
            if (llDetectedName(i) == currentObjectName) {
                currentObjectID = llDetectedKey(i);
                DebugMessage((string)currentObjectID);
            }
        }
    }
    
    listen(integer c, string n, key id, string msg) {
        DebugMessage((string)id + " on " + (string)c + ": " + msg);
        if (c == CHANNEL && msg == "reg") kRezzerHelper = id; // Register RezzerHelper
        else if (c == dialogChannel) {
            integer listIndex = llListFindList(objectData, (list)msg);
            if (~listIndex) RezObject(listIndex);
            else if (msg == "[Clear]") ReturnObject(currentObjectID);
        }
        llSetTimerEvent(0.1); // Trigger cleanup
    }
}
