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

local function paint4th(widget)
    -- 1/4 scree 388x132 (supported)
    local y = 0
    local w, h = lcd.getWindowSize()
    local color = lcd.RGB(0xF8, 0xB0, 0x38)
    lcd.font(FONT_XS)
    local capicityLabel = "Capacity: " .. widget.service.capacityFullMah
    lcd.drawText(w, y, capicityLabel, RIGHT)

    local text_w, text_h = lcd.getTextSize("")
    y = y + text_h + 5
    lcd.font(FONT_XXL)
    local capRemainLabel = math.floor(widget.service.capacityRemainingMah) .. " mAh"
    lcd.drawText(w / 2, y, capRemainLabel, CENTERED)

    local text_w,
    text_h = lcd.getTextSize("")
    y = y + text_h + 5
    local box_top = y
    local box_height = h - y - 4
    local box_left = 4
    local box_width = w - 8

    -- Gauge background
    lcd.color(lcd.RGB(200, 200, 200))
    lcd.drawFilledRectangle(box_left, box_top, box_width, box_height)

    -- Gauge Percentage to width calculation
    local gauge_width = math.floor((((box_width - 2) / 100) * widget.service.batteryRemainingPercent) + 2)
    -- Gauge bar horizontal
    lcd.color(color)
    lcd.drawFilledRectangle(box_left, box_top, gauge_width, box_height)

    -- Gauge frame outline
    lcd.color(lcd.RGB(0, 0, 0))
    lcd.drawRectangle(box_left, box_top, box_width, box_height)
    lcd.drawRectangle(box_left + 1, box_top + 1, box_width - 2, box_height - 2)

    -- Gauge percentage
    lcd.drawText(box_left + box_width / 2, box_top + (box_height - text_h) / 2 + 4, math.floor(widget.service.batteryRemainingPercent) .. "%", CENTERED)

end

local function paint6th(widget)
    -- 1/4 scree 388x132 (supported)
    local y = 0
    local w, h = lcd.getWindowSize()
    local color = lcd.RGB(0xF8, 0xB0, 0x38)


    --lcd.font(FONT_XXL)
    --local capRemainLabel = math.floor(widget.capacityRemainingMah) .. " mAh"
    --lcd.drawText(w / 2, y, capRemainLabel, CENTERED)
    --
    --local text_w, text_h = lcd.getTextSize("")
    --y = y + text_h + 5

    local box_top = y
    local box_height = h - y - 4
    local box_left = 4
    local box_width = w - 8

    -- Gauge background
    lcd.color(lcd.RGB(200, 200, 200))
    lcd.drawFilledRectangle(box_left, box_top, box_width, box_height)

    -- Gauge Percentage to width calculation
    local gauge_width = math.floor((((box_width - 2) / 100) * widget.service.batteryRemainingPercent) + 2)
    -- Gauge bar horizontal
    lcd.color(color)
    lcd.drawFilledRectangle(box_left, box_top, gauge_width, box_height)

    -- Gauge frame outline
    lcd.color(lcd.RGB(0, 0, 0))
    lcd.drawRectangle(box_left, box_top, box_width, box_height)
    lcd.drawRectangle(box_left + 1, box_top + 1, box_width - 2, box_height - 2)

    -- Gauge percentage
    lcd.font(FONT_XS)
    local padding = "  "
    y = y + 2
    local capicityLabel = math.floor(widget.service.capacityRemainingMah) .. "/" .. widget.service.capacityFullMah .. padding
    lcd.drawText(w, y, capicityLabel, RIGHT)
    --
    lcd.font(FONT_XL)
    local text_w, text_h = lcd.getTextSize("")
    --y = y + text_h + 5
    --lcd.drawText(box_left + box_width / 2, box_top + (box_height - text_h) / 2 + 4, math.floor(widget.service.capacityRemainingMah).."/"..widget.service.capacityFullMah, CENTERED)
    lcd.drawText(box_left + box_width / 2, box_top + (box_height - text_h) / 2 + 4, math.floor(widget.service.batteryRemainingPercent) .. "%", CENTERED)

end

----------------------------------------------------------------------------------------------------------------------
local name = "mahRe2"
local key = "mahRe2"

local function create()
    local libservice = libservice or loadService()
    local serviceStarted = false
    if not g_mahRe2Service then
        g_mahRe2Service = libservice.new()
        serviceStarted = true
    end

    widget = {
        service = g_mahRe2Service,
        serviceStarted = serviceStarted
    }
    return widget
end

local function paint(widget)

    local w, h = lcd.getWindowSize()
    if w == 388 and h == 132 then
        paint4th(widget)
    elseif w == 300 and h == 66 then
        paint6th(widget)
    else
        paint4th(widget)
    end

end

local function wakeup(widget)
    widget.service.bg_func()
