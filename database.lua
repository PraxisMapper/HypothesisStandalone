--NOTE: on android, clearing app data doesnt' delete the database, just contents of it, apparently.
require("helpers")

local sqlite3 = require("sqlite3") 
localDb = ""
local dbVersionID = 10

function startDatabase()
    --localDb is the one we write data to.
    local path = system.pathForFile("database.sqlite", system.DocumentsDirectory)
    localDb = sqlite3.open(path)

    -- Handle the "applicationExit" event to close the database
    local function onSystemEvent(event)
        if (event.type == "applicationExit" and localDb:isopen()) then localDb:close() end
        if (event.type == "applicationExit" and masterDb:isopen()) then masterDb:close() end
    end

    Runtime:addEventListener("system", onSystemEvent)
end

function upgradeDatabaseVersion(oldDBversion)
    --if oldDbVersion is nil, that should mean we're making the DB for the first time and can skip this step
    if (oldDBversion == nil or oldDBversion == dbVersionID) then return end

    if (oldDBversion < 1) then
        --do any scripting to match upgrade to version 1
        --which should be none, since that's the baseline for this feature.
    end

   Exec("UPDATE systemData SET dbVersionID = " .. dbVersionID)
end

function Query(sql)
    --print("querying" .. sql)
    results = {}
    local tempResults = localDb:rows(sql)
    --print("results got")

    for row in localDb:rows(sql) do
        table.insert(results, row) 
    end
    --if (debugDB) then dump(results) end
    return results --results is a table of tables EX {[1] : {[1] : 1}} for count(*) when there are results.
end

