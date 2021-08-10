--[[
=====================================
| author: Nkfree                    |
| github: https://github.com/Nkfree |
=================================================================================================================================
| requires: namesData.lua that can be downloaded from https://github.com/Nkfree/-TES3MP-resources/blob/main/namesData.lua	|
=================================================================================================================================
]]

local namesData = require("custom.namesData")

local config = {}
config.resetKillsRank = 3 -- 0 - everyone is allowed to reset their kills, 1 - moderator, 2 - admin, 3 - server owner
config.cellShared = false -- true - any kill that happens in the cell is shared among players within the same cell; false - kills are assigned merely to killers
config.guiId = 85263

-- Save kill in player's data
local function SaveKill(pid, refId)
    if not Players[pid].data.kills[refId] then
        Players[pid].data.kills[refId] = 1
    else
        Players[pid].data.kills[refId] = Players[pid].data.kills[refId] + 1
    end
end

-- Load kills stored in player's data
local function LoadKills(pid)
    tes3mp.ClearKillChanges(pid)

    for refId, count in pairs(Players[pid].data.kills) do
        tes3mp.AddKill(pid, refId, count)
    end

    tes3mp.SendKillChanges(pid, false)
end

-- Back up world kills to world's custom variables just in case
local function OnServerPostInitHandler(eventStatus)
    local worldData = WorldInstance.data

    if next(worldData.kills) then
        worldData.customVariables.kills = {}

        for refId, count in pairs(worldData.kills) do
            worldData.customVariables.kills[refId] = count
        end

        worldData.kills = {}
        WorldInstance:QuicksaveToDrive()
    end

    tes3mp.LogMessage(enumerations.log.INFO, "[playerKillCount] Running...")
end

-- Load player's saved kills to player on logging in
local function OnPlayerAuthentifiedHandler(eventStatus, pid)
    if Players[pid].data.kills == nil then Players[pid].data.kills = {} end
    LoadKills(pid)
end

-- Disable default OnWorldKillCount event behaviour
local function OnWorldKillCountValidator(eventStatus, pid)
    return customEventHooks.makeEventStatus(false, false)
end

-- Save kill for player who killed related actor and other players within the cell in case of config.cellShared being set to true
local function OnActorDeathHandler(eventStatus, pid, cellDescription)

    local actorListSize = tes3mp.GetActorListSize()
    local cell = LoadedCells[cellDescription]

    if actorListSize == 0 then
        return
    end

    for actorIndex = 0, actorListSize - 1 do
        local uniqueIndex = tes3mp.GetActorRefNum(actorIndex) .. "-" .. tes3mp.GetActorMpNum(actorIndex)
        local refId = cell.data.objectData[uniqueIndex].refId

        if refId ~= "" and refId ~= " " and refId and tes3mp.DoesActorHavePlayerKiller(actorIndex) then
            local killerPid = tes3mp.GetActorKillerPid(actorIndex)

            if Players[killerPid] and Players[killerPid]:IsLoggedIn() then
                if tes3mp.GetCell(killerPid) == cellDescription then
                    SaveKill(killerPid, refId)
                end
            end

            if config.cellShared then
                for id, _ in pairs(Players) do
                    if id ~= killerPid and Players[id]:IsLoggedIn() then
                        if tes3mp.GetCell(id) == cellDescription then
                            SaveKill(id, refId)
                            tes3mp.SendKillChanges(id, false, false)
                        end
                    end
                end
            end
        end
    end
end

-- Resets player kills if they meet rank requirement
local function ResetKills(pid, cmd)

    if Players[pid].data.settings.staffRank >= config.resetKillsRank then
        -- Reset saved player kills
        for refId, _ in pairs(Players[pid].data.kills) do
			Players[pid].data.kills[refId] = 0
        end
        -- Load them for player
        LoadKills(pid)
    else
        tes3mp.SendMessage(pid, "You are not eligible to reset kills.\n", false)
    end
end

-- Displays total amount of player kills as well as complete list of killed actors and their respective count
local function GuiShowKills(pid, cmd)
    local label = "- Player Kills -\n\n"
    local totalKills = 0
    local items = ""

    for refId, count in pairs(Players[pid].data.kills) do
        totalKills = totalKills + count

        if namesData[string.lower(refId)] then
            items = items .. namesData[string.lower(refId)]
        else
            items = items .. string.lower(refId)
        end

        items = items .. ": " .. count .. "\n"
    end

    label = label .. "Total: " .. totalKills

    return tes3mp.ListBox(pid, config.guiId, label, items)
end


customEventHooks.registerHandler("OnServerPostInit", OnServerPostInitHandler)
customEventHooks.registerHandler("OnPlayerAuthentified", OnPlayerAuthentifiedHandler)
customEventHooks.registerValidator("OnWorldKillCount", OnWorldKillCountValidator)
customEventHooks.registerHandler("OnActorDeath", OnActorDeathHandler)

customCommandHooks.registerCommand("resetkills", ResetKills)
customCommandHooks.registerCommand("showkills", GuiShowKills)
