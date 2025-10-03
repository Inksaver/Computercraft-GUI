local version = 20251003.1700

local Scene 	= require("lib.Scene")
local Label 	= require("lib.ui.Label")
local MultiLabel= require("lib.ui.MultiLabel")
local Button 	= require("lib.ui.Button")
local S 		= Scene:derive("GetItems")
local WIDTH, HEIGHT = term.getSize()-- 39 x 13 turtle terminal

--[[
	Inventory structure:
	table of inventoryItems:
	inventory[1] = {item, quantity, required?, comment} eg {"slab", "R.length + 2", false, "Match slabs & roof blocks"}
	can also be a table of inventoryItems eg {{items}, {quantities}, {required?}, {comments}}
	Must be same number of elements in all tables eg 3 items need 3 quantities, required? and comments
	inventory[2] =
	{
		{"planks", "stairs", "stone"},
		{
			"(R.height * R.length * 2) + (R.height * R.width * 2)",
			"(R.height * R.length * 2) + (R.height * R.width * 2)",
			"(R.height * R.length * 2) + (R.height * R.width * 2)"
		},
		{true, true, true},
		{"Select block type", " for desired style", ""}
	},
quantity can be numerical or expression to be parsed
]]

function S:new(sceneMgr)
	-- display list of items required
	-- use inventory events to update labels
	
	S.super.new(self, sceneMgr)
	self.lblTitle = Label("lblTitle", 7,  1, WIDTH - 11, 1, "`black¬white` Items:`red¬white` required `white¬green` optional ", colors.black, colors.white, "centre", "centre")
	self.lblInfo = Label("lblInfo", 1,  HEIGHT, WIDTH, 1, "Add required Items", colors.black, colors.white, "centre", "centre")
	--Button:new(name, x, y, w, h, text, fg, bg, alignH, alignV, index, keyBind, scene)
	self.btnBack  = Button("btnBack", 1, 1, 6, 1, "Back", colors.lime, colors.gray, "centre", "centre", 0, "b", "GetItems" )
	self.btnNext  = Button("btnNext", WIDTH - 5, 1, 6, 1, "Next", colors.lime, colors.lightGray, "centre", "centre", 0, "n", "GetItems" )
	
	--local labels = {"aquired", "sep", "expected", "item", "required"}	-- row of 5 labels (names) 
	--local sizes  = {{3, 1}, {1, 1}, {3, 1}, {WIDTH-15, 1}, {8, 1}}	-- width / height of each row
	local labels = {"item", "expected", "aquired", "required"}	-- row of 4 labels (names) 
	local sizes  = {{30, 1}, {4, 1}, {4, 1}, {1, 1}}	-- width / height of each row
	local colours = {{colors.black, colors.yellow},{colors.gray, colors.yellow},
					 {colors.white, colors.black},{colors.gray, colors.red}}
	local alignments = {{"left","centre"}, {"left", "centre"}, {"left", "centre"}, {"left","centre"}}
	
	--ML:new(name, x, y, w, h, text, fg, bg, alignH, alignV, labels, sizes, colours, alignments)
	self.mlDisplay = MultiLabel("mlDisplay", 1,  2, WIDTH, HEIGHT - 1, "", colors.white, colors.black, "centre", "centre",
								labels, sizes, colours, alignments)
	--self.inventory = {}
	--self.inventoryCheck = {}
	--self.itemsRequired = {}
	
	self.em:add(self.lblTitle, 		"lblTitle")
	self.em:add(self.btnBack, 		"btnBack")
	self.em:add(self.btnNext, 		"btnNext")
	self.em:add(self.mlDisplay, 	"mlDisplay")
	self.em:add(self.lblInfo, 		"lblInfo")

	self.btnClick = function(button) self:onBtnClick(button) end
end

function S:setup()
	local lib = {}
	
	function lib.processName(name)
		local start = name:find("\:")
		if  start ~= nil then
			return name:sub(start +1)
		end
		return name
	end
	-- called before self.em.switch()
	-- display list of items required
	--[[
	inventory =
	{
		{"minecraft:bucket", 1, false, ""},
		{"minecraft:ladder", "math.abs(R.height - R.currentLevel)", true, ""},
		{"minecraft:torch", "math.floor(math.abs(R.height - R.currentLevel) / 3)", false, ""},
		{"stone", "math.abs(R.height - R.currentLevel)", true, ""},
		{{"slab","stone"}, {1, 3}, true, "Slab can be crafted from 3 stone"},
		{{"minecraft:packed_ice", "minecraft:blue_ice"}, {"math.ceil(R.length / 2)", "math.ceil(R.length / 2)"}, false, "If required"}
	}
	4 rows of labels required
	col1 (aquired) = "0" | col2 (expected) = "1" | col3 (item) = "minecraft:bucket" | col4 (required) = red:true, green:false
	add any comment to col3 in different colours
	col1 updated when inventory is used
	-- eg data = {{"0", "64", "stone", true}, {"0", "1", "Torch", false}}
	]]
	--self.task = U.currentTask						-- eg  "Ladder up or down"
