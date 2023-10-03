-- define default values
local sfDefaultValues = { 4000, 4500, 5000, 5200, 6000, 8200 }
local defaultPackCapacityMah = 5000

function loadSched()
    if not libSCHED then
        -- Loadable code chunk is called immediately and returns libGUI
        libSCHED = loadfile("libscheduler.lua")
    end
    return libSCHED()
end

function loadService()
	if not libSERVICE then
	-- Loadable code chunk is called immediately and returns libGUI
		libSERVICE = loadfile("libservice.lua")
	end

	return libSERVICE()
end

----------------------------------------------------------------------------------------------------------------------
local name = "Flight Battery Monitor"
local key = "mahRe2"

local function create()
    local libservice = libservice or loadService()
    local widget = libservice.new()
    return widget
end

local function paint(widget)
    y = 30
    lcd.drawText(10, y, "capacity: " .. widget.capacityFullMah)
    lcd.drawText(10, y + 30, "mAh remaining: " .. widget.capacityRemainingMah)
    lcd.drawText(10, y + 60, "percent remaining: " .. widget.batteryRemainingPercent)
end

local function wakeup(widget)
    widget.bg_func()
end

local function configure(widget)

    --line = form.addLine("mAh")
    --form.addSourceField(line, nil, function() return widget.mAh end, function(value) widget.mah = value end)


    -- reset switch position
    line = form.addLine("Reset Switch")
    form.addSwitchField(line, form.getFieldSlots(line)[0], function()
        return widget.resetSwitch
    end, function(value)
        widget.resetSwitch = value
    end)
    --resetSwitch:default("SF╚")


    -- Battery pack capacity
    line = form.addLine("Capacity")
    local capacity = form.addNumberField(line, nil, 100, 10000,
            function() return widget.capacityFullMah end,
            function(value)
                widget.capacityFullMah = value
                widget.capacityFullUpdated = true
            end)
    capacity:suffix("mAh")
    capacity:default(5000)
    capacity:step(100)

    form.beginExpansionPanel("Special Function Buttons")

    line = form.addLine("Use Special Function Buttons")
    form.addBooleanField(line, form.getFieldSlots(line)[0], function()
        return widget.useSpecialFunctionButtons
    end, function(value)
        widget.useSpecialFunctionButtons = value
    end)

    for i = 1, 6, 1 do
        line = form.addLine("SF" .. i .. " Capacity")
        local capacity = form.addNumberField(line, nil, 100, 10000, function()
            return widget.sfCapacityMah[i]
        end, function(value)
            widget.sfCapacityMah[i] = value
        end)
        capacity:suffix("mAh")
        capacity:default(sfDefaultValues[i])
        capacity:step(100)
    end

    form.endExpansionPanel()

    line = form.addLine("Source")
    form.addSourceField(line, nil, function()
        return widget.source
    end, function(value)
        widget.source = value
    end)

end

local function read(widget)
    widget.resetSwitch = storage.read("resetSwitch")
    --widget.resetSwitch = system.getSource({category=CATEGORY_SWITCH, member=17})
    -- widget.resetSwitch = system.getSource({category=10, member=17})
    ----if not widget.resetSwitch then
    ----    widget.resetSwitch = system.getSource("SF╚")
    ----end
    widget.capacityFullMah = storage.read("capacity")
    if not widget.capacityFullMah then
        widget.capacityFullMah = defaultPackCapacityMah
    end
    widget.capacityFullUpdated = true
    widget.useSpecialFunctionButtons = storage.read("useSpecialFunctionButtons")
    for i = 1, 6, 1 do
        local specialFunctionButton = "sfCapacityMah" .. i
        value = storage.read(specialFunctionButton)
        if value then
            widget.sfCapacityMah[i] = value
            print("read:" .. specialFunctionButton .. " " .. value)
        else
            widget.sfCapacityMah[i] = sfDefaultValues[i]
            print("setting default value:" .. specialFunctionButton .. " " .. sfDefaultValues[i])
        end
    end

end

local function write(widget)
    storage.write("resetSwitch", widget.resetSwitch)
    storage.write("capacity", widget.capacityFullMah)
    storage.write("useSpecialFunctionButtons", widget.useSpecialFunctionButtons)
    print("length: " .. #widget.sfCapacityMah)
    for i = 1, 6, 1 do
        local specialFunctionButton = "sfCapacityMah" .. i
        storage.write("sfCapacityMah" .. i, widget.sfCapacityMah[i])
        print("writing " .. specialFunctionButton .. " " .. widget.sfCapacityMah[i])
    end
end

local function init()
    system.registerWidget({ key = key, name = name, create = create, paint = paint, wakeup = wakeup,
                            configure = configure, read = read, write = write, persistent = true })
end

return { init = init }
