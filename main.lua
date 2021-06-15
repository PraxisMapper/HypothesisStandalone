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
require("database")
require("plusCodes")
require("localNetwork")

local composer = require("composer")
composer.isDebug = debug

forceRedraw = false --used to tell the screen to redraw even if we havent moved.

debug = true --set false for release builds. Set true for lots of console info being dumped. Must be global to apply to all files.
debugGPS = false --display data for the GPS event and timer loop and auto-move
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
    print("copied")
end


--commonCodeLetters = GetCommonLetters()
--codeTrim = #commonCodeLetters
startDatabase()

currentPlusCode = "" -- where the user is sitting now
lastPlusCode = "" --the previously received value for the location event, may be the same as currentPlusCode
previousPlusCode = ""  --the previous DIFFERENT pluscode value we visited.
currentHeading = 0
lastScoreLog = ""
lastLocationEvent = ""
currentLocationName = ""

tappedAreaName = ""
tappedAreaScore = 0
tappedAreaMapDataId = 0
currentScoreboardInstance = -1 -- magic value to be updated at loading screen.

tappedCell = "            "
redrawOverlay = false
factionID = 0 --composer.getVariable(factionID) used to be used in some spots, reverted that change.

requestedCells = ""

cellDataCache = {}

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
    local plusCode6 = currentPlusCode:sub(0,6)
    local plusCodeNoPlus = removePlus(currentPlusCode)

    if (lastPlusCode ~= currentPlusCode) then
        --Have this event handle all the DB updates for all game modes.
        --NOTE: this will require some extra logic for local debugging, since that previously was handled in game modes.
        --PaintTheTown: mark this as visited and update times for daily/weekly bonuses in grantPoints
        if(debugGPS) then print("calculating score") end
        lastScoreLog = "Earned " .. grantPoints(plusCodeNoPlus) .. " points from cell " .. plusCodeNoPlus

                --Scavenger Hunt: Mark this area as visited
                print("checking scavenger hunts")
        --print(1)        

        --test values
        -- local placeInfoList = GetPlacesInCell6("86HWHH")
        -- print(#placeInfoList)
        -- --print(dump(placeInfoList)) --should be a list of placeInfoIds
        -- for i, v in ipairs(placeInfoList) do
        --     local asdf = CalcPresent(41.56406, -81.43278, v)
        --     if (asdf) then
        --         print("AHAH")
        --         print("place present: " .. v[2])
        --         local cmd = 'UPDATE ScavengerHunts SET playerHasVisited = 1 WHERE description = "' .. v[2] .. '"'
        --         Exec(cmd)
        --     end
        --     local isPresent = CalcPresent(event.latitude, event.longitude, v)
        --     if (isPresent) then
        --         print("place present: " .. v[2])
        --     end
        -- end

        --Speedup check: get all non-trail areas to check distance on.
        local placeInfoList = GetPlacesInCell6(plusCode6)
        --print(2)
        --print(dump(placeInfoList)) --should be a list of placeInfoIds
        for i, v in ipairs(placeInfoList) do
            local asdf = CalcPresent(41.56406, -81.43278, v)
            print(asdf)
            local isPresent = CalcPresent(event.latitude, event.longitude, v)
            if (isPresent) then
                
                currentLocationName = v[2]
                local cmd = 'UPDATE ScavengerHunts SET playerHasVisited = 1 WHERE description = "' .. v[2] .. '"'
                Exec(cmd)
            end
        end

        --test check
        

        --print(3)
        -- now check for trails.
        local trail = GetTrail(plusCodeNoPlus)
        --print(4)
        if (#trail >= 1) then
            --check off the trail(s) from the scavenger hunt list
            for i,v in ipairs(trail) do
                local cmd = 'UPDATE ScavengerHunts SET playerHasVisited = 1 WHERE description = "' .. v[1] .. '"'
                Exec(cmd)
            end

        end

    
    print("done with scavenger hunt check")
        lastPlusCode = currentPlusCode
    end

    if(debugGPS) then print("Finished location event") end
    lastLocationEvent = event
end

function backListener(event)
    if (debug) then print("key listener hit") end
    if (event.keyName == "back" and event.phase == "up") then
        print("handling")
        local currentScene = composer.getSceneName("current")
        print(currentScene)
        if (currentScene == "SceneSelect") then return false end
        if (debug) then print("back to scene select") end
        local options = {effect = "flip", time = 125}
        composer.gotoScene("SceneSelect", options)
        print("handled")
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

print("shifting to loading scene")
composer.gotoScene("SceneSelect")
--composer.gotoScene("loadingScene")
--currentPlusCode = "87G8Q2JM+F9" --central park, simulator purposes --TODO remember to disable this for iOS app store submission, it confuses their testers.
--currentPlusCode = "86HWG94W+2Q" --CWRU, simulator purposes --TODO remember to disable this for iOS app store submission, it confuses their testers.
currentPlusCode = "86HWGGGJ+FR" --CWRU, simulator purposes --TODO remember to disable this for iOS app store submission, it confuses their testers.



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

local function FakeGpsEvent()
    
end

local function testDrift()
    if (os.time() % 2 == 0) then
        currentPlusCode = shiftCell(currentPlusCode, 1, 9) -- move north if 1, south if -1
    else
        currentPlusCode = shiftCell(currentPlusCode, -1, 10) -- move east if 1, west if -1
    end
end