function SingleValueQuery(sql)
    local query = sql
    for i,row in ipairs(Query(query)) do
        if (#row == 1) then
            return row[1]
        else
            return 0
        end
    end
    return 0
end

function Exec(sql)
    results = {}
    local resultCode = localDb:exec(sql);

     if (resultCode == 0) then
         return 0
     end

    --now its all error tracking.
     local errormsg = localDb:errmsg()
     print(errormsg)
     native.showAlert("dbExec error", errormsg .. "|" .. sql)
     return resultCode
end

--function ResetDailyWeekly(instanceID) -- no longer does daily tracking, so name is wrong.
    --checks for daily and weekly reset times.
    --if oldest date in daily/weekly table is over 22/(24 * 6.9) hours old, delete everything in the table.
    --local timeDiffDaily = os.time() - (60 * 60 * 22) --22 hours, converted to seconds.
    --local cmd = "DELETE FROM dailyVisited WHERE VisitedOn < " .. timeDiffDaily
    --Exec(cmd)
    --local timeDiffWeekly = os.time() - math.floor(60 * 60 * 24 * 6.9) -- 6.9 days, converted to seconds
    --cmd = "DELETE FROM weeklyVisited WHERE VisitedOn < " .. timeDiffWeekly
    --Exec(cmd)
    --cmd = "UPDATE weeklyPoints SET score = 0, instanceID = " .. instanceID
    --I need to get resetAt from the server.
    --Exec(cmd)

--end

function VisitedCell(pluscode)
    if (debugDB) then print("Checking if visited current cell " .. pluscode) end
    local query = "SELECT COUNT(*) as c FROM plusCodesVisited WHERE pluscode = '" .. pluscode .. "'"
    for i,row in ipairs(Query(query)) do
        if (row[1] == 1) then
            return true
        else
            return false
        end
    end
end

function VisitedCell8(pluscode)
    if (debugDB) then print("Checking if visited current cell8 " .. pluscode) end
    local query = "SELECT COUNT(*) as c FROM plusCodesVisited WHERE eightCode = '" .. pluscode .. "'"
    for i,row in ipairs(Query(query)) do
        if (row[1] >= 1) then --any number of entries over 1 means this block was visited.
            return true
        else
            return false
        end
    end
end

function TotalExploredCells()
    if (debugDB) then print("opening total explored cells ") end
    local query = "SELECT COUNT(*) as c FROM plusCodesVisited"
    for i,row in ipairs(Query(query)) do
        return row[1]
    end
end

function TotalExploredCell8s()
    if (debugDB) then print("opening total explored cell8s ") end
    local query = "SELECT COUNT(distinct eightCode) as c FROM plusCodesVisited"
    for i,row in ipairs(Query(query)) do
        return row[1]
    end
end

function Score()
    local query = "SELECT totalPoints as p from playerData"
    local qResults = Query(query)
    if (#qResults > 0) then
        for i,row in ipairs(qResults) do
            return row[1]
        end
    else
        return "?"
    end
end

function LoadTerrainData(pluscode) --plus code does not contain a + here
    if (debugDB) then print("loading terrain data ") end
    local query = "SELECT * from TerrainInfo ti INNER JOIN TerrainData td on td.OsmElementId = ti.terrainDataId WHERE ti.PlusCode = '" .. pluscode .. "'"
    --Now looks like TIid|PlusCode|OsmElementID|TDid|Name|AreatypeName|OsmElementID|OsmElementType
    local results = Query(query)
    --print(dump(results))
    
    for i,row in ipairs(results) do
        if (debugDB) then print(dump(row)) end
        return row
    end 
    return {} --empty table means no data found.
end

--This shouldn't be used anymore since I keep all that data in memory now.
function DownloadedCell8(pluscode)
    local query = "SELECT COUNT(*) as c FROM dataDownloaded WHERE pluscode8 = '" .. pluscode .. "'"
    for i,row in ipairs(Query(query)) do
        if (row[1] >= 1) then --any number of entries over 1 means this block was visited.
            return true
        else
            return false
        end
    end
    return false
end

function ClaimAreaLocally(mapdataid, name, score)
    if (debug) then print("claiming area " .. mapdataid) end
    name = string.gsub(name, "'", "''")
    local cmd = "INSERT INTO areasOwned (mapDataId, name, points) VALUES (" .. mapdataid .. ", '" .. name .. "'," .. score ..")"
    --db:exec(cmd)
    Exec(cmd)
end

function CheckAreaOwned(mapdataid)
    if (mapdataid == null) then return false end
    local query = "SELECT COUNT(*) as c FROM areasOwned WHERE MapDataId = "  .. mapdataid
    for i,row in ipairs(Query(query)) do
        if (row[1] >= 1) then --any number of entries over 1 means this entry is owned
            return true
        else
            return false
        end
    end
    return false
end

function AreaControlScore()
    local query = "SELECT SUM(points) FROM areasOwned"
    for i,row in ipairs(Query(query)) do
        if (#row == 1) then
            return row[1]
        else
            return 0
        end
    end
    return 0
end

function SpendPoints(points)
    local cmd = "UPDATE playerStats SET score = score - " .. points
    db:exec(cmd)
end

function AddPoints(points)
    local cmd = "UPDATE weeklyPoints SET score  = score + " .. points
    --print(cmd)
    local updated = db:exec(cmd)
    --print(updated)
    cmd = "update allTimePoints SET score = score + " .. points
    db:exec(cmd)
end

function AllTimePoints()
    local query = "SELECT score FROM playerStats"
    return SingleValueQuery(query)
end

function WeeklyPoints()
    local query = "SELECT score FROM weeklyPoints" --WHERE what?
    return SingleValueQuery(query)
end

function GetTeamID()
    local query = "SELECT factionID FROM playerData"
    for i,row in ipairs(Query(query)) do
        if (#row == 1) then
            return row[1]
        else
            return 0
        end
    end
    return 0
end

function GetServerAddress()
    local query = "SELECT serverAddress FROM systemData"
    for i,row in ipairs(Query(query)) do
        if (#row == 1) then
            return row[1]
        else
            return "noServerFound"
        end
    end
    return ""
end

-- function SetServerAddress(url)
--     local cmd = "UPDATE systemData SET serverAddress = '" .. url .. "'"
--     db:exec(cmd)
-- end

-- function SetFactionId(teamId)
--     local cmd = "UPDATE playerData SET factionID = " .. teamId .. ""
--     db:exec(cmd)
-- end

function GetEndDate(instanceID)
    local query = "SELECT endsAt FROM endDates WHERE instanceID = " ..instanceID
    return SingleValueQuery(query)
end

function SetEndDate(instanceID, endDate)
    local cmd = "UPDATE endDates SET endsAt = '" .. endDate .. "' WHERE instanceID = " .. instanceID
    --print(cmd)
    local updated = db:exec(cmd)
end