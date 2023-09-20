-- License https://www.gnu.org/licenses/gpl-3.0.en.html
-- OpenTX Lua script
-- TELEMETRY

-- File Locations On The Transmitter's SD Card
--  This script file  /SCRIPTS/WIDGETS/
--  Sound files       /SCRIPTS/WIDGETS/mahRe2/sounds/

-- Works On OpenTX Companion Version: 2.2
-- Works With Sensor: FrSky FAS40S, FCS-150A, FAS100, FLVS Voltage Sensors
--
-- Author: RCdiy
-- Web: http://RCdiy.ca
-- Date: 2016 June 28
-- Update: 2017 March 27
-- Update: 2019 November 21 by Dave Eccleston (Handles sensors returning a table of cell voltages)
-- Update: 2022 July 15 by David Morrison (Converted to OpenTX Widget for Horus and TX16S radios)
--
-- Re-authored: Dean Church
-- Date: 2017 March 25
-- Thanks: TrueBuild (ideas)
--
-- Re-Re-authored: David Morrison
-- Date: 2022 December 1
--
-- Changes/Additions:
-- 	Choose between using consumption sensor or voltage sensor to calculate
--		battery capacity remaining.
--	Choose between simple and detailed display.
--  Voice announcements of percentage remaining during active use.
--  After reset, warn if battery is not fully charged
--  After reset, check cells to verify that they are within VoltageDelta of each other


-- Description
-- 	Reads an OpenTX global variable to determine battery capacity in mAh
--		The sensors used are configurable
-- 	Reads an battery consumption sensor and/or a voltage sensor to
--		estimate mAh and % battery capacity remaining
--		A consumption sensor is a calculated sensor based on a current
--			sensor and the time elapsed.
--			http://rcdiy.ca/calculated-sensor-consumption/
-- 	Displays remaining battery mAh and percent based on mAh used
-- 	Displays battery voltage and remaining percent based on volts
--  Displays details such as minimum voltage, maximum current, mAh used, # of cells
-- 	Write remaining battery mAh to a Tx global variable
-- 	Write remaining battery percent to a Tx global variable
-- 		Writes are optional, off by default
--	Announces percentage remaining every 10% change
--		Announcements are optional, on by default
-- Reserve Percentage
-- 	All values are calculated with reference to this reserve.
--	% Remaining = Estimated % Remaining - Reserve %
--	mAh Remaining = Calculated mAh Remaining - (Size mAh x Reserve %)
--	The reserve is configurable, 20% is the set default
-- 	The following is an example of what is displayed at start up
-- 		800mAh remaining for a 1000mAh battery
--		80% remaining
--
--
-- 	Notes & Suggestions
-- 		The OpenTX global variables (GV) have a 1024 limit.
-- 		mAh values are stored in them as mAh/100
-- 		2800 mAh will be 28
-- 		800 mAh will be 8
--
-- 	 The GVs are global to that model, not between models.
-- 	 Standardize across your models which GV will be used for battery
-- 		capacity. For each model you can set different battery capacities.
-- 	  E.g. If you use GV7 for battery capacity/size then
--					Cargo Plane GV7 = 27
--					Quad 250 has GV7 = 13
--
--	Use Special Functions and Switches to choose between different battery
--		capacities for the same model.
--	E.g.
--		SF1 SA-Up Adjust GV7 Value 10 ON
--		SF2 SA-Mid Adjust GV7 Value 20 ON
--	To play your own announcements replace the sound files provided or
--		turn off sounds
-- 	Use Logical Switches (L) and Special Functions (SF) to play your own sound tracks
-- 		E.g.
-- 			L11 - GV9 < 50
-- 			SF4 - L11 Play Value GV9 30s
-- 			SF5 - L11 Play Track #PrcntRm 30s
-- 				After the remaining battery capacity drops below 50% the percentage
-- 				remaining will be announced every 30 seconds.
-- 	L12 - GV9 < 10
-- 	SF3 - L12 Play Track batcrit
-- 				After the remaining battery capacity drops below 50% a battery
-- 				critical announcement will be made every 10 seconds.

-- Configurations
--  For help using telemetry scripts
--    http://rcdiy.ca/telemetry-scripts-getting-started/

-- GV5: The id of the battery currently in use, will be written into the csv file
-- GV6: The number of cells in the current battery pack
-- GV7: The battery capacity, 8 for 800mAh, 2200 for 2200mAh

local Title = "Flight Battery Monitor"
name = "mahRe2"

-- Do not change the next line
GV = {[1] = 0, [2] = 1, [3] = 2,[4] = 3,[5] = 4,[6] = 5, [7] = 6, [8] = 7, [9] = 8}

function loadSched()
	if not libSCHED then
	-- Loadable code chunk is called immediately and returns libGUI
		libSCHED = loadScript("/WIDGETS/" .. name .. "/libscheduler.lua")
	end

	return libSCHED()
end
--libscheduler = libscheduler or loadSched()

function loadHistory()
	if not libHISTORY then
	-- Loadable code chunk is called immediately and returns libGUI
		libHISTORY = loadScript("/WIDGETS/" .. name .. "/libhistory.lua")
	end

	return libHISTORY()
end
--libhistory = libhistory or loadHistory()

