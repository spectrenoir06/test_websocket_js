-- print(package.path)
-- package.path = package.path..";./lib/?.lua;./lib/?/init.lua;./lib/?/?.lua"
-- print(package.path)
love.filesystem.setRequirePath("?.lua;?/init.lua;lib/?.lua;lib/?/init.lua;lib/?/?.lua")

require 'js'
local json = require "json"
local node_red = require "node_red"
local Pokemon = require "Pokemon"
local Matrix = require "Matrix"

local pkm_data = require("pokemon32/pkm")

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

local function hex(hex) 
	local redColor,greenColor,blueColor=hex:match('#(..)(..)(..)')
	-- print(hex,redColor, greenColor, blueColor)
	redColor, greenColor, blueColor = tonumber(redColor, 16)/255, tonumber(greenColor, 16)/255, tonumber(blueColor, 16)/255
	return redColor, greenColor, blueColor
end

function save_pkm()
	node_red:send("/ws/save_player/", matrix:to_json(), function(v)
		print("save_pkm()")
	end)
end

local emotes_img = {}

function load_from_fs(emote, file)
	local file_data = love.filesystem.newFileData(file, '')
	if file_data:getSize() > 0 then
		local img_data = love.image.newImageData(file_data)
		local img = love.graphics.newImage(img_data)
		new_emote = {
			img = img,
			img_data = img_data,
			lx = img:getWidth(),
			ly = img:getHeight(),
			anim = emote.anim
		}
		if emote.anim then
			print("LOAD IMG Dynamic")
			new_emote.frame_nb = new_emote.lx / new_emote.ly
			new_emote.quads = {}
			local size = new_emote.ly
			for x=0, new_emote.frame_nb -1 do
				table.insert(new_emote.quads, love.graphics.newQuad(x*size, 0, size, size, new_emote.img:getDimensions()))
			end
			-- emotes_img[emote.str].fre
		else
			print("LOAD IMG Static")
		end
		emotes_img[emote.str] = new_emote
	end
end

