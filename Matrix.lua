local class = require 'middleclass'

local Matrix = class('Matrix') -- 'Matrix' is the class' name

local Pokemon = require "Pokemon"
local Emote = require "Emote"
local json = require "json"

-- Matrix.static.vertice = {}


function Matrix:initialize()
	love.physics.setMeter(64)
	self.world = love.physics.newWorld(0, 9.81*64, true)

	self.pkm = {}

	local ground = {}
	ground.body = love.physics.newBody(self.world, 1920/2, 1080+50/2)
	ground.shape = love.physics.newRectangleShape(1920+100, 50)
	ground.fixture = love.physics.newFixture(ground.body, ground.shape)

	local top = {}
	top.body = love.physics.newBody(self.world, 1920/2, -1080-50/2)
	top.shape = love.physics.newRectangleShape(1920+100, 50)
	top.fixture = love.physics.newFixture(top.body, ground.shape)

	local left = {}
	left.body = love.physics.newBody(self.world, -50/2, 0)
	left.shape = love.physics.newRectangleShape(50, 1080*2)
	left.fixture = love.physics.newFixture(left.body, left.shape)

	local right = {}
	right.body = love.physics.newBody(self.world, 1920+50/2, 0)
	right.shape = love.physics.newRectangleShape(50, 1080*2)
	right.fixture = love.physics.newFixture(right.body, right.shape)

end


function Matrix:draw()
	for i,v in pairs(self.pkm) do
		v:drawSprite()
	end

	for i,v in pairs(self.pkm) do
		v:drawName()
	end

	if debug_physic then
		love.graphics.setColor(1,1,1,0.3)
		for _, body in pairs(self.world:getBodies()) do
			for _, fixture in pairs(body:getFixtures()) do
				local shape = fixture:getShape()
		
				if shape:typeOf("CircleShape") then
					local cx, cy = body:getWorldPoints(shape:getPoint())
					love.graphics.circle("fill", cx, cy, shape:getRadius())
				elseif shape:typeOf("PolygonShape") then
					love.graphics.polygon("fill", body:getWorldPoints(shape:getPoints()))
				else
					love.graphics.line(body:getWorldPoints(shape:getPoints()))
				end
			end
		end
	end
end

function Matrix:update(dt)
	self.world:update(dt)
	for i,v in pairs(self.pkm) do
		v:update(dt)
	end
end

function Matrix:spawn(t)
	self.pkm[t.id] = Pokemon:new(self.world, t)
	return self.pkm[t.id]
end

function Matrix:spawn_emote(t)
	table.insert(self.pkm, Emote:new(self.world, t))
	return self.pkm[t.id]
end

function Matrix:to_json()
	local t = {}
	for i,v in pairs(self.pkm) do
		if not v.fake then
			t[v.id] = {
				-- userstate = v.userstate,
				nb = v.nb,
				size = v.size,
				username = v.username,
				dispname = v.dispname,
				id = v.id,
				color = v.color
			}
		end
	end
	return json.encode(t)
end

function Matrix:get_pkm_from_username(username)
	for k,v in pairs(self.pkm) do
		if v.username == username then
			return v, k
		end
	end
	return false
end

function Matrix:get_pkm_from_dispname(dispname)
	for k,v in pairs(self.pkm) do
		if v.dispname == dispname then
			return v, k
		end
	end
	return false
end

function Matrix:kill_fake()
	for k,v in pairs(self.pkm) do
		if v.fake then
			v.body:destroy()
			self.pkm[k] = nil
		end
	end
	return false
end

return Matrix