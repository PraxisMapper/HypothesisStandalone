-- Paint The Town (single player)
-- Pending changes:
local composer = require("composer")
local scene = composer.newScene()

require("UIParts")
require("database")
-- require("dataTracker") -- replaced localNetwork for this scene
require("gameLogic")

-- -----------------------------------------------------------------------------------
-- Code outside of the scene event functions below will only be executed ONCE unless
-- the scene is removed entirely (not recycled) via "composer.removeScene()"
-- -----------------------------------------------------------------------------------

local bigGrid = true

local cellCollection = {} -- show cell area data/image tiles
local CellTapSensors = {} -- Not detecting taps in this mode. This is the highlight layer.
local ctsGroup = display.newGroup()
ctsGroup.x = -8
ctsGroup.y = 10

-- color codes
local unvisitedCell = {0, 0} -- completely transparent
local visitedCell = {.529, .807, .921, .4} -- sky blue, 50% transparent
local selectedCell = {.8, .2, .2, .4} -- red, 50% transparent

local timerResults = nil
local firstRun = true

local locationText = ""
local scoreText = ""
local directionArrow = ""
local debugText = {}
local locationName = ""
local timeText = ""
local personalScore = ""
local header = ""

local zoom = ""

local function testDrift()
    if (os.time() % 2 == 0) then
        currentPlusCode = shiftCell(currentPlusCode, 1, 9) -- move north if 1, south if -1
    else
        currentPlusCode = shiftCell(currentPlusCode, -1, 10) -- move east if 1, west if -1
    end
end

local function ToggleZoom()
    bigGrid = not bigGrid
    local sceneGroup = scene.view
    timer.pause(timerResults)

    for i = 1, #cellCollection do cellCollection[i]:removeSelf() end
    for i = 1, #CellTapSensors do CellTapSensors[i]:removeSelf() end

    cellCollection = {}
    CellTapSensors = {}

    if (bigGrid) then
        CreateRectangleGrid(3, 320, 400, sceneGroup, cellCollection) -- rectangular Cell11 grid with map tiles
        CreateRectangleGrid(61, 16, 20, ctsGroup, CellTapSensors, "painttown") -- rectangular Cell11 grid with a color fill
        ctsGroup.x = -8
        ctsGroup.y = 10
    else
        CreateRectangleGrid(7, 160, 200, sceneGroup, cellCollection) -- rectangular Cell11 grid with map tiles
        CreateRectangleGrid(140, 8, 10, ctsGroup, CellTapSensors, "painttown") -- rectangular Cell11 grid  with a color fill
        ctsGroup.x = -4
        ctsGroup.y = 5
    end
    -- Might be faster to set up a group for maptiles, then just push that group to the back and then the ctsGroup to back as well right after
    -- Move these to the back first, so that the map tiles will be behind them.
    for square = 1, #CellTapSensors do
        -- check each spot based on current cell, modified by gridX and gridY
        CellTapSensors[square]:toBack()
    end

    for square = 1, #cellCollection do
        -- check each spot based on current cell, modified by gridX and gridY
        cellCollection[square]:toBack()
    end

    reorderUI()
    forceRedraw = true
    timer.resume(timerResults)
end

local function GoToSceneSelect()
    local options = {effect = "flip", time = 125}
    composer.gotoScene("SceneSelect", options)
end

