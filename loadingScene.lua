--This is the scene that appears after the splash screen, and sets up everything the game needs to run correcly
--overlayDL is the pop-up for downloading new data.

--a lot of functions are localized to this scene, rather than being shared.
local composer = require( "composer" )
local scene = composer.newScene()

require("database")
--require("localNetwork")

-- -----------------------------------------------------------------------------------
-- Code outside of the scene event functions below will only be executed ONCE unless
-- the scene is removed entirely (not recycled) via "composer.removeScene()"
-- -----------------------------------------------------------------------------------
 
 local statusText = "" --displayText object for info
 imagecount = 0; --pending responses on map tiles.

 local lat = 0
 local lon = 0

 local function startGame()
    statusText.text = "Opening Game..."
    composer.gotoScene("PaintTownScene")
 end

 local function PingServer()
    network.request(serverURL .. "Admin/Test", "GET", testListener)
 end

 function testListener(event)
    if (event.status == 200) then
        statusText.text = "Requesting Team Id and starting game"
        if (debug) then print("server is up and answered") end
        GetTeamAssignment()
        GetCurrentScoreboardNumber(1) --hardcoded to the weekly setup on my server.
        startGame()
    else
        statusText.text = "Server connection failed. Retrying...."
        PingServer()
    end
 end



--  function loadingGpsListener(event)
--     local eventL = event

--     if (debugGPS) then
--         print("got GPS event")
--         if (eventL.errorCode ~= nil) then
--             print("GPS Error " .. eventL.errorCode)
--             return
--         end

--         print("Coords " .. eventL.latitude .. " " ..eventL.longitude)
--     end

--     lat = eventL.latitude
--     lon = eventL.longitude
--     local pluscode = encodeLatLon(eventL.latitude, eventL.longitude, 10); --only goes to 10 right now.
--     if (debugGPS) then print ("Plus Code: " .. pluscode) end
--     currentPlusCode = pluscode

--     --Debug/testing override location
    
--        --More complicated, problematic entries: (Pending possible fix for loading data missing from a file)
--        --currentPlusCode ="8FW4V75V+8R" --Eiffel Tower. ~60,000 entries.
--        --currentPlusCode = "376QRVF4+MP" --Antartic SPOI
--        --currentPlusCode = "85872779+F4" --Hoover Dam Lookout
--        --currentPlusCode = "85PFF56C+5P" --Old Faithful 
       
        --currentPlusCode = "87G8Q2JM+F9" --central park, simulator purposes
        currentPlusCode = "86HWG94W+2Q" --CWRU
-- end
 
 
-- -----------------------------------------------------------------------------------
-- Scene event functions
-- -----------------------------------------------------------------------------------
 
-- create()
function scene:create( event )
 
    local sceneGroup = self.view
    print("creating loading scene")
    -- Code here runs when the scene is first created but has not yet appeared on screen
    --Draw a background image, fullscreen 720x1280
    --will draw text over that.

    local loadingBg = display.newImageRect(sceneGroup, "themables/LoadingScreen.png", 720, 1280)
    loadingBg.anchorX = 0
    loadingBg.anchorY = 0

    statusText = display.newText(sceneGroup, "Loading....", display.contentCenterX, 260, native.systemFont, 30)
    statusText:setFillColor(.2, .2, .2)
    print("loading scene created")
