#!/bin/pleal

-- Function to check if a line exists in another string
function lineExists(line, text)
	for match in text:gmatch("[^\r\n]+") do
		if match == line then
			return true
		end
	end
	return false
end

-- Function to compare oldModlist and newModlist line by line
function compareModlists(oldModlist, newModlist)
	local addedMods = ""
	local removedMods = ""

	-- Check for mods added in newModlist
	for newMod in newModlist:gmatch("[^\r\n]+") do
		if not lineExists(newMod, oldModlist) then
			addedMods = "$addedMods  \\+ $newMod \n"
		end
	end

	-- Check for mods removed from oldModlist
	for oldMod in oldModlist:gmatch("[^\r\n]+") do
		if not lineExists(oldMod, newModlist) then
			removedMods = "$removedMods  \\- $oldMod \n"
		end
	end

	return addedMods, removedMods
end

function exec(command)
	local handle = io.popen(command)  -- Open a pipe to the command
	local result = handle:read("*a")  -- Read the entire output
	handle:close()  -- Close the pipe
	return result
end

-- Example usage
local oldModlist = exec("cat modlist.txt")
local newModlist = exec("cd packwiz; packwiz list")

-- Call the function and print the results
local addedMods, removedMods = compareModlists(oldModlist, newModlist)

print(addedMods)
print(removedMods)