local function UpdateLocalOptimized()
    -- This now needs to be 2 loops, because the cell tables are different sizes.
    -- First loop for map tiles
    -- Then loop for touch event rectangles.
    if (debugLocal) then print("start UpdateLocalOptimized") end
    if (currentPlusCode == "") then

        if (debugLocal) then print("skipping, no location.") end
        print("NO_LOC")
        return
    end

    --print(1)
    if (debug) then debugText.text = dump(lastLocationEvent) end

    local plusCodeNoPlus = removePlus(currentPlusCode)
    if (timerResults ~= nil) then timer.pause(timerResults) end
    local innerForceRedraw = forceRedraw or firstRun or
                                 (currentPlusCode:sub(1, 8) ~=
                                     previousPlusCode:sub(1, 8))
    firstRun = false
    forceRedraw = false
    if currentPlusCode ~= previousPlusCode then
        -- TODO: find a way to only update the square the arrow is in instead of redrawing all of them.
        innerForceRedraw = true
    end
    previousPlusCode = currentPlusCode
    --print(2)

    -- draw this place's name on screen, or an empty string if its not a place.
    -- TODO: this no longer needs TerrainData, this should get set by the location handler and read here.
    -- local terrainInfo = LoadTerrainData(plusCodeNoPlus:sub(codeTrim + 1, 10)) -- terrainInfo is a whole row from the DB.
    -- print(1)
    -- locationName.text = terrainInfo[5] --name
    -- if locationName.text == "" then
    --     locationName.text = terrainInfo[6] --area type name
    -- end
    locationName.text = currentLocationName

    if (innerForceRedraw == false) then -- none of this needs to get processed if we haven't moved and there's no new maptiles to refresh.
        for square = 1, #cellCollection do
            -- check each spot based on current cell, modified by gridX and gridY
            local thisSquaresPluscode = currentPlusCode
            thisSquaresPluscode = shiftCell(thisSquaresPluscode,
                                            cellCollection[square].gridX, 8)
            thisSquaresPluscode = shiftCell(thisSquaresPluscode,
                                            cellCollection[square].gridY, 7)
            cellCollection[square].pluscode = thisSquaresPluscode
            plusCodeNoPlus = removePlus(thisSquaresPluscode):sub(1, 8)
            plusCodeSix = plusCodeNoPlus:sub(1, 6)
            plusCodeTwo = plusCodeNoPlus:sub(7, 8)
            cellCollection[square].fill = {0, 0} -- required to make Solar2d actually update the texture.
            local paint = {
                type = "image",
                -- filename = "Tiles/" ..plusCodeNoPlus .. ".pngTile",
                filename = "Tiles/" .. plusCodeSix .. "/" .. plusCodeTwo ..
                    ".pngTile", -- TODO: does fixing this slash from \\ to / make tiles work on android?
                baseDir = system.ResourceDirectory
            }
            cellCollection[square].fill = paint

        end
    end
    -- print(5)

    if (debug) then print("done with map cells") end
    -- Step 2: set up event listener grid. These need Cell10s
    -- If there was a good way to shortcut this, and only update the cell the arrow is currently in, that would be a good optimization
    -- (always update the cell the arrow is in, skip the others unless innerForceRedraw is true)
    local baselinePlusCode = currentPlusCode:sub(1, 8) .. "+FF"
    if (innerForceRedraw) then -- Also no need to do all of this unless we shifted our Cell8 location.
        for square = 1, #CellTapSensors do
            CellTapSensors[square].fill = {0, 0.01} -- this needs to be some value or else the cells dont get created/register taps correctly.
            local thisSquaresPluscode = baselinePlusCode
            local shiftChar7 = math.floor(CellTapSensors[square].gridY / 20)
            local shiftChar8 = math.floor(CellTapSensors[square].gridX / 20)
            local shiftChar9 = math.floor(CellTapSensors[square].gridY % 20)
            local shiftChar10 = math.floor(CellTapSensors[square].gridX % 20)
            thisSquaresPluscode = shiftCell(thisSquaresPluscode, shiftChar7, 7)
            thisSquaresPluscode = shiftCell(thisSquaresPluscode, shiftChar8, 8)
            thisSquaresPluscode = shiftCell(thisSquaresPluscode, shiftChar9, 9)
            thisSquaresPluscode = shiftCell(thisSquaresPluscode, shiftChar10, 10)
            local idCheck = removePlus(thisSquaresPluscode)

            CellTapSensors[square].pluscode = thisSquaresPluscode
            if (VisitedCell(idCheck)) then
                CellTapSensors[square].fill = visitedCell
            end

            local debugTrails = false
            if (debugTrails) then
                trail = GetTrail(idCheck:sub(commonStartLetters:len()+1))
                if (#trail > 0) then
                    CellTapSensors[square].fill = {.5, .2, .2, .6}
                end
            end

        end
    end

    if (timerResults ~= nil) then timer.resume(timerResults) end
    if (debugLocal) then print("grid done or skipped") end
    locationText.text = "Current location:" .. currentPlusCode
    timeText.text = "Current time:" .. os.date("%X")

    if (debugSpin) then
        directionArrow.rotation = directionArrow.rotation + 10
        if (directionArrow.rotation > 360) then
            directionArrow.rotation = 0
        end
    else
        directionArrow.rotation = currentHeading
    end

    -- 11 and 10 here seem to get me aligned on the center square. 
    local shift = CODE_ALPHABET_:find(currentPlusCode:sub(11, 11)) - 11
    local shift2 = CODE_ALPHABET_:find(currentPlusCode:sub(10, 10)) - 10
    if (bigGrid) then
        directionArrow.x = display.contentCenterX + (shift * 16) + 8
        directionArrow.y = display.contentCenterY - (shift2 * 20) + 10
    else -- these were 4 and 5 respectively, but these cells are 8x10 px.
        directionArrow.x = display.contentCenterX + (shift * 8) + 4
        directionArrow.y = display.contentCenterY - (shift2 * 10) + 5
    end

    personalScore.text = "Paint The Town Score: " .. AllTimePoints()

    if (debugLocal) then print("end updateLocalOptimized") end
end

-- -----------------------------------------------------------------------------------
-- Scene event functions
-- -----------------------------------------------------------------------------------

function scene:create(event)

    if (debug) then print("creating painttown scene") end
    local sceneGroup = self.view
    -- Code here runs when the scene is first created but has not yet appeared on screen

    sceneGroup:insert(ctsGroup)

    locationText = display.newText(sceneGroup,
                                   "Current location:" .. currentPlusCode,
                                   display.contentCenterX, 160, native.systemFont, 20)
    timeText = display.newText(sceneGroup, "Current time:" .. os.date("%X"),
                               display.contentCenterX, 180, native.systemFont, 20)
    personalScore = display.newText(sceneGroup, "Paint The Town Score: ",
                                    display.contentCenterX, 200, native.systemFont, 20)
    locationName = display.newText(sceneGroup, "", display.contentCenterX, 220,
                                   native.systemFont, 20)

    header = display.newImageRect(sceneGroup, "themables/PaintTown.png", 300, 100)
    header.x = display.contentCenterX
    header.y = 80
    header:addEventListener("tap", GoToSceneSelect)
    header:toFront()

    CreateRectangleGrid(3, 320, 400, sceneGroup, cellCollection) -- rectangular Cell11 grid with map tiles
    CreateRectangleGrid(60, 16, 20, ctsGroup, CellTapSensors, "painttown") -- rectangular Cell11 grid  with color fill

    directionArrow = display.newImageRect(sceneGroup, "themables/arrow1.png", 16, 20)
    directionArrow.x = display.contentCenterX
    directionArrow.y = display.contentCenterY
    directionArrow.anchorX = .5 -- 0 looks right on BigGrid= true. .5 looks better on BigGrid = false.
    directionArrow.anchorY = .5
    directionArrow:toFront()

    zoom = display.newImageRect(sceneGroup, "themables/ToggleZoom.png", 100, 100)
    zoom.anchorX = 0
    zoom.x = 50
    zoom.y = 80
    zoom:addEventListener("tap", ToggleZoom)
    zoom:toFront()

    reorderUI()

    -- if (debug) then
    --     debugText = display.newText(sceneGroup, "location data",
    --                                 display.contentCenterX, 1180, 600, 0,
    --                                 native.systemFont, 22)
    --     debugText:toFront()
    -- end

    if (debug) then print("created PaintTown scene") end
end

function reorderUI()

    ctsGroup:toFront() -- these must go over the map tiles, and then everything else sits on these.
    -- header:toFront()
    zoom:toFront()

    locationText:toFront()
    timeText:toFront()
    directionArrow:toFront()
    locationName:toFront()
    personalScore:toFront()
    header:toFront()
end

function scene:show(event)
    if (debug) then print("showing painttown scene") end
    local sceneGroup = self.view
    local phase = event.phase

    if (phase == "will") then
        -- Code here runs when the scene is still off screen (but is about to come on screen)
        firstRun = true
    elseif (phase == "did") then
        -- Code here runs when the scene is entirely on screen 
        timerResults = timer.performWithDelay(800, UpdateLocalOptimized, -1)
        if (debugGPS) then timer.performWithDelay(500, testDrift, -1) end
        reorderUI()
    end
    if (debug) then print("showed painttown scene") end
end

function scene:hide(event)
    if (debug) then print("hiding painttown scene") end
    local sceneGroup = self.view
    local phase = event.phase

    if (phase == "will") then
        timer.cancel(timerResults)
        timerResults = nil
    elseif (phase == "did") then
        -- Code here runs immediately after the scene goes entirely off screen
    end
end

function scene:destroy(event)
    if (debug) then print("destroying painttown scene") end

    local sceneGroup = self.view
    -- Code here runs prior to the removal of scene's view
end

-- -----------------------------------------------------------------------------------
-- Scene event function listeners
-- -----------------------------------------------------------------------------------
scene:addEventListener("create", scene)
scene:addEventListener("show", scene)
scene:addEventListener("hide", scene)
scene:addEventListener("destroy", scene)
-- -----------------------------------------------------------------------------------

return scene