function loadGui()
	if not libGUI then
	-- Loadable code chunk is called immediately and returns libGUI
		libGUI = loadScript("/WIDGETS/" .. name .. "/libgui.lua")
	end

	return libGUI()
end
--libgui = libgui or loadGui()

function loadService()
	if not libSERVICE then
	-- Loadable code chunk is called immediately and returns libGUI
		libSERVICE = loadScript("/WIDGETS/" .. name .. "/libservice.lua")
	end

	return libSERVICE()
end
--libservice = libservice or loadService()

options = {
	{ "mAh", SOURCE, mAh }, -- Defines source Battery Current Sensor
	{ "Voltage", SOURCE, Cels }, -- Defines source Battery Voltage Sensor
	{ "Current", SOURCE, Curr },
	{ "Reset", SOURCE, 125 }, -- Defines the switch to use to reset the stored data
	{ "Throttle", SOURCE, 1 }, -- 204==CH3
	-- { "Color", COLOR, GREY },
}

local function create(zone, options)
	libscheduler = libscheduler or loadSched()
	libhistory = libhistory or loadHistory()
	libgui = libgui or loadGui()
	libservice = libservice or loadService()
	service = libservice.new()
	service.init_func()
	local Context = { zone = zone, options = options }
	return Context
end

local function update(Context, options)
	return service.update(Context, options)
end

local function background(Context)
	service.bg_func()
end

local function refresh(wgt, event, touchState)
	return service.refresh(wgt, event, touchState)
end

--------------------------------------------------------------------------------------------------------------------
---
local function create()
  local sensor = system.getSource("LiPo")
  local mah = system.getSource("mAh")
  local capacity = 5000
  return {sensor=sensor, value=nil, mah = mah, capacity=capacity, sfCapacity={}}
end

local function paint(widget)
  if widget.sensor ~= nil then
    lcd.font(FONT_L)
    local y = 10
    lcd.drawText(10, y, "Total = " .. widget.sensor:stringValue() .. " (" .. widget.sensor:stringValue(OPTION_CELL_COUNT) .. " cells)")
    y = y + 30
    for i = 1, widget.sensor:value(OPTION_CELL_COUNT) do
      lcd.drawText(10, y, "Cell[" .. i .."] = " .. widget.sensor:stringValue(OPTION_CELL_INDEX(i)))
      y = y + 30
    end
	local mahValue = widget.mah:rawValue()
    mahValue = "mAh = " .. mahValue
    lcd.drawText(10, y, mahValue,0)
  end
end

local function wakeup(widget)
  local newValue = nil
  if widget.sensor == nil then
    widget.sensor = system.getSource("LiPo")
  end
  if widget.sensor ~= nil then
    newValue = widget.sensor:stringValue()
  end
  if widget.value ~= newValue then
    widget.value = newValue
    lcd.invalidate()
  end
  lcd.invalidate()
end

local function configure(widget)

    -- Trigger switch position
    --line = form.addLine("flvss")
    --form.addSwitchField(line, form.getFieldSlots(line)[0], function() return widget.triggerswitch end, function(value) widget.triggerswitch = value end)

    -- Battery pack capacity
    line = form.addLine("Capacity")
    local capacity = form.addNumberField(line, nil,100, 10000, function() return widget.capacity end, function(value) widget.capacity = value end)
    capacity:suffix("mAh")
	capacity:default(5000)
	capacity:step(100)

	form.beginExpansionPanel("Special Function Buttons")

	line = form.addLine("Use Special Function Buttons")
    form.addBooleanField(line, form.getFieldSlots(line)[0], function() return widget.useSpecialFunctionButtons end, function(value) widget.useSpecialFunctionButtons = value end)

	for i=1,6,1 do
		line = form.addLine("SF"..i.." Capacity")
		local capacity = form.addNumberField(line, nil,100, 10000, function() return widget.sfCapacity[i] end, function(value) widget.sfCapacity[i] = value end)
		capacity:suffix("mAh")
		capacity:default(sfDefaultValues[i])
		capacity:step(100)
	end

	form.endExpansionPanel()

end


local function read(widget)

	widget.capacity = storage.read("capacity")
	widget.useSpecialFunctionButtons = storage.read("useSpecialFunctionButtons")
	for i=1,6,1 do
		name = "sfCapacity"..i
		value = storage.read(name)
		if value then
			widget.sfCapacity[i] = value
			print("read:"..name.." "..value)
		else
			widget.sfCapacity[i] = sfDefaultValues[i]
			print("setting default value:" .. name .. " " ..sfDefaultValues[i])
		end
	end

end

local function write(widget)
	storage.write("capacity",widget.capacity)
	storage.write("useSpecialFunctionButtons",widget.useSpecialFunctionButtons)
	print("length: "..#widget.sfCapacity)
	for i=1,6,1 do
		name = "sfCapacity"..i
		storage.write("sfCapacity"..i, widget.sfCapacity[i])
		print("writing "..name.." "..widget.sfCapacity[i])
	end
end

local function init()
  system.registerWidget({key=name, name=Title, create=create, paint=paint, wakeup=wakeup, configure=configure, read=read, write=write, persistent=true})
end

return {init=init}