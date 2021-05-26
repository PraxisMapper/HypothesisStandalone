-- the class for handling sending data to/from the API server
-- NOTE: naming this 'network' overrides the internal Solar2d library with the same name and breaks everything.
local composer = require("composer")
require("database")
require("helpers") --for Split

--This app isn't open source, i can hardcode this to my aws server.
--serverURL = "https://us.praxismapper.org/" --OFFICIAL domain name WOOOOO! And with SSL!
--serverURL = "http://ec2-3-138-184-251.us-east-2.compute.amazonaws.com/" --AWS Test server, IP part of address will change each time instance is launched.
serverURL = "http://192.168.50.247/PraxisMapper/" --Localhost test.

function plusCode8Listener(event)
    if (debug) then print("plus code 8 event started") end
    if event.status == 200 then netUp() else netDown() end
    if (event.status ~= 200) then return end --dont' save invalid results on an error.

    --This one splits each cell10 via newline.
    local resultsTable = Split(event.response, "\r\n") --windows newlines
    --Format:
    --line1: the cell8 requested
    --remaining lines: the last 2 digits for a cell10=name|type
    --EX: 48=Local Park|park

    db:exec("BEGIN TRANSACTION") --transactions for multiple inserts are a huge performance boost.
    local plusCode6 = resultsTable[1] 
    for i = 2, #resultsTable do
        if (resultsTable[i] ~= nil and resultsTable[i] ~= "") then 
            local data = Split(resultsTable[i], "|") --3 data parts in order
            data[2] = string.gsub(data[2], "'", "''")--escape data[2] to allow ' in name of places.
            insertString = "INSERT INTO terrainData (plusCode, name, areatype, MapDataId) VALUES ('" .. resultsTable[1] .. data[1] .. "', '" .. data[2] .. "', '" .. data[3] .. "', '" .. data[4] .. "');" --insertString .. 
            local results = db:exec(insertString)
        end
    end
    local e2 = db:exec("END TRANSACTION")
    if(debugNetwork) then print("table done") end

    --save these results to the DB.
    local updateCmd = "INSERT INTO dataDownloaded (pluscode8, downloadedOn) VALUES ('" .. plusCode6 .. "', " .. os.time() .. ")"
    Exec(updateCmd)
    requestedCells = requestedCells:gsub(plusCode6 .. ",", "")

    netUp()
end

function GetCell8Data(code8)
    local cellAlreadyRequested = string.find(requestedCells, code8 .. ",")
    if (cellAlreadyRequested ~= nil) then 
        return 
    end
    if debugNetwork then print("network: getting 8 cell data " .. code8) end
    requestedCells = requestedCells .. code8 .. ","
    if (debugNetwork) then print ("getting cell data via " .. serverURL .. "MapData/LearnCell8/" .. code8) end
    network.request(serverURL .. "MapData/LearnCell8/" .. code8, "GET", plusCode8Listener)
    netTransfer()
end

function GetCell8Image10(plusCode8)
    netTransfer()
    if (debugNetwork) then print ("getting cell image data via " .. serverURL .. "MapData/DrawCell8/" .. plusCode8) end
    local params = { response = { filename = plusCode8 .. "-10.png", baseDirectory = system.CachesDirectory}}
    network.request(serverURL .. "MapData/DrawCell8/" .. plusCode8, "GET", image810Listener, params)
end

function GetCell8Image11(plusCode8)
    netTransfer()
    local params = {}
    params.response  = {filename = plusCode8 .. "-11.png", baseDirectory = system.CachesDirectory}
    network.request(serverURL .. "MapData/DrawCell8Highres/" .. plusCode8, "GET", image811Listener, params)
end

function GetCell10Image11(plusCode)
    netTransfer()
    local params = {}
    params.response  = {filename = plusCode .. "-11.png", baseDirectory = system.CachesDirectory}
    network.request(serverURL .. "MapData/DrawCell10Highres/" .. plusCode, "GET", image1011Listener, params)
end

function image810Listener(event)
    forceRedraw = true
    if event.status == 200 then netUp() else netDown() end
end

function image811Listener(event)
    forceRedraw = true
    if event.status == 200 then 
        netUp() 
    else 
        netDown() 
        native.showAlert("netError", event.status)
    end
end

function image1011Listener(event)
    forceRedraw = true
    if event.status == 200 then netUp() else netDown() end
end

gettingTeam = false

function GetTeamAssignment()
    if (gettingTeam == true) then return end
    gettingTeam = true
    local url = serverURL .. "PlayerContent/AssignTeam/"  .. system.getInfo("deviceID")
    if (debug) then print("Team request sent to " .. url) end
    network.request(url, "GET", GetTeamAssignmentListener)
    netTransfer()
end

function GetTeamAssignmentListener(event)
    if (debug) then 
        print("Team listener fired") 
        print(event.status)
    end
    if event.status == 200 then
        factionID = tonumber(event.response)
        netUp()
    else
        netDown()
        print("team assignment failed")
        print(event.response)
    end
    gettingTeam = false
    if (debug) then print("Team Assignment done") end
end

function SetTeamAssignment(teamId)
    local url = serverURL .. "PlayerContent/SetTeam/"  .. system.getInfo("deviceID") .. "/" .. teamId
    network.request(url, "GET", GetTeamAssignmentListener) --recycled, since the results are the same.
    if (debug) then print("Team change sent to " .. url) end
    netTransfer()
end

function GetCurrentScoreboardNumber(instanceID)
    local url = serverURL .. "PaintTown/GetEndDate/"  .. instanceID
    network.request(url, "GET", currentScoreboardNumberListener) --recycled, since the results are the same.
    if (debug) then print("Checking if weekly scores needs reset at " .. url) end
    netTransfer()
end

function currentScoreboardNumberListener(event)
    if (debug) then 
        print("SB number listener fired") 
        print(event.status)
    end
    if event.status == 200 then
        netUp()
        print(event.response)
        if (event.response ~= GetEndDate(1)) then --hard coded to my weekly instance.
            SetEndDate(1, event.response)
            ResetDailyWeekly(1)
        end
    else
        netDown()
        print("SB id failed")
        print(event.response)
    end
    gettingTeam = false
    if (debug) then print("sb id done") end
end