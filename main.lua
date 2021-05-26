-----------------------------------------------------------------------------------------
-- main.lua
-----------------------------------------------------------------------------------------
--this function sets up a few global variables and baseline config.
--remember, lua requires code to be in order to reference (cant call a function that's lower in the file than the current one)
--Remember: in LUA, if you use strings to index a table, you can't use #table to get a count accurately, but the string reference will work.

system.setIdleTimer(false) --disables screen auto-off.

require("store")
require("helpers")
require("gameLogic")
--require("database")
require("plusCodes")
require("localNetwork")

forceRedraw = false --used to tell the screen to redraw even if we havent moved.

debug = true --set false for release builds. Set true for lots of console info being dumped. Must be global to apply to all files.
debugGPS = true --display data for the GPS event and timer loop and auto-move
debugDB = false
debugLocal = true
debugNetwork = false
debugSpin = false
--uncomment when testing to clear local data.
--ResetDatabase()
--Doing this here, before anything else opens and locks files.
local dataPath = system.pathForFile("database.sqlite", system.ResourceDirectory)
print(dataPath)
if (not doesFileExist("database.sqlite", system.DocumentsDirectory)) then   
    print("copying user database")
    copyFile("database.sqlite", system.ResourceDirectory, "database.sqlite", system.DocumentsDirectory, false)
end


startDatabase()

currentPlusCode = "" -- where the user is sitting now
lastPlusCode = "" --the previously received value for the location event, may be the same as currentPlusCode
previousPlusCode = ""  --the previous DIFFERENT pluscode value we visited.
currentHeading = 0
lastScoreLog = ""
lastLocationEvent = ""

tappedAreaName = ""
tappedAreaScore = 0
tappedAreaMapDataId = 0
currentScoreboardInstance = -1 -- magic value to be updated at loading screen.

tappedCell = "            "
redrawOverlay = false
factionID = 0 --composer.getVariable(factionID) used to be used in some spots, reverted that change.

typeNames = {}
typeNames["1"] = "Water"
typeNames["2"] = "Wetlands"
typeNames["3"] = "Park"
typeNames["4"] = "Beach"
typeNames["5"] = "University"
typeNames["6"] = "Nature Reserve"
typeNames["7"] = "Cemetery"
--typeNames["8"] = "Retail" --old mall entry, should never appear
typeNames["9"] = "Retail"
typeNames["10"] = "Tourism"
typeNames["11"] = "Historical"
typeNames["12"] = "Trail"
--typeNames["13"] = "" --admin entry, should never appear
typeNames["14"] = "Building"
typeNames["15"] = "Road"
typeNames["16"] = "Parking"
typeNames["100"] = "Server-Generated"

requestedCells = ""

cellDataCache = {}

--making the network indicator persist through all scenes
networkDown = display.newImageRect("themables/networkDown.png", 25, 25)
networkDown.x = 0
networkDown.y = 0
networkDown.anchorX = 0
networkDown.anchorY = 0

networkUp = display.newImageRect("themables/networkUp.png", 25, 25)
networkUp.x = 0
networkUp.y = 0
networkUp.anchorX = 0
networkUp.anchorY = 0
networkUp.isVisible = false

networkTx = display.newImageRect("themables/networkTransfer.png", 25, 25)
networkTx.x = 0
networkTx.y = 0
networkTx.anchorX = 0
networkTx.anchorY = 0
networkTx.isVisible = false

tapData = display.newText("Cell Tapped:", 20, 1250, native.systemFont, 20)
tapData.anchorX = 0

print(system.getInfo("deviceID"))

--OSM License Compliance. Do not remove this line.
--It might be moved, but it must be visible when maptiles are.
--TODO: link to OSM license info when tapped?
local osmLicenseText = display.newText("Map Data © OpenStreetMap contributors", 530, 1250, native.systemFont, 20)

function gpsListener(event)

    print("main gps fired")

    if (debugGPS) then
        print("got GPS event")
        if (event.errorCode ~= nil) then
            print("GPS Error " .. event.errorCode)
            return
        end

        print("Coords " .. event.latitude .. " " ..event.longitude)
    end

    if (event.direction ~= 0) then
         currentHeading = event.direction
     end

    local pluscode = encodeLatLon(event.latitude, event.longitude, 10); --only goes to 10 right now.
    if (debugGPS) then print ("Plus Code: " .. pluscode) end
    currentPlusCode = pluscode
    local plusCode8 = currentPlusCode:sub(0,8)

    if (lastPlusCode ~= currentPlusCode) then
        --update score stuff, we moved a cell.  Other stuff needs to process as usual.
        if(debugGPS) then print("calculating score") end
        lastScoreLog = "Earned " .. grantPoints(currentPlusCode) .. " points from cell " .. currentPlusCode
        lastPlusCode = currentPlusCode
    end

    if(debugGPS) then print("Finished location event") end
    lastLocationEvent = event
end

function backListener(event)
    if (debug) then print("key listener got")  end
    if (event.keyName == "back" and event.phase == "up") then
        local currentScene = composer.getSceneName("current")
        if (currentScene == "PaintTownScene") then
            return false
        end
        if (debug) then print("back to main scene") end
        local options = {effect = "flip", time = 125}
        composer.gotoScene("PaintTownScene", options)
        return true
    end
    if (debug) then print("didn't handle this one") end
end

function assignGpsListener()
    Runtime:addEventListener("location", gpsListener)
end

if (pcall(assignGpsListener)) then
    --success, do nothing
    print("GPS listener started")
else
    timer.performWithDelay(5000, assignGpsListener, 1)
    print("GPS listener failed, waiting 5 seconds and retrying")
end

Runtime:addEventListener("key", backListener) --this could be removed on iOS

function netUp()
    networkUp.isVisible = true
    networkDown.isVisible = false
    networkTx.isVisible = false
end

function netDown()
    networkDown.isVisible = true
    networkUp.isVisible = false
    networkTx.isVisible = false
end

function netTransfer()
    networkDown.isVisible = false
    networkUp.isVisible = false
    networkTx.isVisible = true
end

print("shifting to loading scene")
local composer = require("composer")
composer.isDebug = debug
composer.gotoScene("loadingScene")
--currentPlusCode = "87G8Q2JM+F9" --central park, simulator purposes --TODO remember to disable this for iOS app store submission, it confuses their testers.
currentPlusCode = "86HWG94W+2Q" --CWRU, simulator purposes --TODO remember to disable this for iOS app store submission, it confuses their testers.

local function myUnhandledErrorListener( event )
 
    local iHandledTheError = true
 
    if iHandledTheError then
        print( "Handling the unhandled error", event.errorMessage )
    else
        print( "Not handling the unhandled error", event.errorMessage )
    end
    
    return iHandledTheError
end
 
Runtime:addEventListener("unhandledError", myUnhandledErrorListener)