return function(State, Utils, readyToRock, Config)
    local BELT_KEY = Config.SeatbeltKey or 29
    local seatbeltEnabled = Config.EnableSeatbelt ~= false

    local function pushVehicle()
        if not cache.vehicle then
            Utils.yeet('updateVehicle', { show = false })
            return
        end
        local veh    = cache.vehicle
        local rawSpd = GetEntitySpeed(veh)
        local speed  = Config.SpeedUnit == 'KMH' and rawSpd * 3.6 or rawSpd * 2.236936
        local gear   = GetVehicleCurrentGear(veh)
        local rpm    = math.floor((GetVehicleCurrentRpm(veh) or 0) * 100)
        Utils.yeet('updateVehicle', {
            show     = true,
            speed    = Utils.roundIt(speed),
            unit     = Config.SpeedUnit,
            fuel     = Utils.roundIt(GetVehicleFuelLevel(veh)),
            rpm      = rpm,
            gear     = gear == 0 and 'R' or tostring(gear),
            engine   = math.max(0, math.min(100, Utils.roundIt(GetVehicleEngineHealth(veh) / 10))),
            seatbelt = seatbeltEnabled and State.buckledUp or false,
            vehName  = Utils.getVehName(veh),
            lights   = {
                headlights     = State.lastLights.headlights,
                highbeam       = State.lastLights.highbeam,
                indicatorLeft  = State.lastLights.indicatorLeft,
                indicatorRight = State.lastLights.indicatorRight,
                hazard         = State.lastLights.hazard,
            },
        })
    end

    -- Seatbelt, indicator controls, and eject logic
    CreateThread(function()
        while true do
            if cache.vehicle then
                local veh      = cache.vehicle
                local isDriver = cache.seat == -1

                if not seatbeltEnabled and State.buckledUp then
                    State.buckledUp = false
                    if State.hudShowing then pushVehicle() end
                end

                if seatbeltEnabled and IsControlJustPressed(0, BELT_KEY) then
                    State.buckledUp = not State.buckledUp
                    lib.notify({
                        title       = 'Seatbelt',
                        description = State.buckledUp and 'Seatbelt fastened' or 'Seatbelt removed',
                        type        = State.buckledUp and 'success' or 'error',
                        duration    = 2000,
                    })
                    if State.hudShowing then pushVehicle() end
                end

                if seatbeltEnabled and State.buckledUp then
                    DisableControlAction(0, 75, true)
                    if IsDisabledControlJustPressed(0, 75) then
                        lib.notify({ title = 'Seatbelt', description = 'Remove your seatbelt first', type = 'error' })
                    end
                end

                if isDriver then
                    DisableControlAction(0, 174, true)
                    DisableControlAction(0, 175, true)
                    DisableControlAction(0, 173, true)
                    if IsDisabledControlJustPressed(0, 174) then
                        SetVehicleIndicatorLights(veh, 1, GetVehicleIndicatorLights(veh) ~= 1)
                        SetVehicleIndicatorLights(veh, 0, false)
                        PlaySoundFrontend(-1, 'NAV_UP_DOWN', 'HUD_FRONTEND_DEFAULT_SOUNDSET', false)
                    end
                    if IsDisabledControlJustPressed(0, 175) then
                        SetVehicleIndicatorLights(veh, 0, GetVehicleIndicatorLights(veh) ~= 2)
                        SetVehicleIndicatorLights(veh, 1, false)
                        PlaySoundFrontend(-1, 'NAV_UP_DOWN', 'HUD_FRONTEND_DEFAULT_SOUNDSET', false)
                    end
                    if IsDisabledControlJustPressed(0, 173) then
                        local hz = GetVehicleIndicatorLights(veh) == 3
                        SetVehicleIndicatorLights(veh, 0, not hz)
                        SetVehicleIndicatorLights(veh, 1, not hz)
                        PlaySoundFrontend(-1, 'NAV_UP_DOWN', 'HUD_FRONTEND_DEFAULT_SOUNDSET', false)
                    end
                end

                if seatbeltEnabled and Config.SeatbeltEject and not State.buckledUp and not State.ejected then
                    local kmh = GetEntitySpeed(veh) * 3.6
                    if kmh > Config.SeatbeltEjectSpeed and GetVehicleBodyHealth(veh) < Config.SeatbeltBodyThresh then
                        local fwd = GetEntityForwardVector(veh)
                        local spd = GetEntitySpeed(veh)
                        State.ejected = true
                        TaskLeaveVehicle(cache.ped, veh, 4160)
                        Wait(100)
                        SetEntityVelocity(cache.ped, fwd.x * spd * 0.8, fwd.y * spd * 0.8, spd * 0.3)
                    end
                end

                Wait(0)
            else
                if State.buckledUp then
                    State.buckledUp = false
                    if State.hudShowing then pushVehicle() end
                end
                State.ejected = false
                Wait(300)
            end
        end
    end)

    -- Lights state polling
    CreateThread(function()
        while true do
            if readyToRock() and cache.vehicle then
                local veh       = cache.vehicle
                local on, _, hb = GetVehicleLightsState(veh)
                local ind       = GetVehicleIndicatorLights(veh)
                local fl        = {
                    headlights     = on >= 1,
                    highbeam       = hb == true or hb == 1,
                    indicatorLeft  = ind == 1 or ind == 3,
                    indicatorRight = ind == 2 or ind == 3,
                    hazard         = ind == 3,
                }
                local changed = false
                for k, v in pairs(fl) do
                    if State.lastLights[k] ~= v then changed = true; break end
                end
                if changed then State.lastLights = fl; Utils.yeet('updateLights', fl) end
                Wait(150)
            else
                local anyOn = State.lastLights.headlights or State.lastLights.highbeam
                           or State.lastLights.indicatorLeft or State.lastLights.indicatorRight
                if anyOn then
                    State.lastLights = { headlights=false, highbeam=false, indicatorLeft=false, indicatorRight=false, hazard=false }
                    Utils.yeet('updateLights', State.lastLights)
                end
                Wait(500)
            end
        end
    end)

    exports('SetSeatbelt', function(state)
        if not seatbeltEnabled then
            State.buckledUp = false
        else
            State.buckledUp = state == true
        end
        if State.hudShowing then pushVehicle() end
    end)

    return { pushVehicle = pushVehicle }
end
