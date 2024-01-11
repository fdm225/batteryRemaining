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
    local capicityLabel = "Capacity: " .. widget.capacityFullMah
    lcd.drawText(w, y, capicityLabel, RIGHT)

    local text_w, text_h = lcd.getTextSize("")
    y = y + text_h + 5
    lcd.font(FONT_XXL)
    local capRemainLabel = math.floor(widget.capacityRemainingMah) .. " mAh"
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
    local gauge_width = math.floor((((box_width - 2) / 100) * widget.batteryRemainingPercent) + 2)
    -- Gauge bar horizontal
    lcd.color(color)
    lcd.drawFilledRectangle(box_left, box_top, gauge_width, box_height)

    -- Gauge frame outline
    lcd.color(lcd.RGB(0, 0, 0))
    lcd.drawRectangle(box_left, box_top, box_width, box_height)
    lcd.drawRectangle(box_left + 1, box_top + 1, box_width - 2, box_height - 2)

    -- Gauge percentage
    lcd.drawText(box_left + box_width / 2, box_top + (box_height - text_h) / 2 + 4, math.floor(widget.batteryRemainingPercent) .. "%", CENTERED)

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
    local gauge_width = math.floor((((box_width - 2) / 100) * widget.batteryRemainingPercent) + 2)
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
    local capicityLabel = math.floor(widget.capacityRemainingMah) .. "/" .. widget.capacityFullMah .. padding
    lcd.drawText(w, y, capicityLabel, RIGHT)
    --
    lcd.font(FONT_XL)
    local text_w, text_h = lcd.getTextSize("")
    --y = y + text_h + 5
    --lcd.drawText(box_left + box_width / 2, box_top + (box_height - text_h) / 2 + 4, math.floor(widget.capacityRemainingMah).."/"..widget.capacityFullMah, CENTERED)
    lcd.drawText(box_left + box_width / 2, box_top + (box_height - text_h) / 2 + 4, math.floor(widget.batteryRemainingPercent) .. "%", CENTERED)

end

----------------------------------------------------------------------------------------------------------------------
local name = "mahRe2"
local key = "mahRe2"

local function create()
    local libservice = libservice or loadService()
    local widget = libservice.new()
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
            function()
                return widget.capacityFullMah
            end,
            function(value)
                widget.capacityFullMah = value
                widget.capacityFullUpdated = true
            end)
    capacity:suffix("mAh")
    capacity:default(5000)
    capacity:step(100)

    if type(form.beginExpansionPanel) == 'function' then
        form.beginExpansionPanel("Special Function Buttons")
        line = form.addLine("Use Special Function Buttons")
        form.addBooleanField(line, form.getFieldSlots(line)[0],
                function() return widget.useSpecialFunctionButtons end,
                function(value) widget.useSpecialFunctionButtons = value end
        )

        for i = 1, 6, 1 do
            line = form.addLine("SF" .. i .. " Capacity")
            local capacity = form.addNumberField(line, nil, 100, 10000,
                    function() return widget.sfCapacityMah[i] end,
                    function(value) widget.sfCapacityMah[i] = value end
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
                function() return widget.useSpecialFunctionButtons end,
                function(value) widget.useSpecialFunctionButtons = value end
        )

        for i = 1, 6, 1 do
            line = form.addLine("SF" .. i .. " Capacity", panel)
            local capacity = form.addNumberField(line, nil, 100, 10000,
                    function() return widget.sfCapacityMah[i] end,
                    function(value) widget.sfCapacityMah[i] = value end,
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
            function() return widget.source end,
            function(value) widget.source = value end
    )

end

local function read(widget)
    print("in read funciton")
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
        if widget.sfCapacityMah[i] == nil then
            widget.sfCapacityMah[i] = sfDefaultValues[i]
        end
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
