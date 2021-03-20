require 'js'

local i = 0

function send()
	local str = [[
		console.log('send');
		const socket = new WebSocket('ws://192.168.1.163:1880/ws/test/');
			
		socket.addEventListener('open', function (event) {
			socket.send('%d');
		});
			
		socket.addEventListener('message', function (event) {
			console.log('Message from server ', event.data);
			_$_(event.data);
		});
	]]
	str = str:format(i)
	i = i + 1
	JS.newPromiseRequest(JS.stringFunc(str),
	function(...)
		print("return from js", ...)
	end,
	function(...)
		print("error from js", ...)
	end
	)
end

function love.load()

end

function love.draw()
end

function love.keypressed(key, scancode, isrepeat)
	if key == "space" then


	send()

	elseif key == "a" then
		local list = love.filesystem.getDirectoryItems("/")
		for k,v in ipairs(list) do
			print(k,v)
		end
	end
end

function love.update(dt)
	if(JS.retrieveData(dt)) then
		return
	end
end

 -- __storeWebDB(event.data, "FILE_DATA", _@_);