Log:saveToLog("GetItems:setup() R.inventoryKey  = "..R.inventoryKey)	
	local inv = nil		-- initialise table
	if R.inventoryKey == "" then
		inv = F[U.currentTask].inventory
	else
		inv = F[U.currentTask].inventory[R.inventoryKey]
	end
Log:saveToLog("\nInventory = "..textutils.serialise(inv, {compact = true}))
	--[[ inventory as recorded in taskInventory.lua
	eg this inventory has only 1 inventoryItem, with a choice of 3 materials: inventory = 
	{
	[1]={
			{"stone","planks","bricks"},
			{
				"(R.height * R.length * 2) + (R.height * R.width * 2)",
				"(R.height * R.length * 2) + (R.height * R.width * 2)",
				"(R.height * R.length * 2) + (R.height * R.width * 2)"
			},
			{true,true,true},
			{"","",""}
		} 
	}
	This inventory has 4 inventoryItems: inventory = 
	{
		[1] = {"minecraft:water_bucket",3},
		[2] = {{"minecraft:soul_sand","minecraft:dirt",},{1,1,},{true,true,},{"if available","as placeholder"}},
		[3] = {"stone","R.height * 2",false,""},
		[4] = {"minecraft:bucket","T:getEmptySlotCount",false,"buckets = speed"},
	}
	]]

	self.inventory = {}			-- initialise tables
	self.inventoryCheck = {}
	self.itemsRequired = {}		-- contains items only
	-- create a sanitised version of the inventory from taskInventory.lua to store in self.inventory
	-- eg {{"minecraft:bucket","minecraft:water_bucket"}, {R.height, R.height}, {true, true}, {"", ""}},
	-- -> {{"bucket","water_bucket"}, {2, 2}, {0, 0}, {true, true}}, item(s), quantity(s), aquired, required
	-- This is passed to the MultiLabel for display (self.mlDisplay:setup(self.inventory))
	
	-- At the same time create a table of items for self.itemsRequired
	for k, v in ipairs(inv) do	-- eg {{"minecraft:bucket","minecraft:water_bucket"}, {2, 2}, {true, true}, {"", ""}},
		-- v[1] = items, v[2] = quantities numeric/ expressions, v[3] = required true/false, v[4] = string comments
		local tempInventory = {}	-- temporary table to hold {items, quantities, aquired, required} for self.inventory
		local tempItems = {}		-- temporary table to hold {items, quantities,          required} for self.itemsRequired
		local useTable = false		-- flag
		-- if first value of inventoryItem is a table, all following values are also tables of the same size
		if type(v[1]) == "table" then				-- eg {"minecraft:soul_sand","minecraft:dirt",}
			useTable = true
			for i = 1, #v[1] do						-- change names to shorter versions
				v[1][i] = lib.processName(v[1][i])	-- {"minecraft:soul_sand","minecraft:dirt"} -> {"soul_sand","dirt"}
			end
		else
			v[1] = lib.processName(v[1])			-- eg {"minecraft:water_bucket"} -> {"water_bucket"}
			-- ? v[1] = {lib.processName(v[1])} ??
		end
		table.insert(tempItems, v[1])				-- add items table to tempItems
		table.insert(tempInventory, v[1])			-- [1] either "stone" or {"slab","stone"}
		-- read quantities later v[2]
		--[[if v[3] == nil then						-- v[3] = required true/false
			if useTable then
				v[3] = {false, false}
			else
				v[3] = false
			end
		end
		if v[4] == nil then							-- v[4] = comments
			if useTable then
				v[4] = {"", ""}
			else
				v[4] = ""
			end
		end]]
		-- get quantities
		if useTable then										-- {"math.ceil(R.length / 2)", "math.ceil(R.length / 2)"}
			local quantities = {}
Log:saveToLog("S:setup() ipairs(v[2]) = "..textutils.serialise(v[2], {compact = true}))
			for _, exp in ipairs(v[2]) do
				local amount = U.parseExpression(exp)
				Log:saveToLog("S:setup() for _, item in ipairs(v[2]) exp = "..exp..", amount = "..amount)
				table.insert(quantities, amount)
			end
			table.insert(tempInventory, quantities)				-- [2]
			table.insert(tempItems, quantities)
			
			-- aquired field is used when passed to MultiLabel, should consist of {0, ...}
			local aquired = {}
			for i = 1, #v[1] do
				table.insert(aquired, 0)
			end
			table.insert(tempInventory, aquired)				-- aquired always starts as {0, 0,..}
			
			table.insert(tempInventory, v[3])					-- [3] required true/false already in table form
			table.insert(tempItems, v[3])
			if v[4][1] ~= "" then
				tempInventory[1][1] = tempInventory[1][1].." (".. v[4][1]..")"		-- add comment onto item
			end
			if v[4][2] ~= "" then
				tempInventory[1][2] = tempInventory[1][2].." (".. v[4][2]..")"
			end
		else	-- single quantity
