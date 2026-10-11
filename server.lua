local endpoint = GetConvar("synapse_verification_url", "")
local integrationKey = GetConvar("synapse_verification_key", "")

local function postDiscordJoin(discordId, attempt)
    PerformHttpRequest(endpoint, function(statusCode)
        if statusCode >= 200 and statusCode < 300 then
            return
        end

        if attempt < 3 and (statusCode == 0 or statusCode >= 500) then
            SetTimeout(attempt * 5000, function()
                postDiscordJoin(discordId, attempt + 1)
            end)
            return
        end

        print(("[synapse_verification] Synapse rejected or could not receive a join report (HTTP %s)."):format(statusCode))
    end, "POST", json.encode({ discordId = discordId }), {
        ["Content-Type"] = "application/json",
        ["Authorization"] = "Bearer " .. integrationKey,
    })
end

local function reportDiscordJoin(playerId)
    local identifier = GetPlayerIdentifierByType(playerId, "discord")
    local discordId = identifier and identifier:gsub("^discord:", "") or ""

    if #discordId < 17 or #discordId > 20 or not discordId:match("^%d+$") then
        print(("[synapse_verification] Player %s has no linked Discord identifier; join was not reported."):format(playerId))
        return
    end

    postDiscordJoin(discordId, 1)
end

AddEventHandler("playerJoining", function()
    local playerId = source

    if endpoint == "" or integrationKey == "" then
        print("[synapse_verification] Configure synapse_verification_url and synapse_verification_key in server.cfg.")
        return
    end

    reportDiscordJoin(playerId)
end)
