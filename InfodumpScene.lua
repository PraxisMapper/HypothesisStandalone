local composer = require( "composer" )

require("helpers")
require("database")
local scene = composer.newScene()
 
-- -----------------------------------------------------------------------------------
-- Code outside of the scene event functions below will only be executed ONCE unless
-- the scene is removed entirely (not recycled) via "composer.removeScene()"
-- -----------------------------------------------------------------------------------

 local header = ''
 local locationDump = ''
 local areaDump = ''
 local currentPlaces = ''
 local keepLooping = false

 local function GoToSceneSelect()
    local options = {effect = "flip", time = 125}
    composer.gotoScene("SceneSelect", options)
end

function updateInfo()
        --  local query = "SELECT * FROM PlaceInfo2s WHERE ID = 1155"
        -- local results = Query(query)
        -- areaDump.text = dump(results[1])

        locationDump.text = dump(lastLocationEvent)
        local placesIn = ""

        --print(currentPlusCode)
        --print(1)
        local placeInfoList = GetPlacesInCell6(currentPlusCode:sub(0,6))
        for i, v in ipairs(placeInfoList) do
            --print(dump(v))
            local isPresent = CalcPresentRect(lastLocationEvent.latitude, lastLocationEvent.longitude, v)
            if (isPresent) then
                placesIn = placesIn .. ", " .. v[2]
            end
        end
        --print(placesIn)
        --print(2)

        local trails = GetTrail(removePlus(currentPlusCode):sub(commonStartLetters:len()+1))
        if (#trails) > 0 then
            for i,v in ipairs(trail) do
                placesIn = placesIn .. "," .. v[1]
            end
        end

        currentPlaces.text = "Currently in: " .. placesIn
        if (debug) then print("updated info") end
        --if keepLooping then
            --timerResults = timer.performWithDelay(200, updateInfo, -1)
        --end
end
 
-- -----------------------------------------------------------------------------------
-- Scene event functions
-- -----------------------------------------------------------------------------------
 
-- create()
function scene:create( event )
 
    if (debug) then print("creating infodump scene") end
    local sceneGroup = self.view

    header = display.newImageRect(sceneGroup, "themables/Infodump.png", 300, 100)
    header.x = display.contentCenterX
    header.y = 80
    header:addEventListener("tap", GoToSceneSelect)
    header:toFront()

    locationDump = display.newText(sceneGroup, "location:", 50, 200, 600, 600, native.systemFont, 25)
    locationDump.anchorX = 0
    locationDump.anchorY = 0

    -- areaDump = display.newText(sceneGroup, "areaInfo: ", 50, 500, 600, 600, native.systemFont, 25)
    -- areaDump.anchorX = 0
    -- areaDump.anchorY = 0

    currentPlaces = display.newText(sceneGroup, "Currently in:", 50, 800, 600, 600, native.systemFont, 25)
    currentPlaces.anchorX = 0
    currentPlaces.anchorY = 0

    keepLooping = true

end
 
 
-- show()
function scene:show( event )
 
    local sceneGroup = self.view
    local phase = event.phase
 
    if ( phase == "will" ) then
        -- Code here runs when the scene is still off screen (but is about to come on screen)
 
    elseif ( phase == "did" ) then
        -- Code here runs when the scene is entirely on screen
        timerResults = timer.performWithDelay(200, updateInfo, -1)       
    end
end
 
 
-- hide()
function scene:hide( event )
 
    local sceneGroup = self.view
    local phase = event.phase
 
    if ( phase == "will" ) then
        -- Code here runs when the scene is on screen (but is about to go off screen)
 
    elseif ( phase == "did" ) then
        -- Code here runs immediately after the scene goes entirely off screen
        timer.pause(timerResults)
 
    end
end
 
 
-- destroy()
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