node_red.onReceive = function(data)
	print(data)
	local t = json.decode(data)
	for k, msg in pairs(t) do
		if msg.type == "tchat" then
			-- local p, id = get_pkm_from_userstate(msg.userstate)

			if msg.userstate["emotes-raw"] then
				local emotes_raw = msg.userstate["emotes-raw"]
				msg.emotes_t = {}
				for id,b in emotes_raw:gmatch('([0-9a-z_]+):([%d%-%,]+)') do
					msg.emotes_t[id] = {}
					msg.emotes_t[id].pos = {}
					msg.emotes_t[id].id = id
					local nb = 0
					for c,d in b:gmatch('(%d+)%-(%d+)') do
						table.insert(msg.emotes_t[id].pos, {tonumber(c),tonumber(d)})
						msg.emotes_t[id].str = msg.message:sub(c+1, d+1)
						nb = nb + 1
					end
					msg.emotes_t[id].nb = nb
					print("NB = ", nb)
				end
				msg.emotes_by_pos = {}
				for k,v in pairs(msg.emotes_t) do
					-- print(k,v)
					for l,w in ipairs(v.pos) do
						-- print(k,v,l,w)
						table.insert(msg.emotes_by_pos, {
							str = v.str,
							id = k,
							pos = w,
							nb = #v.pos
						})
					end
				end
				table.sort(msg.emotes_by_pos, function(a,b)
					return a.pos[1] < b.pos[1]
				end)
				

				for key,v in pairs(msg.emotes_t) do
					print(k, v.str)

					print(v.str, v.id)
					if not emotes_img[v.str] then
						local file = nil -- = love.filesystem.read("cache/emotes/"..k..".png")
						if not file then
							node_red:send("/ws/dl_emote/", "http://antoine.doussaud.org/twitch_proxy/emoticons/v2/"..v.id.."/default/light/2.0", function(data)
								-- print(data)
								print("receive img", v.str, data)
								local t = json.decode(data)
								v.anim = t.anim
								file = love.data.decode("string", "base64", t.data)
								if file then
									love.filesystem.write("cache/emotes/"..v.id..".png", file)
									-- load_from_fs(v.str, img, t.anim)
									load_from_fs(v, file)
									print(v.nb)
									for i=1, v.nb do
										matrix:spawn_emote(emotes_img[v.str])
									end
								else
									print("can't load from twitch", url)
								end	
							end)
						else
							print("load from cache", "cache/emotes/"..v.id..".png")
						end

						-- if file then 
						-- 	matrix:spawn_emote(emotes_t[v.str])
						-- 	load_from_fs(v, file)
						-- end
					else
						for i=1, v.nb do
							matrix:spawn_emote(emotes_img[v.str])
						end
					end
				end
			end
			
			
			local p = matrix.pkm[msg.userstate["user-id"]]
			local r,g,b = 1,1,1
			if (msg.userstate.color) then
				r,g,b = hex(msg.userstate.color)
			end
			local color = {r,g,b}
			if not p then
				print(msg.message)
				str = str.."\n"..msg.message
				local new = matrix:spawn({
					username = msg.userstate.username,
					dispname = msg.userstate["display-name"],
					color = color,
					id = msg.userstate["user-id"]
				})
			else
				-- print(hex(msg.userstate.color))
				p.body:applyLinearImpulse(-love.math.random()*200*p.size, -300*p.size)
				p.color = color
				-- p:recevieMsg()
				-- p.size = p.size + 0.05
			end

			if (msg.message:match("!stuck")) then
				local p = matrix.pkm[msg.userstate["user-id"]]
				p.x = 1500
				matrix:spawn(p)
			end

			if msg.userstate["custom-reward-id"] == "474e36e6-0ec6-4c22-8925-7b3076b1b181" then -- new random
				matrix:spawn({
					username = msg.userstate.username,
					dispname = msg.userstate["display-name"],
					color = color,
					id = msg.userstate["user-id"]
				})
			elseif msg.userstate["custom-reward-id"] == "53251096-1376-4cfd-a9ab-7a57ea11b57e" then -- set pkm
				local nb = tonumber(msg.message)
				if nb > 0 and nb < 152 then
					matrix:spawn({
						username = msg.userstate.username,
						dispname = msg.userstate["display-name"],
						id = msg.userstate["user-id"],
						color = color,
						nb = pkm_data.starter[love.math.random( 1, #pkm_data.starter)]
					})
				end
			elseif msg.userstate["custom-reward-id"] == "b1b4c2c7-cd9b-453f-866f-d74b65a0e77f" then -- big
				matrix:spawn({
					username = msg.userstate.username,
					dispname = msg.userstate["display-name"],
					id = msg.userstate["user-id"],
					color = color,
					size = 10,
					nb = p.nb
				})
			elseif msg.userstate.username == "spectrenoir06" then -- set pkm
				if (msg.message:match("!set_nb @(.+) (.+)")) then
					local user, nb = msg.message:match("!set_nb @(.+) (.+)")
					nb = tonumber(nb)
					if user and nb then
						local p = matrix:get_pkm_from_dispname(user)
						if nb > 0 and nb < 152 and p then
							p.nb = nb
							matrix:spawn(p)
						end
					end
				elseif (msg.message:match("!set_size @(.+) (.+)")) then
					local user, nb = msg.message:match("!set_size @(.+) (.+)")
					nb = tonumber(nb)
					if user and nb then
						local p = matrix:get_pkm_from_dispname(user)
						if (p) then
							if nb > 0 and nb < 100000 then
								p.size = nb
								matrix:spawn(p)
							end
						end
					end
				end
			end
			save_pkm()
		end
	end
end




function love.load()
	love.graphics.setBackgroundColor(0,0,0,0)

	local list = love.filesystem.getDirectoryItems("/")
	for k,v in pairs(list) do
		print(k,v)
		if v:match("__temp*") then
			print("REMOVE", v)
			love.filesystem.remove(v)
		end
	end

	love.filesystem.createDirectory("cache")
	love.filesystem.createDirectory("cache/emotes")

	matrix = Matrix:new()

	node_red:send("/ws/load_player/", "load_player", function(v)
		local t = json.decode(v)
		print("Receive", v)
		for k,v in pairs(t) do
			matrix:spawn(v)
		end
	end)

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

	matrix:draw()


	-- local y = 0
	-- love.graphics.setColor(1, 1, 1)
	-- for k,v in pairs(emotes_img) do
	-- 	love.graphics.draw(v.img, 0, y)
	-- 	y = y + 64
	-- end

	-- love.graphics.print(str, 10, 10)
	
end

local test_id = 1

function love.keypressed(key, scancode, isrepeat)
	print(key, scancode)
	if key == "space" then
		-- spawn(10)?
		matrix:spawn({
			fake = true,
			id = tostring(test_id)
		})
		test_id = test_id + 1
		save_pkm()
	elseif key == "q" then
		-- pkm[1].body:applyLinearImpulse((love.math.random()-.5)*500, -1000)
		matrix:kill_fake()
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
	matrix:update(dt)
end