--Log:saveToLog("Expression  = "..v[2])
			local amount = U.parseExpression(v[2])	-- eg 1 or "math.abs(R.height - R.currentLevel)"
			table.insert(tempInventory, math.abs(amount))	-- [2] quantities
			table.insert(tempItems, math.abs(amount))
			table.insert(tempInventory, 0)					-- aquired always 0 or {0,..}
			--table.insert(tempItems, 0)
			table.insert(tempInventory, v[3])				-- [4] required true/false
			table.insert(tempItems, v[3])
			if v[4] ~= "" then
				tempInventory[1] = tempInventory[1].." (".. v[4]..")"	-- add comment onto item
			end
		end
		if type(tempInventory[2]) == "table" then
			table.insert(self.inventoryCheck, math.max(tempInventory[2][1], tempInventory[2][2]))
		else
			table.insert(self.inventoryCheck, tempInventory[2])
		end
		table.insert(self.inventory, tempInventory)
		table.insert(self.itemsRequired, tempItems)
	end
Log:saveToLog("self.itemsRequired = "..textutils.serialise(self.itemsRequired, {compact = true}))
	--Log:saveToLog("\ndata = "..textutils.serialise(self.inventory, {compact = true}))
	--[[ self.inventory = 
	{
		{"water_bucket",3,0,false},
		{{"soul_sand (if available)","dirt (as placeholder)"},{1,1},{0,0},{true,true}},
		{"stone",148,0,false},
		{"bucket (buckets = speed)",16,0,false},
	}
	]]
	--Log:saveToLog("\ninventoryCheck = "..textutils.serialise(self.inventoryCheck, {compact = true}))
	-- self.inventoryCheck = {3,1,148,16}
	--Log:saveToLog("\nitemsRequired = "..textutils.serialise(self.itemsRequired, {compact = true}))
	--[[ self.itemsRequired = 
	{
		{"water_bucket",3,0},
		{{"minecraft:soul_sand","minecraft:dirt"},{1,1},{0,0}},
		{"stone",148,0},
		{"bucket",16,0}
	}
	]]
	self.mlDisplay:setup(self.inventory)
	self:checkInventory()
end

function S:checkInventory()
	local lib = {}
	
	function lib.checkInventory(items, quantities, quantitiesFound, tInventory)
		-- items and quantities are always tables
Log:saveToLog("lib.checkInventory(items = "..textutils.serialise(items, {compact = true}))
Log:saveToLog("lib.checkInventory(quantities = "..textutils.serialise(quantitiesFound, {compact = true}))
Log:saveToLog("lib.checkInventory(quantitiesFound = "..textutils.serialise(quantitiesFound, {compact = true}))
Log:saveToLog("lib.checkInventory(tInventory = "..textutils.serialise(tInventory, {compact = true}))		
		local incomplete = true 							-- return value. set to false if not enough put in the inventory for this item / group of items
		--local quantitiesFound = {} 						-- table of quantities found, based on no of items needed
		--for i = 1, #quantities do							-- Initialise table eg {0, 0, 0}	
			--table.insert(quantitiesFound, 0)
		--end 
		for i = 1, #quantitiesFound do
			quantitiesFound[i] = 0
		end
		for i = 1, #items do 								-- check if item(s) already present
			local findItem = items[i]
			for k, v in pairs(tInventory) do 				-- eg: {"minecraft:cobblestone" = 128, "minecraft:dirt" = 203}
				if findItem:find("\:") ~= nil then 			-- specific item requested eg "minecraft:cobblestone"
					if findItem == k then 					-- exact match eg "minecraft:cobblestone" requested, "minecraft:cobblestone" found
						item = k							-- item = "minecraft:cobblestone"
						quantitiesFound[i] = v
					end
				else 										-- non specific eg "log", "pressure_plate", "stone"
					if findItem == "stone" then 			-- check for allowed blocks in global table stone
						for _, stonetype in ipairs(U.stone) do
							if k == stonetype then			-- k = "minecraft:cobblestone" matches with stonetype
								quantitiesFound[i] = quantitiesFound[i] + v
							end
						end
					elseif k:find(findItem) ~= nil then 	-- similar item exists already eg "pressure_plate" is in "minecraft:stone_pressure_plate"
						quantitiesFound[i] = quantitiesFound[i] + v
					end
				end
			end
		end
		Log:saveToLog("lib.checkInventory({"..items[1]..", "..tostring(items[2])..
					  "}, required = {"..quantities[1]..", "..tostring(quantities[2])..
					  "}, found = {".. quantitiesFound[1]..", ".. tostring(quantitiesFound[2]).."}")
		local totalFound = 0
		for i = 1, #quantities do
			totalFound = totalFound + quantitiesFound[i]
			if totalFound >= quantities[i] then
				incomplete = false
			end
		end
		if incomplete then -- update quantities
			for i = 1, #quantitiesFound do
				quantitiesFound[i] = totalFound -- when player asked to supply alternatives, this gives quantities
			end
		end
		Log:saveToLog("lib.checkInventory() return: incomplete = "..tostring(incomplete)..", totalFound = "..totalFound)
		return incomplete, totalFound --, quantitiesFound
	end
	
	local tInventory = T:getInventoryItems() 	-- create table of blocktypes and quantities
