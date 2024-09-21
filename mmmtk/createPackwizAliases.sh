#!/usr/bin/pleal

--[[
	This file is part of the MMMTK
	
	MMMTK Copyright (c) 2023 MisterNoNameLP

   MMMTK is free software: you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation, either version 3 of the License, or
   (at your option) any later version.

   MMMTK is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with MMMTK.  If not, see <https://www.gnu.org/licenses/>.
]]

local version = "1.1.5"

--===== local vars =====--
local lfs = require("lfs")
local ut = require("UT")
local argparse = require("argparse")
local posix = require("posix")

local args 
local listFileHandler

do --arg parsing 
	local parser = argparse("createPackwizAliases", "PackwizDownloadFileCollector")

	parser:flag("-v --version", "Prots the version and exits."):action(function() 
		print("PackwizDownloadFileCollector v$version")
		os.exit(0)
	end)

	parser:option("-u --url --pack-url", "Target url where files are goinf to be stored"):count(1):target("baseDownloadURI")
	parser:option("-i --input", "Input dir"):count(1):target("inputDir")
	parser:option("-o --output", "Output dir"):count(1):target("outputDir")
	parser:option("-l --list-file", "File containing a list of already collectet files"):count(1):target("listFile")
	
	parser:flag("-O --overwrite", "Overwrites already existing toml files"):target("overwrite")
	parser:flag("-R --remove", "Removes all previously added toml files before collecting new ones"):target("remove")
	parser:flag("-C --clear", "Removes all previously added toml files and exits"):target("clear")

	args = parser:parse()
end

--===== local functions =====--
local function fileExists(path)
	local file = io.open(path, "r")
	local fileExists = false
	if file ~= nil then
		fileExists = true
		file:close()
	end
	return fileExists
end
--[[This function is ripped from DAMS v0.19.1_v1-prev41
	https://github.com/MisterNoNameLP/dams
]]
local function exec(cmd, pollTimeout)
	local execString = ""
	local handlerFile, handlerFileDescriptor, events
	local discriptorList = {}
	local returnSignal
	local tmpOutput, output = "", ""
	 
	execString = execString .. " " .. cmd .. " 2>&1; printf \"\n\$?\""

	handlerFile = io.popen(execString, "r")

	--make poopen file stream non blocking
	handlerFileDescriptor = posix.fileno(handlerFile)
	discriptorList[handlerFileDescriptor] = {events = {IN = true}}
	pollTimeout = math.floor((pollTimeout or 0.01) * 1000)

	while true do
		events = posix.poll(discriptorList)
		--reading handler file
		tmpOutput = handlerFile:read("*a")
		if tmpOutput then
			output = output .. tmpOutput
		end

		if events > 0 and discriptorList[handlerFileDescriptor].revents.HUP then
			break
		end
	end

	--reading rest of handler file
	tmpOutput = handlerFile:read("*a")
	if tmpOutput then
		output = output .. tmpOutput
	end
	handlerFile:close()

	--getting exec exit code
	for s in string.gmatch(output, "[^\n]+") do
		returnSignal = s
	end

	output = output:sub(0, -(len(returnSignal) + 2))

	if returnSignal ~= "0" then
		print("Exec failed")
		print(output)
		print("Aborting")
		os.exit(1)
	end

	return tonumber(returnSignal), output
end
local function collectFiles(path, side, initialPath)
	if not initialPath then
		initialPath = path
	end
	for file in lfs.dir(path) do
		if string.sub(file, 1, 1) ~= "." then
			local filePath = path .. "/" .. file
			local attributes = lfs.attributes(filePath)
			if attributes.mode == "directory" then
				collectFiles(filePath, side, initialPath)
			else
				print("Found raw file: $filePath")
				local _, name, ending = ut.seperatePath(file)
				local pureName, fileHash
				local tomlFileName, tomlFilePath, tomlFileExists, tomlFile, tomlFileString
				local addTomlFile = true

				for name in name:gmatch("[%w]+") do
					pureName = name
					break
				end
				tomlFileName = "${pureName}${ending}.pw.toml"
				tomlFilePath = "$args.outputDir/" .. path:sub(len(initialPath) + 2) .. "/$tomlFileName"

				tomlFileExists = fileExists(tomlFilePath)
				if tomlFileExists and args.overwrite then
					print("WARN: Overwriting toml file")
				elseif tomlFileExists then
					print("ERROR: Toml file already exists")
					addTomlFile = false
				end

				if addTomlFile then
					print("Adding toml file: $tomlFilePath")
					exec("mkdir -p $args.outputDir/" .. path:sub(len(initialPath) + 2))
					tomlFile = io.open(tomlFilePath, "w")

					_, fileHash = exec("sha1sum $filePath")
					for hash in fileHash:gmatch("[%w]+") do
						fileHash = hash
						break
					end

					tomlFileString = [[
name = "$pureName$ending"
filename = "$file"
side = "$side"

[download]
url = "$args.baseDownloadURI/$filePath"
hash-format = "sha1"
hash = "$fileHash"
					]]

					tomlFile:write(tomlFileString)
					tomlFile:close()
					listFileHandler:write("$tomlFilePath\n")
				end
			end
		end
	end
end

--===== init =====--

--===== prog start =====--
--clear files
if args.remove or args.clear then
	print("Remove previously added files")
	listFileHandler = io.open(args.listFile, "r")
	if listFileHandler then
		for line in io.lines(args.listFile) do 
			if fileExists(line) then
				print("Remove file: $line")
				exec("rm $line")
			end
		end
		listFileHandler:close()
	end
	listFileHandler = io.open(args.listFile, "w")
	if args.clear then 
		listFileHandler:close()
		print("Cleaning done")
		os.exit()
	end
else
	listFileHandler = io.open(args.listFile, "a")
end

--add files
collectFiles("${args.inputDir}/server", "server")
collectFiles("${args.inputDir}/client", "client")
collectFiles("${args.inputDir}/both", "both")

listFileHandler:close()