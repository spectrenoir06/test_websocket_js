require 'js'

function love.load()
end

function love.draw()
end

function love.keypressed(key, scancode, isrepeat)
	if key == "space" then
		love.filesystem.write( "test", "hello")
		JS.newPromiseRequest(JS.stringFunc(
		[[
			const socket = new WebSocket('wss://echo.websocket.org');
				
			socket.addEventListener('open', function (event) {
				socket.send('Hello Server!');
			});
				
			socket.addEventListener('message', function (event) {
				console.log('Message from server ', event.data);
				_$_(event.data);
			});
		]]),
		print,
		print
		)
	elseif key == "a" then
		local list = love.filesystem.getDirectoryItems("/")
		for k,v in ipairs(list) do
			print(k,v)
		end
	end
end

function love.update(dt)
	if(JS.retrieveData(dt)) then
		-- return
	end
end

 -- __storeWebDB(event.data, "FILE_DATA", _@_);