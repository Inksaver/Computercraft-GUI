local version = 20250914.1600
--[[
	pastebin(1) 9LETv15f lib.Class.lua
	pastebin(2) vNARV362
	this code based on youtube dot com watch?v=Jte9o4S6rlo&list=PLZVNxI_lsRW2kXnJh2BMb6D82HCAoSTUB
	Thanks to pixelbytestudios dot com for a brilliant tutorial seies on Lua and Love2d
	Adapted for use in ccTweaked / computercraft by Inksaver youtube dot com/@Inksaver
]]
--generic class table
local Class = {}
Class.__index = Class --metamethod to index itself
function Class:new() end

-- create new class type 
function Class:derive(classType)
	assert(classType ~= nil, "parameter classType must not be nil")
	assert(type(classType) == "string", "parameter classType must be string")
	local cls = {}
	cls["__call"] = Class.__call
	cls.type = classType
	cls.__index = cls
	cls.super = self
	setmetatable(cls, self) -- allows inheritance
	return cls
end

-- allow table to be treated as a function
function Class:__call(...)
	local inst = setmetatable({}, self) --create instance of Class
	inst:new(...)
	return inst
end

function Class:is(class)
	assert(class ~= nil, "parameter class must not be nil")
	assert(type(class) == "table", "parameter class must be of type Class")
	local mt = getmetatable(self)
	while mt do
		if mt == class then return true end
		mt = getmetatable(mt)
	end
	return false
end

function Class:isType(classType)
	assert(classType ~= nil, "parameter classType must not be nil")
	assert(type(classType) == "string", "parameter classType must be string")
	local base = self
	while base do
		if base.type == classType then return true end
		base = base.super
	end
	return false
end

function Class:getType()
	return self.type
end

return Class