Log:saveToLog("T:getInventoryItems() = "..textutils.serialise(tInventory, {compact = true}))
	-- table eg: {"minecraft:cobblestone" = 256, "minecraft:cobbled_deepslate = 256"}
	-- iterate items list and look for match
	local ready = true
	--for row, v in ipairs(self.inventory) do	-- {{"minecraft:bucket",1,0,false}, {"minecraft:ladder",10,0,true}, {{"slab","stone"}, {1, 3}, {0, 0}, {false, false}}}
	for row, v in ipairs(self.inventory) do
	--for row, v in ipairs(self.itemsRequired) do	-- {"water_bucket",3,0}, {{"minecraft:soul_sand","minecraft:dirt"},{1,1},{0,0}},
		-- check if each item or group of items is completed
		local incomplete, totalFound, quantitiesFound = false, 0, {}
		local isTable = false
		if type(v[1]) == "table" then		-- {"minecraft:soul_sand","minecraft:dirt"}
			isTable = true
			incomplete, totalFound, quantitiesFound = lib.checkInventory(v[1], v[2], v[3], tInventory)		-- {"minecraft:soul_sand","minecraft:dirt"}, {1, 1}, {0,0}
		else								-- "minecraft:bucket"
			incomplete, totalFound, quantitiesFound = lib.checkInventory({v[1]}, {v[2]}, {v[3]}, tInventory)	-- {"minecraft:bucket", 1, 0}
		end
		-- change the button text in self.mlDisplay
		if incomplete then
			self.mlDisplay:setButtonData({row, 3}, {{"text", tostring(totalFound)}, {"fg", colors.red}})
		else
			self.mlDisplay:setButtonData({row, 3}, {{"text", tostring(totalFound)}, {"fg", colors.lime}})
		end
		if isTable then
			--Log:saveToLog("required[] = "..tostring(v[4][1]))
			if v[4][1] or v[4][2] then	-- required
				if totalFound < v[2][1] and totalFound < v[2][2] then	-- if less than BOTH quantities
					ready = false
				end
			end
		else
			Log:saveToLog("required = "..tostring(v[4]))
			if totalFound < v[2] and v[4] then
				ready = false
			end
		end
	end
	if ready then
		self.lblInfo:setText("Required items loaded. Click 'Next'")
		self.lblInfo:setColours(colors.white, colors.red)
	else
		self.lblInfo:setText("Add required Items")
		self.lblInfo:setColours(colors.black, colors.white)
	end
end

function S:enter()
	S.super.enter(self)

	_G.events:hook("onBtnClick", self.btnClick)    
end

function S:exit()
	S.super.exit(self)
	
	_G.events:unhook("onBtnClick", self.btnClick)    
end

function S:onBtnClick(button)
	Log:saveToLog("S:onBtnClick("..button.name..")")
	if button.name == "btnBack" then
		-- back button goes to "TaskOptions" if taskInventory.data ~= nil
		U.keyboardInput = ""
		if F[U.currentTask].data == nil then				
			self.sceneMgr:switch("MainMenu")
		else		-- options need to be set
			self.sceneMgr:switch("TaskOptions")
		end
	elseif button.name == "btnNext" then
		-- start the process 
		--U.currentTask = "test"	-- debugging only. comment out when completed
		U.executeTask = true
	end
end

function S:update(data)
	self.super.update(self, data)
	if data ~= nil then
		-- b and n are actioned in Button:update
		if data[1] == "turtle_inventory" then
			Log:saveToLog("GetItems:update calling self:checkInventory")
			self:checkInventory()	
		end
	end
end

function S:draw()
	self.super.draw(self)
end

return S
