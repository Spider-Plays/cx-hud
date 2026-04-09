return function(Config)
    local function yeet(action, payload)
        SendNUIMessage({ action = action, data = payload })
    end

    local function roundIt(n)
        return math.floor((n or 0) + 0.5)
    end

    local function headingToCompass(deg)
        local dirs = { 'N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW' }
        return dirs[math.floor(((deg % 360) + 22.5) / 45) % 8 + 1]
    end

    local function prettyMoney(n)
        local s      = tostring(math.floor(n or 0))
        local going  = true
        while going do
            local k; s, k = s:gsub('^(%-?%d+)(%d%d%d)', '%1,%2')
            if k == 0 then going = false end
        end
        return '$' .. s
    end

    local function whereTheHellAmI(coords)
        local sh, ch  = GetStreetNameAtCoord(coords.x, coords.y, coords.z)
        local rawZone = GetNameOfZone(coords.x, coords.y, coords.z)
        local street  = GetStreetNameFromHashKey(sh)
        local cross   = ch ~= 0 and GetStreetNameFromHashKey(ch) or ''
        local zLabel  = GetLabelText(rawZone)
        return street, cross, (zLabel == 'NULL' or zLabel == '') and rawZone or zLabel
    end

    local function waypointDistance(coords)
        local wp = GetFirstBlipInfoId(8)
        if not DoesBlipExist(wp) then return nil end
        local wc = GetBlipInfoIdCoord(wp)
        local d  = math.sqrt((coords.x - wc.x)^2 + (coords.y - wc.y)^2)
        return d >= 1000 and ('%.1f km'):format(d / 1000) or ('%d m'):format(math.floor(d))
    end

    local cachedVehHandle = -1
    local cachedVehName   = ''

    local function getVehName(veh)
        if veh == cachedVehHandle then return cachedVehName end
        local label = GetLabelText(GetDisplayNameFromVehicleModel(GetEntityModel(veh)))
        if label == 'NULL' or label == '' then label = GetDisplayNameFromVehicleModel(GetEntityModel(veh)) end
        cachedVehHandle = veh
        cachedVehName   = label
        return label
    end

    return {
        yeet             = yeet,
        roundIt          = roundIt,
        headingToCompass = headingToCompass,
        prettyMoney      = prettyMoney,
        whereTheHellAmI  = whereTheHellAmI,
        waypointDistance = waypointDistance,
        getVehName       = getVehName,
    }
end
