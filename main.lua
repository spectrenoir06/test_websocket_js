require 'js'
local json = require "json"
local node_red = require "node_red"

local pkm_data = require("pokemon32/pkm")

local i = 0
local str = ""
local vertice = {}

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

local function hex(hex) 
	local redColor,greenColor,blueColor=hex:match('#(..)(..)(..)')
	-- print(hex,redColor, greenColor, blueColor)
	redColor, greenColor, blueColor = tonumber(redColor, 16)/255, tonumber(greenColor, 16)/255, tonumber(blueColor, 16)/255
	return redColor, greenColor, blueColor
end

-- function get_pkm_from_userstate(userstate)
-- 	for k,v in ipairs(pkm) do
-- 		if v.userstate and (v.userstate.username == userstate.username) then
-- 			v.userstate = userstate
-- 			return v, k
-- 		end
-- 	end
-- 	return false
-- end

function save_pkm()
	node_red:send("/ws/save_player/", pkm2json(pkm), function(v)
		print("save_pkm()")
	end)
end

node_red.onReceive = function(data)
	-- print(data)
	local t = json.decode(data)
	for k, msg in pairs(t) do
		if msg.type == "tchat" then
			-- local p, id = get_pkm_from_userstate(msg.userstate)
			local p = pkm[msg.userstate["user-id"]]
			local r,g,b = hex(msg.userstate.color)
			local color = {r,g,b}
			if not p then
				print(msg.message)
				str = str.."\n"..msg.message
				local new = spawn_pkm({
					username = msg.userstate.username,
					dispname = msg.userstate["display-name"],
					color = color,
					id = msg.userstate["user-id"]
				})
			else
				-- print(hex(msg.userstate.color))
				p.body:applyLinearImpulse((love.math.random()-.5)*500, -300)
				p.color = color
				p.size = p.size + 0.05
			end

			if msg.userstate["custom-reward-id"] == "474e36e6-0ec6-4c22-8925-7b3076b1b181" then -- new random
				spawn_pkm({
					username = msg.userstate.username,
					dispname = msg.userstate["display-name"],
					color = color,
					id = msg.userstate["user-id"]
				})
			elseif msg.userstate["custom-reward-id"] == "53251096-1376-4cfd-a9ab-7a57ea11b57e" then -- set pkm
				local nb = tonumber(msg.message)
				if nb > 0 and nb < 152 then
					spawn_pkm({
						username = msg.userstate.username,
						dispname = msg.userstate["display-name"],
						id = msg.userstate["user-id"],
						color = color,
						nb = pkm_data.starter[love.math.random( 1, #pkm_data.starter)]
					})
				end
			end

			

			save_pkm()
		end
	end
end

function spawn(nb)
	nb = nb or 1
	for i=1,nb do
		local new = {}
		new.body = love.physics.newBody(world, 1920/2 + (love.math.random()-0.5)*1800, -50, "dynamic")
		new.body:setAngularVelocity(love.math.random()-0.5)
		new.shape = love.physics.newCircleShape(22/2)
		new.fixture = love.physics.newFixture(new.body, new.shape, 1)
		new.off = love.math.random() * 10
		new.speed = 1 + love.math.random() / 10
		table.insert(ditto, new)
	end
end

function spawn_pkm(t)
	local new = t or {}
	new.body = love.physics.newBody(world, 1920/2 + (love.math.random()-0.5)*1800, -500 + (love.math.random()-0.5)*1000, "dynamic")
	-- new.body:setFixedRotation(true)
	-- new.body:setAngularVelocity(love.math.random()-0.5)
	-- print(pkm_data)
	new.nb = new.nb or pkm_data.starter[love.math.random( 1, #pkm_data.starter)] --love.math.random( 1, 151)
	new.size = t.size or 3--new.size or (love.math.random()+1)*4
	-- print(vertice[new.nb])

	for i,v in ipairs(vertice[new.nb]) do
		-- print(i,v)
		local t = {}
		for j, w in ipairs(v.shape) do
			t[j] = (w-16) * new.size
		end
		local shape = love.physics.newPolygonShape(t)
		-- new.shape = love.physics.newRectangleShape(16*new.size, 16*new.size)
		new.fixture = love.physics.newFixture(new.body, shape, 1)
	end

	-- new.shape = love.physics.newRectangleShape(16*new.size, 16*new.size)
	-- new.fixture = love.physics.newFixture(new.body, new.shape, 1)
	new.fixture:setRestitution(0.80)
	new.off = love.math.random() * 10
	new.speed = 1 + love.math.random() / 10
	
	pkm[new.id] = new
	return new
end

function love.load()
	font = love.graphics.newFont(24)
	data = json.decode(love.filesystem.read("pokemon32/test.json"))
	-- print(data)
	for i=0, 150 do
		-- print(data["pokemon32-"..i][1].shape, i+1)
		vertice[i+1] = data["pokemon32-"..i]
	end

	img = love.graphics.newImage("ditto.png")
	
	quads = {}
	for x=0, 3 do
		table.insert(quads, love.graphics.newQuad(x*33, 0, 33, img:getHeight(), img:getDimensions()))
	end

	pkm_img = love.graphics.newImage("pokemon32/pokemon32.png")
	pkm_img:setFilter("nearest")
	pkm_quads = {}
	for x=0, 150 do
		local t = {}
		for y=0,1 do
			table.insert(
				t,
				love.graphics.newQuad(
					x*32,
					y*32,
					32,
					32,
					pkm_img:getDimensions()
				)
			)
		end
		table.insert(pkm_quads, t)
	end
	pkm = {}

	ditto = {}
	
	love.physics.setMeter(64)
	world = love.physics.newWorld(0, 9.81*64, true)


	local ground = {}
	ground.body = love.physics.newBody(world, 1920/2, 1080+50/2)
	ground.shape = love.physics.newRectangleShape(1920+100, 50)
	ground.fixture = love.physics.newFixture(ground.body, ground.shape)

	local top = {}
	top.body = love.physics.newBody(world, 1920/2, -1080-50/2)
	top.shape = love.physics.newRectangleShape(1920+100, 50)
	top.fixture = love.physics.newFixture(top.body, ground.shape)

	local left = {}
	left.body = love.physics.newBody(world, -50/2, 0)
	left.shape = love.physics.newRectangleShape(50, 1080*2)
	left.fixture = love.physics.newFixture(left.body, left.shape)

	local right = {}
	right.body = love.physics.newBody(world, 1920+50/2, 0)
	right.shape = love.physics.newRectangleShape(50, 1080*2)
	right.fixture = love.physics.newFixture(right.body, right.shape)

	love.graphics.setBackgroundColor(0,0,0,0)

	node_red:send("/ws/load_player/", "load_player", function(v)
		local t = json.decode(v)
		print("Receive", v)
		for k,v in pairs(t) do
			spawn_pkm(v)
		end
	end)

end

function pkm2json(pkm)
	local t = {}
	for i,v in pairs(pkm) do
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
		-- print(i,v)
	end
	return json.encode(t)
end

tx=0
ty=0

-- restore position with the right mouse button:
function love.mousepressed(x, y, button, istouch)
	if button == 2 then
		tx = 0
		ty = 0
	end
end

function love.draw()
	
	mx = love.mouse.getX()
	my = love.mouse.getY()
	if love.mouse.isDown(1) then
		if not mouse_pressed then
			mouse_pressed = true
			dx = tx-mx
			dy = ty-my
		else
			tx = mx+dx
			ty = my+dy
		end
	elseif mouse_pressed then
		mouse_pressed = false
	end
	love.graphics.translate(tx, ty)
	
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
	
	local frame = (math.floor(time*10)%2)+1
	-- print(frame, (math.floor(time)%2))
	
	for i,v in pairs(pkm) do
		if v.rainbow then
			local r,g,b = hslToRgb((time*v.speed+v.off/20+0.20)%1, 1, 0.8)
			love.graphics.setColor(r, g, b)
		else
			love.graphics.setColor(1, 1, 1)
		end
		love.graphics.draw(
			pkm_img,
			pkm_quads[v.nb][frame],
			v.body:getX(),
			v.body:getY(),
			v.body:getAngle(),
			v.size,
			v.size,
			(32/2),
			(32/2)
		)

		-- love.graphics.setColor(1,0,0)
		-- love.graphics.circle("fill", v.body:getX(), v.body:getY(), 4)
	end

	for i,v in pairs(pkm) do
		love.graphics.setColor(0,0,0)
		love.graphics.setFont(font)
		local max_w = 200
		local x,y = v.body:getWorldCenter()
		love.graphics.printf(
			v.dispname or "Roger",
			x-max_w/2-1,
			y-15*v.size+1,
			max_w,
			"center"
		)
		love.graphics.setColor(v.color or {1,1,1})
		love.graphics.printf(
			v.dispname or "Roger",
			x-max_w/2,
			y-15*v.size,
			max_w,
			"center"
		)
	end


	if debug_physic then
		love.graphics.setColor(1,1,1,0.3)
		for _, body in pairs(world:getBodies()) do
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
	-- love.graphics.print(str, 10, 10)
	
end

local test_id = 1

function love.keypressed(key, scancode, isrepeat)
	print(key, scancode)
	if key == "space" then
		-- spawn(10)?
		spawn_pkm({
			fake = true,
			id = tostring(test_id)
		})
		test_id = test_id + 1
		save_pkm()
	elseif key == "q" then
		-- pkm[1].body:applyLinearImpulse((love.math.random()-.5)*500, -1000)
		for k,v in pairs(pkm) do
			if v.fake then
				pkm[k] = nil
			end
		end
		--spawn(100)
	elseif key == "a" then
		local list = love.filesystem.getDirectoryItems("/")
		for k,v in ipairs(list) do
			print(k,v)
		end
	elseif key == "w" then
		debug_physic = not debug_physic
	end
end

time = 0
local next_check = 0
local next_spawn = 0

function love.update(dt)
	time = time + dt
	node_red:update(dt)
	world:update(dt)
end
