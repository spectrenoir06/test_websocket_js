require "js"
local json = require "json"

local node_red = {}
node_red.time = 0
node_red.next_check = 0
node_red.url = "ws://192.168.1.4:1880"

function node_red.onError(...)
	print("error from WS", ...)
end

function node_red:send(url, cmd, f, e)
	local str = [[
		const socket = new WebSocket('%s');
		socket.addEventListener('open', function (event) {
			socket.send('%s');
		});
		socket.addEventListener('message', function (event) {
			_$_(event.data);
			socket.close();
		});
	]]
	str = str:format(self.url..url, cmd, f)
	JS.newPromiseRequest(
		JS.stringFunc(str),
		f or self.onReceive,
		e or self.onError
	)
end

function node_red:update(dt)
	self.time = self.time + dt
	if(JS.retrieveData(dt)) then
		-- return
	else
		if self.time > self.next_check then
			self:send("/ws/update/", "update")
			self.next_check = self.time + 1
		end
	end
end

return node_red