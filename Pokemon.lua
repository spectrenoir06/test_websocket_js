local class = require 'middleclass'
local json = require "json"

local Pokemon = class('Pokemon') -- 'Pokemon' is the class' name

Pokemon.static.vertice = {}

local data = json.decode(love.filesystem.read("pokemon32/test.json"))
for i=0, 150 do Pokemon.static.vertice[i+1] = data["pokemon32-"..i] end

Pokemon.static.pkm_data = require("pokemon32/pkm")

Pokemon.static.img = love.graphics.newImage("pokemon32/pokemon32.png")
Pokemon.static.img:setFilter("nearest")

Pokemon.static.font = love.graphics.newFont(24)

Pokemon.static.quads = {}
for x=0, 150 do
	local t = {}
	for y=0,1 do
		table.insert(t, love.graphics.newQuad(x*32,y*32,32,32,Pokemon.static.img:getDimensions()))
	end
	table.insert(Pokemon.static.quads, t)
end

function Pokemon:initialize(world, t)
	-- self.sweetness = sweetness

	local t = t or {}

	for k,v in pairs(t) do
		self[k] = v
	end

	if self.body then
		self.body:destroy()
	end

	self.body = love.physics.newBody(
		world,
		self.x or (1920/2 + (love.math.random()-0.5)*1800),
		-500 + (love.math.random()-0.5)*1000,
		"dynamic"
	)
	self.body:setFixedRotation(true)

	self.nb = self.nb or Pokemon.static.pkm_data.starter[love.math.random( 1, #Pokemon.static.pkm_data.starter)] --love.math.random( 1, 151)
	self.size = self.size or 3

	for i,v in ipairs(Pokemon.static.vertice[self.nb]) do
		local t = {}
		for j, w in ipairs(v.shape) do
			t[j] = (w-16) * self.size
		end
		local shape = love.physics.newPolygonShape(t)
		self.fixture = love.physics.newFixture(self.body, shape, 1)
	end

	self.fixture:setRestitution(0.90)
	-- self.off = love.math.random()*10
	self.speed = 1 + love.math.random() / 10
	self.animeSpeed = 0.2
	self.timer = love.math.random()*10
	self.frame = 1
	-- pkm[new.id] = new
end

function Pokemon:drawSprite()
	-- if self.rainbow then
	-- 	local r,g,b = hslToRgb((self.timer*self.speed+self.off/20+0.20)%1, 1, 0.8)
	-- 	love.graphics.setColor(r, g, b)
	-- else
		love.graphics.setColor(1, 1, 1)
	-- end
	love.graphics.draw(
		Pokemon.static.img,
		Pokemon.static.quads[self.nb][self.frame],
		self.body:getX(),
		self.body:getY(),
		self.body:getAngle(),
		self.size,
		self.size,
		(32/2),
		(32/2)
	)
	-- love.graphics.setColor(1,0,0)
	-- love.graphics.circle("fill", v.body:getX(), v.body:getY(), 4)
end

function Pokemon:drawName()
	love.graphics.setColor(0,0,0)
	love.graphics.setFont(Pokemon.static.font)
	local max_w = 200
	local x,y = self.body:getWorldCenter()
	love.graphics.printf(
		self.dispname or "Roger",
		x-max_w/2-1,
		y-15*self.size+1,
		max_w,
		"center"
	)
	if type(self.color) == "table" then
		love.graphics.setColor(self.color)
	else
		love.graphics.setColor(1,0,1)
	end
	love.graphics.printf(
		self.dispname or "Roger",
		x-max_w/2,
		y-15*self.size,
		max_w,
		"center"
	)
end

function Pokemon:update(dt)
	self.timer = self.timer + dt
	self.frame = (math.floor(self.timer/self.animeSpeed)%2)+1
end

return Pokemon