end

local function configure(widget)

    --line = form.addLine("mAh")
    --form.addSourceField(line, nil, function() return widget.mAh end, function(value) widget.mah = value end)


    -- reset switch position
    line = form.addLine("Reset Switch")
    form.addSwitchField(line, form.getFieldSlots(line)[0], function()
        return widget.service.resetSwitch
    end, function(value)
        widget.service.resetSwitch = value
    end)
    --resetSwitch:default("SF╚")


    -- Battery pack capacity
    line = form.addLine("Capacity")
    local capacity = form.addNumberField(line, nil, 100, 10000,
            function()
                return widget.service.capacityFullMah
            end,
            function(value)
                widget.service.capacityFullMah = value
                widget.service.capacityFullUpdated = true
            end)
    capacity:suffix("mAh")
    capacity:default(5000)
    capacity:step(100)

    if type(form.beginExpansionPanel) == 'function' then
        form.beginExpansionPanel("Special Function Buttons")
        line = form.addLine("Use Special Function Buttons")
        form.addBooleanField(line, form.getFieldSlots(line)[0],
                function() return widget.service.useSpecialFunctionButtons end,
                function(value) widget.service.useSpecialFunctionButtons = value end
        )

        for i = 1, 6, 1 do
            line = form.addLine("SF" .. i .. " Capacity")
            local capacity = form.addNumberField(line, nil, 100, 10000,
                    function() return widget.service.sfCapacityMah[i] end,
                    function(value) widget.service.sfCapacityMah[i] = value end
            )
            capacity:suffix("mAh")
            capacity:default(sfDefaultValues[i])
            capacity:step(100)
        end
        form.endExpansionPanel()
    else
        panel = form.addExpansionPanel("Special Function Buttons")
        line = form.addLine("Use Special Function Buttons", panel)
        form.addBooleanField(line, form.getFieldSlots(line)[0],
                function() return widget.service.useSpecialFunctionButtons end,
                function(value) widget.service.useSpecialFunctionButtons = value end
        )

        for i = 1, 6, 1 do
            line = form.addLine("SF" .. i .. " Capacity", panel)
            local capacity = form.addNumberField(line, nil, 100, 10000,
                    function() return widget.service.sfCapacityMah[i] end,
                    function(value) widget.service.sfCapacityMah[i] = value end,
                    panel
            )
            capacity:suffix("mAh")
            capacity:default(sfDefaultValues[i])
            capacity:step(100)
        end
        panel:open(false)
    end

    line = form.addLine("Source")
    form.addSourceField(line, nil,
            function() return widget.service.source end,
            function(value) widget.service.source = value end
    )

end

local function read(widget)
    print("in read funciton")
    widget.service.resetSwitch = storage.read("resetSwitch")
    --widget.service.resetSwitch = system.getSource({category=CATEGORY_SWITCH, member=17})
    -- widget.service.resetSwitch = system.getSource({category=10, member=17})
    ----if not widget.service.resetSwitch then
    ----    widget.service.resetSwitch = system.getSource("SF╚")
    ----end
    widget.service.capacityFullMah = storage.read("capacity")
    if not widget.service.capacityFullMah then
        widget.service.capacityFullMah = defaultPackCapacityMah
    end
    widget.service.capacityFullUpdated = true
    widget.service.useSpecialFunctionButtons = storage.read("useSpecialFunctionButtons")
    for i = 1, 6, 1 do
        local specialFunctionButton = "sfCapacityMah" .. i
        value = storage.read(specialFunctionButton)
        if value then
            widget.service.sfCapacityMah[i] = value
            print("read:" .. specialFunctionButton .. " " .. value)
        else
            widget.service.sfCapacityMah[i] = sfDefaultValues[i]
            print("setting default value:" .. specialFunctionButton .. " " .. sfDefaultValues[i])
        end
    end

end

local function write(widget)
    storage.write("resetSwitch", widget.service.resetSwitch)
    storage.write("capacity", widget.service.capacityFullMah)
    storage.write("useSpecialFunctionButtons", widget.service.useSpecialFunctionButtons)
    print("length: " .. #widget.service.sfCapacityMah)
    for i = 1, 6, 1 do
        if widget.service.sfCapacityMah[i] == nil then
            widget.service.sfCapacityMah[i] = sfDefaultValues[i]
        end
        local specialFunctionButton = "sfCapacityMah" .. i
        storage.write("sfCapacityMah" .. i, widget.service.sfCapacityMah[i])
        print("writing " .. specialFunctionButton .. " " .. widget.service.sfCapacityMah[i])
    end
end

local function init()
    system.registerWidget({ key = key, name = name, create = create, paint = paint, wakeup = wakeup,
                            configure = configure, read = read, write = write, persistent = true })
end

return { init = init }
