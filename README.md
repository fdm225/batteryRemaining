This is a port of the OpenTX maRe2 script to ethos.  Calculates and calls out the battery percent remaining during flights

Requires a FrSky current sensor (FAS40, FAS100, FAS150, or FAS300)

  ![image](https://github.com/fdm225/batteryRemaining/assets/1608096/c5151441-b1b5-436a-bb89-a5cbc72be149)


- Installation:
  copy lua files and sounds directory into the scripts/mahRe2 folder

- Setup Options
Reset Switch: Reset switch to reset the mah available back to the match (e.g. start over)
Capacity: Capacity of the lipo battery pack
Use Special Function Buttons: Enable the use of the special function buttons for preset battery pack sizes
SF1-SF6 Capacity: Capacity presets tied to the special function buttons
Source: The sensor name to monitor  (e.g. Current)



![image](https://github.com/fdm225/batteryRemaining/assets/1608096/79b4adf4-dc4b-465f-a529-2129b453eb5e)
![image](https://github.com/fdm225/batteryRemaining/assets/1608096/d7568942-aceb-4611-9bea-352930b28091)


Note: The tool automatically subtracts 20% from the battery packs so that if you take it to 0 the pack is not completely dead (though not suggested)

Author takes no responsibilites for bugs, issues, crashes, overall don't blame me if something goes horribly wrong.
