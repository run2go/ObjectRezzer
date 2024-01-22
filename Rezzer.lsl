// Rezzer.lsl
// Author & Repository: https://github.com/run2go/ObjectRezzer
// License: MIT

// Configuration Parameters
integer CHANNEL = 4588; // Comms channel for the communication

// Helper Variables
list objectData;
key currentObjectID = NULL_KEY;
string currentObjectName;
integer dialogChannel;
string gName;
integer gLine = 0;
key gQueryID;
integer gListener; // Keep track of listener

string trimQuotes(string input) { return llGetSubString(input, 1, -2); } // Trim quotes around a string

rezObject(integer button) {
    // Check if an object is already rezzed, if yes, delete it
    if (llKey2Name(currentObjectID) == currentObjectName && currentObjectName != "") llOwnerSay("Object already rezzed");
    else if (currentObjectID != NULL_KEY) ReturnObject(currentObjectID);
    else {
        currentObjectName = llList2String(objectData, button + 1);
        vector objectPos = (vector)llList2String(objectData, button + 2);
        vector objectRotVector = (vector)llList2String(objectData, button + 3);
        rotation objectRot = llEuler2Rot(objectRotVector * DEG_TO_RAD);
        rotation rezzerRot = llGetRot();
        
        // Calculate the offset based on the rezzer's position and rotation
        rotation offsetRot = rezzerRot * objectRot;
    
        // Attempt to rez the object
        llRezObject(currentObjectName, objectPos, ZERO_VECTOR, offsetRot, 0);
        llOwnerSay("\nShort: " + llGetSubString(llList2String(objectData, button), 0, 23)
                 + "\nName: " + currentObjectName
                 + "\nPos: " +  (string)objectPos
                 + "\nRotVector: " +  (string)objectRotVector
                 + "\nRot: " +  (string)objectRot
                 + "\noffsetRot: " + (string)offsetRot
                 + "\nrezzerRot: " + (string)rezzerRot);
    }
    //llOwnerSay("\n" + llDumpList2String(objectData, "\n"));
}
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
    currentObjectID = NULL_KEY;
    return TRUE;
}

default {
    state_entry() { // Import data from notecard during startup
        gName = llGetInventoryName(INVENTORY_NOTECARD, 0); // select the first notecard in the object's inventory
        gQueryID = llGetNotecardLine(gName, gLine); // request first line
    }

    dataserver(key query_id, string data) {
        if (query_id == gQueryID) {
            if (data != EOF) { // not at the end of the notecard
                list entry = llCSV2List(data);
                entry = llListReplaceList(entry, [trimQuotes(llList2String(entry, 0)), trimQuotes(llList2String(entry, 1))], 0, 1);
                objectData += entry;
                ++gLine;
                gQueryID = llGetNotecardLine(gName, gLine);
            } // else llOwnerSay("Notecard Imported.");
        }
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
            buttonLabels += llGetSubString(buttonName, 0, 23);
        }
        
        llDialog(llGetOwner(), "Select an object to rez:", buttonLabels, dialogChannel);
        llSetTimerEvent(60.0); // 1min Timeout per dialog prompt
    }
    
    timer() {
        llListenRemove(gListener); // Stop listening
        llSetTimerEvent(0); // Stop the timer now that its job is done
    }
    
    listen(integer chan, string name, key id, string msg) {
        integer listIndex = llListFindList(objectData, (list)msg);
        if (~listIndex) rezObject(listIndex);
        else if (msg == "[Clear]") ReturnObject(currentObjectID);
        
        llSetTimerEvent(0.1); // Trigger cleanup
    }
}
