function grantPoints(code)
    -- new Cell8: 100 points! --removing
    -- New Cell10: 10 points!
    -- weekly bonus: 5 points
    -- daily checkin: 1 point
    local addPoints = 0
    if (debug) then print("granting points for cell " .. code) end

    -- check 1: is this the first time we've entered this Cell8?
    -- query = "SELECT COUNT(*) as c FROM plusCodesVisited WHERE eightCode = '" .. code:sub(1,8) .. "'"
    -- for i,row in ipairs(Query(query)) do 
    --     if (row[1] == 0) then --we have not yet visited this cell
    --         --new visit to this cell8
    --         addPoints = addPoints + 100
    --     end
    -- end

    -- check 2: is this a brand new Cell10?
    local query =
        "SELECT COUNT(*) as c FROM plusCodesVisited WHERE pluscode = '" .. code ..
            "'"
    for i, row in ipairs(Query(query)) do
        print(dump(row))
        if (row[1] == 0) then
            if (debug) then print("inserting new row") end
            local timeValue = os.time()
            local dailyReset = timeValue + 79200 -- 22 hours
            local weeklyReset = timeValue + (79200 * 7) -- 6.5 days
            local insert =
                "INSERT INTO plusCodesVisited (pluscode, visited, lastVisit, nextDailyBonus, nextWeeklyBonus) VALUES ('" ..
                    code .. "', 1, " .. timeValue .. "," .. dailyReset .. "," ..
                    weeklyReset .. ")"
            Exec(insert)
            addPoints = addPoints + 10
        else
            print("checking values")
            local sql2 = "SELECT * FROM PlusCodesVisited WHERE pluscode = '" ..
                             code .. "'"
            local query2 = Query(sql2)
            -- if (debug) then print("updating existing data") end
            for i, row in ipairs(query2) do
                --print(dump(row))
                local timeValue = os.time()
                local dailyReset = row[5]
                local weeklyReset = row[6]
                --print(dailyReset)
                --print("values set")
                if (tonumber(dailyReset) < timeValue) then
                    --print("bonk1")
                    dailyReset = timeValue + 79200 -- 22 hours
                    addPoints = addPoints + 1
                end
                if (tonumber(weeklyReset) < timeValue) then
                    --print("bonk2")
                    weeklyReset = timeValue + (79200 * 7) -- 6.5 days
                    addPoints = addPoints + 10
                end
                --print("ready to update")
                local update = "UPDATE plusCodesVisited SET lastVisit = " ..
                                   os.time() .. ", nextDailyBonus = " ..
                                   dailyReset .. ", nextWeeklyBonus = " ..
                                   weeklyReset .. " WHERE plusCode = '" .. code ..
                                   "'"
                Exec(update)
            end
        end
    end
    if (debug) then print("grant query done") end

    -- --check 3: this our first visit today?
    -- query = "SELECT COUNT(*) as c FROM dailyVisited WHERE pluscode = '" .. code .. "'"
    -- for i,row in ipairs(Query(query)) do
    --     if (row[1] == 0) then --we have not yet visited this cell today
    --         local cmd = "INSERT INTO dailyVisited (pluscode, VisitedOn) VALUES('" .. code .. "', " .. os.time() .. ")"
    --         Exec(cmd)
    --         addPoints = addPoints + 1 
    --     end
    -- end

    -- if(debug) then print("grant query 2 done") end

    -- --check 4: this our first visit this week?
    -- query = "SELECT COUNT(*) as c FROM weeklyVisited WHERE pluscode = '" .. code .. "'"
    -- for i,row in ipairs(Query(query)) do 
    --     if (row[1] == 0) then --we have not yet visited this cell this week
    --         local cmd = "INSERT INTO weeklyVisited (pluscode, VisitedOn) VALUES('" .. code .. "', " .. os.time() .. ")"
    --         Exec(cmd)
    --         addPoints = addPoints + 5
    --     end
    -- end

    local cmd = "UPDATE playerStats SET score = score + " .. addPoints
    Exec(cmd)

    if (debug) then
        print("earned " .. addPoints .. " points for cell " .. code)
    end
    return addPoints
end
