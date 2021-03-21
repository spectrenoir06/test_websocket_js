require 'js'
local json = require "json"


local node_red = {}
node_red.time = 0
node_red.next_check = 0
node_red.url = "ws://192.168.1.163:1880/ws/test/"

function node_red:send()
	local str = [[
		const socket = new WebSocket('%s');
		socket.addEventListener('open', function (event) {
			socket.send('update');
		});
		socket.addEventListener('message', function (event) {
			_$_(event.data);
		});
	]]
	str = str:format(self.url)
	JS.newPromiseRequest(
		JS.stringFunc(str),
		function(...)
			local t = json.decode(...)
			for k,v in ipairs(t) do
				print(k,v, self.onReceive)
				if self.onReceive then
					self.onReceive(v)
				end
			end
		end,
		function(...)
			print("error from js", ...)
		end
	)
end

function node_red:update(dt)
	self.time = self.time + dt
	if(JS.retrieveData(dt)) then
		-- return
	else
		if self.time > self.next_check then
			self:send()
			self.next_check = self.time + 1
		end
	end
end

return node_red