--a single shared file for specifically handling downloading map tiles and cell data
--This is an attempt to make updating a bigger grid faster, such as the 35x35 area control map.
--by minimizing duplicate work/network calls/etc.

--Lots of this is unnecessary now.

require("localNetwork") --for serverURL.

--this process:
--these tables have a string key for each relevant cell
--key present: this cell has been requested this session
--key absent: this cell has not been requested this session
--0 value: request sent
--1 value: data present (either request completed earlier or data was already present)
-- -1 value: last request failed.
requestedDataCells = {} --these should be Cell8
requestedMapTileCells = {} --these should be Cell10
requestedMPMapTileCells = {} --these should be Cell10, separate because they can change quickly.
requestedPaintTownCells = {} --THe list of Cell10s and the team that owns them.
PaintTownInstanceIDs ={} --list of int ids.
DownloadedCell8sThisSession = {} --All the cell 8s we've pulled from the server so far.
PTCellsInProcessing = {} --Stuff currently waiting on a network request to complete.


function GetMapData8(Cell8) -- the terrain type call.
    local status = requestedDataCells[Cell8] --this can occasionally be nil if there's multiple active calls that return out of order on the first update
     if (status == nil) then --first time requesting this cell this session.
        local dataPresent = DownloadedCell8(Cell8)
        if (dataPresent == true) then --use local data.
            requestedDataCells[Cell8] = 1
            return
        end
        requestedDataCells[Cell8] = 0
        GetCell8TerrainData(Cell8)
     end

     if (status == -1) then --retry a failed download.
        requestedDataCells[Cell8] = 0
        GetCell8TerrainData(Cell8)
     end
end

function GetMapTile10(Cell10)
    if (requestedMapTileCells[cell10] == 1) then
        --We already have this tile.
        return
    end
    local status = requestedMapTileCells[Cell10] --this can occasionally be nil if there's multiple active calls that return out of order on the first update
     if (status == nil) then --first time requesting this cell this session.
        local dataPresent = doesFileExist(Cell10 .. "-11.png", system.CachesDirectory)
        if (dataPresent == true) then --use local data.
            requestedMapTileCells[Cell10] = 1
            return
        end
        requestedMapTileCells[Cell10] = 0
        TrackerGetCell10Image11(Cell10)
     end

     if (status == -1) then --retry a failed download.
        requestedMapTileCells[Cell10] = 0
        TrackerGetCell10Image11(Cell10)
     end
end

function GetMapTile8(Cell8)
    if (debugNetwork) then print("getting map tile for " .. Cell8) end
    if (requestedMapTileCells[cell8] == 1) then
        --We already have this tile.
        return
    end
    local status = requestedMapTileCells[Cell8] --this can occasionally be nil if there's multiple active calls that return out of order on the first update
     if (status == nil) then --first time requesting this cell this session.
        local dataPresent = doesFileExist(Cell8 .. "-11.png", system.CachesDirectory)
        if (dataPresent == true) then --use local data.
            requestedMapTileCells[Cell8] = 1
            return
        end
        requestedMapTileCells[Cell8] = 0
        TrackerGetCell8Image11(Cell8)
     end

     if (status == -1) then --retry a failed download.
        requestedMapTileCells[Cell8] = 0
        TrackerGetCell8Image11(Cell8)
     end
end

function GetCell8TerrainData(code8)
    if debugNetwork then 
        print("network: getting 8 cell data " .. code8) 
        print ("getting cell data via " .. serverURL .. "MapData/LearnCell8/" .. code8) 
    end
    network.request(serverURL .. "MapData/LearnCell8/" .. code8 , "GET", TrackplusCode8Listener)
    netTransfer()
end

