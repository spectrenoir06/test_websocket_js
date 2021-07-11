local class = require 'middleclass'
local json = require "json"

local Emote = class('Emote') -- 'Emote' is the class' name

Emote.static.vertice = {}

Emote.static.font = love.graphics.newFont(24)


function Emote:initialize(world, t)

	local t = t or {}

	for k,v in pairs(t) do
		self[k] = v
	end

	self.fake = true

	if self.body then
		self.body:destroy()
	end

	self.body = love.physics.newBody(
		world,
		self.x or (1920/2 + (love.math.random()-0.5)*1800),
		-500 + (love.math.random()-0.5)*1000,
		"dynamic"
	)
	self.body:setFixedRotation(false)

	local shape = love.physics.newCircleShape(56)
	self.fixture = love.physics.newFixture(self.body, shape, 1)
	
	self.fixture:setRestitution(0.90)

	self.speed = 1 + love.math.random() / 10
	self.animeSpeed = 0.2
	self.timer = love.math.random()*10
	self.frame = 1
end

function Emote:drawSprite()
	-- if self.rainbow then
	-- 	local r,g,b = hslToRgb((self.timer*self.speed+self.off/20+0.20)%1, 1, 0.8)
	-- 	love.graphics.setColor(r, g, b)
	-- else
		love.graphics.setColor(1, 1, 1)
	-- end
	
	if self.anim then
		love.graphics.draw(
			self.img,
			self.quads[self.frame],
			self.body:getX(),
			self.body:getY(),
			self.body:getAngle(),
			2,
			2,
			(56/2),
			(56/2)
		)
	else
		love.graphics.draw(
			self.img,
			self.body:getX(),
			self.body:getY(),
			self.body:getAngle(),
			2,
			2,
			(56/2),
			(56/2)
		)
	end
	-- love.graphics.setColor(1,0,0)
	-- love.graphics.circle("fill", v.body:getX(), v.body:getY(), 4)
end

function Emote:drawName()
end

function Emote:update(dt)
	if self.anim then
		self.timer = self.timer + dt
		self.frame = (math.floor(self.timer/self.animeSpeed)%self.frame_nb)+1
	end
end

return Emote