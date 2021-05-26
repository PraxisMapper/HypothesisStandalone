local composer = require("composer")
local scene = composer.newScene()

require("database")

local widget = require("widget")

-- -----------------------------------------------------------------------------------
-- Code outside of the scene event functions below will only be executed ONCE unless
-- the scene is removed entirely (not recycled) via "composer.removeScene()"
-- -----------------------------------------------------------------------------------
local tabBar = ""
local header = ""

local function GoToSceneSelect()
    local options = {effect = "flip", time = 125}
    composer.gotoScene("SceneSelect", options)
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
    local tabSql = "SELECT DISTINCT listname FROM ScavengerHunts ORDER BY listname"
    print(1)

    local results = Query(tabSql)
    print(2)
    print(dump(results))
    print(#results)
    local Tbuttons = {}
    for i, r in ipairs(results) do
        local btnConfig = {label = r[1], size = 14}
        table.insert(Tbuttons, btnConfig)
    end

    print(3)
    local options = {buttons = Tbuttons, left = 0, top = 150}
    tabBar = widget.newTabBar(options)
    sceneGroup:insert(tabBar)
    print(4)

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
