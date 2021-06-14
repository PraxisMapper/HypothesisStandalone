local composer = require("composer")
local scene = composer.newScene()

require("database")
require("helpers")

local widget = require("widget")

local thingsOnScreen = {}

-- -----------------------------------------------------------------------------------
-- Code outside of the scene event functions below will only be executed ONCE unless
-- the scene is removed entirely (not recycled) via "composer.removeScene()"
-- -----------------------------------------------------------------------------------
local tabBar = ""
local header = ""
local scrollView = ""

local function GoToSceneSelect()
    local options = {effect = "flip", time = 125}
    composer.gotoScene("SceneSelect", options)
end

local function innerTabPressed(event)
    --Remove any existing items.
    for i,v in ipairs(thingsOnScreen) do
        scrollView:remove(v)
    end
    thingsOnScreen = {}

    local query = "SELECT * FROM ScavengerHunts WHERE listName = '" .. event.target.id .. "' ORDER BY playerHasVisited DESC, description "
    --print(query)
    local results = Query(query)

    for i,s in ipairs(results) do
        --print(dump(s))
        local textEntry = display.newText(scrollView, s[3], 25, i * 50, native.systemFont, 35)
        textEntry.anchorX = 0
        if (s[4] == 1) then
            textEntry:setFillColor(0, .7, 0)
        else
            textEntry:setFillColor(.7, 0, 0)
        end
        --print("A")
        thingsOnScreen[i] = textEntry
        --print("B")
        scrollView:insert(textEntry)
    end

    scrollView:scrollTo("top", {time = 0})

     
end
-- -----------------------------------------------------------------------------------
-- Scene event functions
-- -----------------------------------------------------------------------------------

-- create()
function scene:create(event)

    local sceneGroup = self.view

    header = display.newImageRect(sceneGroup, "themables/ScavengerHunts.png", 300, 100)
    header.x = display.contentCenterX
    header.y = 80
    header:addEventListener("tap", GoToSceneSelect)
    header:toFront()


    -- Code here runs when the scene is first created but has not yet appeared on screen
    local tabSql = "SELECT DISTINCT listname FROM ScavengerHunts ORDER BY playerHasVisited, listname"

    local results = Query(tabSql)

    local Tbuttons = {}
    for i, r in ipairs(results) do
        local btnConfig = {label = r[1], id = r[1], size = 14, onPress = innerTabPressed}
        table.insert(Tbuttons, btnConfig)
    end

    local options = {buttons = Tbuttons, left = 0, top = 150}
    tabBar = widget.newTabBar(options)
    sceneGroup:insert(tabBar)

    scrollView = widget.newScrollView(
        {
            top = 200,
            left = 0, 
            width = 720,
            height = 1080,
            backgroundColor = {.1, .1, .1}
        }
    )

    sceneGroup:insert(scrollView)

end 

-- show()
function scene:show(event)

    local sceneGroup = self.view
    local phase = event.phase

    if (phase == "will") then
        -- Code here runs when the scene is still off screen (but is about to come on screen)

    elseif (phase == "did") then
        -- Code here runs when the scene is entirely on screen

    end
end

-- hide()
function scene:hide(event)

    local sceneGroup = self.view
    local phase = event.phase

    if (phase == "will") then
        -- Code here runs when the scene is on screen (but is about to go off screen)

    elseif (phase == "did") then
        -- Code here runs immediately after the scene goes entirely off screen

    end
end

-- destroy()
function scene:destroy(event)

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