function TrackplusCode8Listener(event)
    if (debug) then print("plus code 8 event started") end
    if event.status == 200 then 
        netUp() 
    else 
        print("pluscode 8 track listener failed")
        netDown() 
    end
    if (event.status ~= 200) then return end --dont' save invalid results on an error.

    --This one splits each Cell10 via newline.
    local resultsTable = Split(event.response, "\r\n") --windows newlines
    --Format:
    --line1: the Cell8 requested
    --remaining lines: the last 2 digits in the cell10=name|typeID|mapDataID
    --EX: 48=Local Park|4|1234

    db:exec("BEGIN TRANSACTION") --transactions for multiple inserts are a huge performance boost.
    local plusCode8 = resultsTable[1] 
    for i = 2, #resultsTable do
        if (resultsTable[i] ~= nil and resultsTable[i] ~= "") then 
            local data = Split(resultsTable[i], "|") --4 data parts in order
            data[2] = string.gsub(data[2], "'", "''")--escape data[2] to allow ' in name of places.
            insertString = "INSERT INTO terrainData (plusCode, name, areatype, MapDataId) VALUES ('" .. resultsTable[1] .. data[1] .. "', '" .. data[2] .. "', '" .. data[3] .. "', '" .. data[4] .. "');" 
            local results = db:exec(insertString)
        end
    end
    local e2 = db:exec("END TRANSACTION")
    --save these results to the DB.
    local updateCmd = "INSERT INTO dataDownloaded (pluscode8, downloadedOn) VALUES ('" .. plusCode8 .. "', " .. os.time() .. ")"
    Exec(updateCmd)
    requestedDataCells[plusCode8] = 1
    forceRedraw = true
end

function TrackerGetCell10Image11(plusCode)
    netTransfer()
    local params = {}
    params.response  = {filename = plusCode .. "-11.png", baseDirectory = system.CachesDirectory}
    network.request(serverURL .. "MapData/DrawCell10Highres/" .. plusCode, "GET", Trackerimage1011Listener, params)
end

function Trackerimage1011Listener(event)
    if event.status == 200 then
        forceRedraw = true
        netUp() 
        local filename = string.gsub(event.url, serverURL .. "MapData/DrawCell10Highres/", "")
        requestedMapTileCells[filename] = 1
    else 
        netDown() 
        local filename = string.gsub(event.url, serverURL .. "MapData/DrawCell10Highres/", "")
        requestedMapTileCells[filename] = -1
    end
end

function TrackerGetCell8Image11(plusCode)
    netTransfer()
    local params = {}
    params.response  = {filename = plusCode .. "-11.png", baseDirectory = system.CachesDirectory}
    network.request(serverURL .. "MapData/DrawCell8Highres/" .. plusCode, "GET", Trackerimage811Listener, params)
end

function Trackerimage811Listener(event)
    if event.status == 200 then
        forceRedraw = true
        netUp() 
        local filename = string.gsub(event.url, serverURL .. "MapData/DrawCell8Highres/", "")
        requestedMapTileCells[filename] = 1
    else 
        netDown() 
        print("maptile listener failed")
        local filename = string.gsub(event.url, serverURL .. "MapData/DrawCell8Highres/", "")
        requestedMapTileCells[filename] = -1
    end
end

function GetTeamControlMapTile8(Cell8)
    if (requestedMPMapTileCells[cell8] == 1) then
        --We already have this tile.
        return
    end
    local status = requestedMPMapTileCells[Cell8] --this can occasionally be nil if there's multiple active calls that return out of order on the first update
     if (status == nil) then --first time requesting this cell this session.
        local dataPresent = doesFileExist(Cell8 .. "-AC-11.png", system.CachesDirectory)
        if (dataPresent == true) then --use local data.
            requestedMPMapTileCells[Cell8] = 1
            return
        end
        requestedMPMapTileCells[Cell8] = 0
        TrackerGetMPCell8Image11(Cell8)
     end

     if (status == -1) then --retry a failed download.
        requestedDataCells[Cell8] = 0
        TrackerGetMPCell8Image11(Cell8)
     end
end

function TrackerMPimage1011Listener(event)
    if event.status == 200 then
        forceRedraw = true
        netUp() 
        local filename = string.gsub(event.url, serverURL .. "Gameplay/DrawFactionModeCell10HighRes/", "")
        requestedMPMapTileCells[filename] = 1
    else 
        netDown() 
        local filename = string.gsub(event.url, serverURL .. "Gameplay/DrawFactionModeCell10HighRes/", "")
        requestedMPMapTileCells[filename] = -1
    end
end

function TrackerGetMPCell8Image11(plusCode)
    netTransfer()
    local params = {}
    params.response  = {filename = plusCode .. "-AC-11.png", baseDirectory = system.CachesDirectory}
    network.request(serverURL .. "Gameplay/DrawFactionModeCell8HighRes/" .. plusCode, "GET", TrackerMPimage811Listener, params)
end

