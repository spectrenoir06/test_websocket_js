require 'js'
local json = require "json"
local node_red = require "node_red"

local i = 0
local str = ""

function hslToRgb(h, s, l, a)
	local r, g, b
	if s == 0 then
		r, g, b = l, l, l -- achromatic
	else
		function hue2rgb(p, q, t)
			if t < 0   then t = t + 1 end
			if t > 1   then t = t - 1 end
			if t < 1/6 then return p + (q - p) * 6 * t end
			if t < 1/2 then return q end
			if t < 2/3 then return p + (q - p) * (2/3 - t) * 6 end
			return p
		end
		local q
		if l < 0.5 then q = l * (1 + s) else q = l + s - l * s end
		local p = 2 * l - q

		r = hue2rgb(p, q, h + 1/3)
		g = hue2rgb(p, q, h)
		b = hue2rgb(p, q, h - 1/3)
	end

	return r, g, b, a
end

node_red.onReceive = function(msg)
	print(msg, msg.type)
	if msg.type == "tchat" then
		print(msg, msg.message)
		str = str.."\n"..msg.message
		spawn(1)
	end
end

function spawn(nb)
	nb = nb or 1
	for i=1,nb do
		local new = {}
		new.body = love.physics.newBody(world, 1920/2 + (math.random()-0.5)*1800, -50, "dynamic")
		new.body:setAngularVelocity(math.random()-0.5)
		new.shape = love.physics.newCircleShape(22/2)
		new.fixture = love.physics.newFixture(new.body, new.shape, 1)
		new.off = math.random() * 10
		new.speed = 1 + math.random() / 10
		table.insert(ditto, new)
	end
end

function love.load()

	img = love.graphics.newImage("ditto.png")
	quads = {}
	for x=0, 3 do
		table.insert(quads, love.graphics.newQuad(x*33, 0, 33, img:getHeight(), img:getDimensions()))
	end
	ditto = {}

	love.physics.setMeter(64)
	world = love.physics.newWorld(0, 9.81*64, true)


	local ground = {}
	ground.body = love.physics.newBody(world, 1920/2, 1080+50/2)
	ground.shape = love.physics.newRectangleShape(1920, 50)
	ground.fixture = love.physics.newFixture(ground.body, ground.shape)

	local left = {}
	left.body = love.physics.newBody(world, -50/2, 1080/2)
	left.shape = love.physics.newRectangleShape(50, 1080)
	left.fixture = love.physics.newFixture(left.body, left.shape)

	local right = {}
	right.body = love.physics.newBody(world, 1920+50/2, 1080/2)
	right.shape = love.physics.newRectangleShape(50, 1080)
	right.fixture = love.physics.newFixture(right.body, right.shape)

	love.graphics.setBackgroundColor(1,0,1)
end

function love.draw()
	
	-- for _, body in pairs(world:getBodies()) do
	-- 	for _, fixture in pairs(body:getFixtures()) do
	-- 		local shape = fixture:getShape()
	
	-- 		if shape:typeOf("CircleShape") then
	-- 			local cx, cy = body:getWorldPoints(shape:getPoint())
	-- 			love.graphics.circle("fill", cx, cy, shape:getRadius())
	-- 		elseif shape:typeOf("PolygonShape") then
	-- 			love.graphics.polygon("fill", body:getWorldPoints(shape:getPoints()))
	-- 		else
	-- 			love.graphics.line(body:getWorldPoints(shape:getPoints()))
	-- 		end
	-- 	end
	-- end

	for i,v in ipairs(ditto) do
		local r,g,b = hslToRgb((time*v.speed+v.off/20+0.20)%1, 1, 0.8)
		love.graphics.setColor(r, g, b)
		love.graphics.draw(
			img,
			quads[(math.floor((time*v.speed+v.off)*10)%(#quads))+1],
			v.body:getX(),
			v.body:getY(),
			v.body:getAngle(),
			1,
			1,
			33/2,
			40/2
		)
	end

	love.graphics.print(str, 10, 10)

end

function love.keypressed(key, scancode, isrepeat)
	if key == "space" then
		send()
	elseif key == "q" then
		spawn(100)
	elseif key == "a" then
		local list = love.filesystem.getDirectoryItems("/")
		for k,v in ipairs(list) do
			print(k,v)
		end
	end
end

time = 0
local next_check = 0

function love.update(dt)
	time = time + dt
	node_red:update(dt)
	world:update(dt)
end
