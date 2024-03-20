local lib = { }

function lib.new()
    local libscheduler = libscheduler or loadSched()
    local service = {
        -- get system info here
        currentSensor = system.getSource("Current"),
        resetSwitch = nil, -- switch to reset script, usually same switch to reset timers
        startTime = os.clock(),
        scheduler = libscheduler.new(), -- todo: check to see if this can be removed
        --source = system.getSource("Throttle"), -- todo: check to see if this can be removed

        -- misc
        canCallInitFuncAgain = false,

        -- capacity variables in mAh values
        sfCapacityMah = {}, -- list of capacity values assigned to the special function buttons
        capacityFullMah = 5000, -- total pack capacity
        capacityFullUpdated = false,
        capacityUsedMah = 0, -- total mAh used since reset
        capacityReservedMah = 0, -- adjusted capacity based on reserved percent in mAh
        capacityRemainingMah = 0, -- remaining battery based on capacityRemainingMah

        -- capacity variables in percentages
        capacityReservePercent = 20, -- Reserve Capacity: Remaining % Displayed = Calculated Remaining % - Reserve %
        batteryRemainingPercent = 0,

        -- Announcements
        soundDirPath = "/scripts/mahRe2/sounds/", -- where you put the sound files,
        announcePercentRemaining = true,
        batteryRemainingPercentFileName = 0, -- updated in service.PlayPercentRemaining
        batteryRemainingPercentPlayed = 0, -- updated in service.PlayPercentRemaining
        atZeroPlayedCount = 0, -- updated in initializeValues, service.PlayPercentRemaining
        playAtZero = 1,
    }

    function service.playPercentRemaining()
        -- Announces percent remaining using the accompanying sound files.
        -- Announcements ever 10% change when percent remaining is above 10 else
        --	every 5%
        local myModVal
        if service.batteryRemainingPercent < 10 then
            myModVal = service.batteryRemainingPercent % 5
        else
            myModVal = service.batteryRemainingPercent % 10
        end

        if myModVal == 0 and service.batteryRemainingPercent ~= service.batteryRemainingPercentPlayed then
            system.playNumber(service.batteryRemainingPercent, UNIT_PERCENT, 0)
            system.playFile(service.soundDirPath .. "remaining.wav")
            service.batteryRemainingPercentPlayed = service.batteryRemainingPercent    -- do not keep playing the same sound file over and
        end

        local rssi = system.getSource("RSSI")
        if service.batteryRemainingPercent <= 0 and service.atZeroPlayedCount < service.playAtZero and rssi:value() > 0 then
            print(service.batteryRemainingPercent, service.atZeroPlayedCount)
            system.playFile(service.soundDirPath .. "BatNo.wav")
            service.atZeroPlayedCount = service.atZeroPlayedCount + 1
        elseif service.atZeroPlayedCount == service.PlayAtZero and service.batteryRemainingPercent > 0 then
            service.atZeroPlayedCount = 0
        end
    end

    function service.initializeValues()
        if service then
            service.capacityReservedMah = service.capacityFullMah * (100 - service.capacityReservePercent) / 100
            service.capacityRemainingMah = service.capacityReservedMah
            service.batteryRemainingPercent = 0
            service.atZeroPlayedCount = 0
            service.capacityFullUpdated = false
        end
    end

    function service.reset_if_needed()
        -- test if the reset switch is toggled, if so then reset all internal flags
        if service.resetSwitch then
            -- Update switch position
            local debounced = service.scheduler.check('reset_sw')
            --print("debounced: " .. tostring(debounced))
            local resetSwitchValue = service.resetSwitch:value()
            if (debounced == nil or debounced == true) and -1024 ~= resetSwitchValue then
                -- reset switch
                service.scheduler.add('reset_sw', false, 2) -- add the reset switch to the scheduler
                --print("reset start task: " .. tostring(service.scheduler.tasks['reset_sw'].ready))
                service.scheduler.clear('reset_sw') -- set the reset switch to false in the scheduler so we don't run again
                --print("reset task: " .. tostring(service.scheduler.tasks['reset_sw'].ready))
                --print("reset switch toggled - debounced: " .. tostring(debounced))
                print("reset event")
                service.startTime = os.clock()  -- this resets the mAh used counter
                service.scheduler.reset()
                service.initializeValues()
            elseif -1024 == resetSwitchValue then
                --print("reset switch released")
                service.scheduler.remove('reset_sw')
            end
        end
    end

    function service.bg_func()
        -- test if the reset switch is toggled, if so then reset all internal flags
        service.reset_if_needed()

        -- check the special function buttons to see if there is a change in pack capacity
        if service.useSpecialFunctionButtons then
            for i = 0, 6, 1 do
                local me = system.getSource({ category = CATEGORY_FUNCTION_SWITCH, member = i })
                local value = me:value()
                if (value == 1024 or value == 100) and service.sfCapacityMah[i + 1] ~= service.capacityFullMah then
                    service.capacityFullMah = service.sfCapacityMah[i + 1]
                    service.capacityFullUpdated = true
                    system.playNumber(service.capacityFullMah, UNIT_MILLIAMPERE_HOUR, 0)
                    break
                end
            end
        end

        -- Check in battery capacity was changed
        if service.capacityFullUpdated then
            service.initializeValues()
        end

        if service.mAhSensor ~= "" then
            service.capacityUsedMah = math.floor(service.currentSensor:value() * 1000 * (os.clock() - service.startTime) / 3600)
            if (service.capacityUsedMah == 0) and service.canCallInitFuncAgain then
                -- service.capacityUsedMah == 0 when Telemetry has been reset or model loaded
                -- service.capacityUsedMah == 0 when no battery used which could be a long time
                --	so don't keep calling the service.initializeValues unnecessarily.

                service.initializeValues()
                service.canCallInitFuncAgain = false
            elseif service.capacityUsedMah > 0 then
                -- Call init function again when Telemetry has been reset
                service.canCallInitFuncAgain = true
            end
            service.capacityRemainingMah = service.capacityReservedMah - service.capacityUsedMah
        end -- mAhSensor ~= ""

        -- Update battery remaining percent
        if service.capacityReservedMah > 0 then
            service.batteryRemainingPercent = math.floor((service.capacityRemainingMah / service.capacityFullMah) * 100)
        end

        service.playPercentRemaining()
        lcd.invalidate()
    end

    return service
end

return lib