function TrackerMPimage811Listener(event)
    if (debug) then print("got data for " ..  string.gsub(event.url, serverURL .. "Gameplay/DrawFactionModeCell8HighRes/", "")) end
    if event.status == 200 then
        forceRedraw = true
        netUp() 
        local filename = string.gsub(event.url, serverURL .. "Gameplay/DrawFactionModeCell8HighRes/", "")
        requestedMPMapTileCells[filename] = 1
    else 
        print("maptile listener failed")
        netDown() 
        local filename = string.gsub(event.url, serverURL .. "Gameplay/DrawFactionModeCell8HighRes/", "")
        requestedMPMapTileCells[filename] = -1
    end
end

--Since Paint The Town is meant to be a much faster game mode, we won't save its state in the database, just memory.
function GetPaintTownMapData8(Cell8, instanceID, getAll) -- the painttown map update call.
    --this doesn't get saved to the device at all. Keep it in memory, update it every few seconds.
    --TODO new functionality: if I don't currently have this cell in memory, do a full request.
    --if I do, only call LearnCell8Recent and save some time updating the last 30 seconds of changes.
    --if (PTCellsInProcessing[Cell8] == 1) then
        --return
    --end
    --PTCellsInProcessing[Cell8] = 1

    --getAll = true
    if (DownloadedCell8sThisSession[Cell8] == nil or getAll == true) then
        --print("getting full data for " .. Cell8)
        network.request(serverURL .. "PaintTown/LearnCell8/" .. instanceID .. "/" .. Cell8, "GET", PaintTownMapListener) 
        DownloadedCell8sThisSession[Cell8] = 1
    else
        --print("getting recent data for " .. Cell8)
        network.request(serverURL .. "PaintTown/LearnCell8Recent/" .. instanceID .. "/" .. Cell8, "GET", PaintTownMapListener) 
    end
    netTransfer()
    
    --requestedPaintTownCells = {} --clears out the display cache. this might be better placed somewhere else, but doing this in the listener seems to fail?
end

function PaintTownMapListener(event)
    local time = 0
    local instanceID = Split(string.gsub(event.url, serverURL .. "PaintTown/LearnCell8/", ""), "/")[1]
    local Cell8 = Split(string.gsub(event.url, serverURL .. "PaintTown/LearnCell8/", ""), "/")[2]
    if (instanceID == 'https:' or instanceID == nil) then
        instanceID = Split(string.gsub(event.url, serverURL .. "PaintTown/LearnCell8Recent/", ""), "/")[1]
        Cell8 = Split(string.gsub(event.url, serverURL .. "PaintTown/LearnCell8Recent/", ""), "/")[2]
    end

    --print(event.url)
    --print("Processing data for " .. Cell8)

    if (debug) then 
        print("paint the town map event started") 
        time = os.time()
    end
    if event.status == 200 then 
        netUp() 
    else 
        print("paint the town map listener failed")
        PTCellsInProcessing[Cell8] = 0
        DownloadedCell8sThisSession[Cell8] = nil
        netDown() 
    end
    if (event.status ~= 200) then return end --dont' save invalid results on an error.
    
    --This one splits each Cell10 via pipe, each sub-vaule by =
    local resultsTable = Split(event.response, "|")
    --Format:
    --Cell10=TeamID|Cell10=TeamID etc

    local tempCellStatus =  requestedPaintTownCells
    
    for cell = 1, #resultsTable do
        local splitData = Split(resultsTable[cell], "=")
        local key = splitData[1]
        tempCellStatus[key] = splitData[2]
        --requestedPaintTownCells[key] = splitData[2]
    end
    requestedPaintTownCells = tempCellStatus
    forceRedraw = true

    PTCellsInProcessing[Cell8] = 0

    if (debug) then print("paint town listener ended") end
end

function ClaimPaintTownCell(Cell10)
    --this is a DB call in the standalone app.
    --netTransfer()
    --network.request(serverURL .. "PaintTown/ClaimCell10/" .. factionId .. "/" .. Cell10, "GET", PaintTownClaimListener) 
    
    --This is a database check in this app.
end

function PaintTownClaimListener(event) --record stats locally only
    if event.status == 200 then 
        netUp() 
        --TODO: create column for points contributed in DB, increment them by results
        if (debug) then print("Got Points: " .. event.response) end
        if (event.response ~= "0") then
            AddPoints(event.response)
            --else indicate cell locked out
        end
    else 
        print("paint the town claim failed")
        netDown() 
    end
end