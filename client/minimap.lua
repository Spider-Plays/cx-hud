return function(State, Utils, readyToRock, Config)
    local squaremapLoaded = false
    local mapPatched      = false

    local function grabSquaremap()
        if squaremapLoaded then return true end
        RequestStreamedTextureDict('squaremap', false)
        local waited = 0
        while not HasStreamedTextureDictLoaded('squaremap') do
            Wait(100); waited = waited + 100
            if waited >= 5000 then print('[cx-hud] squaremap timed out'); return false end
        end
        SetMinimapClipType(0)
        AddReplaceTexture('platform:/textures/graphics', 'radarmasksm', 'squaremap', 'radarmasksm')
        AddReplaceTexture('platform:/textures/graphics', 'radarmask1g', 'squaremap', 'radarmasksm')
        squaremapLoaded = true
        return true
    end

    local function killBigmap()
        CreateThread(function()
            local t = 0
            while t < 10000 do SetBigmapActive(false, false); t = t + 1000; Wait(1000) end
        end)
    end

    local function patchMinimap()
        if mapPatched then return end
        if not grabSquaremap() then return end
        local rx, ry   = GetActiveScreenResolution()
        local mmOffset = 0.0
        if rx / ry > 1920 / 1080 then mmOffset = ((1920 / 1080 - rx / ry) / 3.6) - 0.008 end
        SetMinimapClipType(0)
        SetMinimapComponentPosition('minimap',      'L', 'B',  0.0  + mmOffset, -0.047, 0.1638, 0.183)
        SetMinimapComponentPosition('minimap_mask', 'L', 'B',  0.0  + mmOffset,  0.0,   0.128,  0.20)
        SetMinimapComponentPosition('minimap_blur', 'L', 'B', -0.01 + mmOffset,  0.025, 0.262,  0.300)
        SetBlipAlpha(GetNorthRadarBlip(), 0)
        SetBigmapActive(true, false); Wait(0); SetBigmapActive(false, false)
        killBigmap()
        mapPatched = true
    end

    -- Show/hide radar based on login state and vehicle presence
    local lastInCar   = false
    local lastCanShow = false

    CreateThread(function()
        while true do
            Wait(500)
            local canShow = readyToRock()
            local inCar   = canShow and cache.vehicle ~= nil or false
            local show    = canShow and (Config.EnableMinimapOnFoot or inCar)
            if canShow ~= lastCanShow or inCar ~= lastInCar then
                if canShow then
                    patchMinimap()
                    DisplayRadar(show)
                    if show then SetBigmapActive(false, false) end
                else
                    DisplayRadar(false)
                    SetBigmapActive(false, false)
                end
                lastCanShow = canShow
                lastInCar   = inCar
            end
        end
    end)

    return { patchMinimap = patchMinimap }
end