end
 
 
-- show()
function scene:show( event )
    local sceneGroup = self.view
    local phase = event.phase
 
    if ( phase == "will" ) then
        -- Code here runs when the scene is still off screen (but is about to come on screen)
        --Runtime:addEventListener("location", loadingGpsListener)
 
    elseif ( phase == "did" ) then
        -- Code here runs when the scene is entirely on screen
        --Do some database stuff, display progress on screen
        print("loading scene on screen")

        --Database setup is done in main.lua, since it's a very early step everything else depends on
        -- statusText.text = "Database Check"
        -- local localPath = system.pathForFile("userData.sqlite", system.DocumentsDirectory) 
        -- print(localPath)
        -- if (not doesFileExist(localPath)) then
        -- --if (not doesFileExist("userData.sqlite", system.DocumentsDirectory)) then
        --     print("copying user database")
        --     copyFile("userData.sqlite", system.ResourceDirectory, "userData.sqlite", system.DocumentsDirectory, false)
        -- end

        -- local dataPath = system.pathForFile("database.sqlite", system.ResourceDirectory)
        -- print(dataPath)
        -- if (not doesFileExist(dataPath)) then   
        --     print("Fix database path!")
        -- end


        --startDatabase()
        --statusText.text = "Database Opened"
        --print("database started")

        local currentDbVersion = 1; 

        

        --TODO: clear out a bunch of this DB stuff, PTT doesn't use much there.
        -- local tablesetup =
        -- [[CREATE TABLE IF NOT EXISTS plusCodesVisited(id INTEGER PRIMARY KEY, pluscode, lat, long, firstVisitedOn, lastVisitedOn, totalVisits, eightCode);
        -- CREATE TABLE IF NOT EXISTS playerData(id INTEGER PRIMARY KEY, factionID, totalPoints);
        -- CREATE TABLE IF NOT EXISTS systemData(id INTEGER PRIMARY KEY, dbVersionID, serverAddress);
        -- CREATE TABLE IF NOT EXISTS weeklyVisited(id INTEGER PRIMARY KEY, pluscode, VisitedOn);
        -- CREATE TABLE IF NOT EXISTS dailyVisited(id INTEGER PRIMARY KEY, pluscode, VisitedOn);
        -- CREATE TABLE IF NOT EXISTS terrainData (id INTEGER PRIMARY KEY, pluscode UNIQUE, name, areatype, lastUpdated, MapDataId);
        -- CREATE INDEX IF NOT EXISTS terrainIndex on terrainData(pluscode);
        -- CREATE TABLE IF NOT EXISTS dataDownloaded(id INTEGER PRIMARY KEY, pluscode8, downloadedOn);
        -- CREATE TABLE IF NOT EXISTS areasOwned(id INTEGER PRIMARY KEY, mapDataId, name, points);
        -- CREATE INDEX IF NOT EXISTS indexPCodes on plusCodesVisited(pluscode);
        -- CREATE INDEX IF NOT EXISTS indexEightCodes on plusCodesVisited(eightCode);
        -- CREATE INDEX IF NOT EXISTS indexOwnedMapIds on areasOwned(mapDataId);
        -- CREATE TABLE IF NOT EXISTS weeklyPoints (id INTEGER PRIMARY KEY, score, instanceID);
        -- CREATE TABLE IF NOT EXISTS allTimePoints (id INTEGER PRIMARY KEY, score);
        -- CREATE TABLE IF NOT EXISTS endDates (id INTEGER PRIMARY KEY, instanceID, endsAt);

        -- INSERT OR IGNORE INTO systemData(id, dbVersionID, serverAddress) values (1, ]] .. currentDbVersion .. [[, '');
        -- INSERT OR IGNORE INTO playerData(id, factionID, totalPoints) values (1, 0, 0);
        -- INSERT OR IGNORE INTO weeklyPoints(id, score, instanceID) values (1, 0, 0);
        -- INSERT OR IGNORE INTO allTimePoints(id, score) values (1, 0);
        -- INSERT OR IGNORE INTO endDates(id, instanceID, endsAt) values (1, 1, "asdf");
        -- ]]
        
        statusText.text = "Database Opened "  .. sqlite3.version() --3.19 on android and simulator.
        if (debug) then 
            print("SQLite version " .. sqlite3.version())
        end
        --local setupResults = Exec(tablesetup)
        --if (debug) then print("setup done " .. setupResults) end
        --statusText.text = "setup done " .. setupResults
        --if (setupResults > 0) then
            --print(db:errmsg())
            --statusText = db:errmsg()
        --end
        
        --statusText.text = "Database Exists : " .. setupResults
        --if (setupResults ~= 0) then return end
        --statusText.text = "Database Exists!"

        --upgrading database now, clearing data on android apparently doesn't reset table structure.
        --upgradeDatabaseVersion(currentDbVersion) 

        statusText.text = "Checking server..."
        --PingServer()



        --statusText.text = "Requesting Team Id"
        --GetTeamAssignment()        
        
        statusText.text = "Starting Game"
        startGame()
    end
end
 
-- hide()
function scene:hide( event )
    local sceneGroup = self.view
    local phase = event.phase
 
    if ( phase == "will" ) then
        -- Code here runs when the scene is on screen (but is about to go off screen)
        print("loadingScene hiding")
    elseif ( phase == "did" ) then
        -- Code here runs immediately after the scene goes entirely off screen
        --Runtime:removeEventListener("location", loadingGpsListener) --the local one
        --Runtime:addEventListener("location", gpsListener) --the one in main.lua
        print("loadingScene hidden, GPS on.")
    end
end
  
function scene:destroy( event )
    local sceneGroup = self.view
    -- Code here runs prior to the removal of scene's view
end
 
-- -----------------------------------------------------------------------------------
-- Scene event function listeners
-- -----------------------------------------------------------------------------------
scene:addEventListener( "create", scene )
scene:addEventListener( "show", scene )
scene:addEventListener( "hide", scene )
scene:addEventListener( "destroy", scene )
-- -----------------------------------------------------------------------------------
 
return scene