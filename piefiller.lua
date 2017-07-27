local path = ...
local piefiller = {}

local function hsvToRgb(h, s, v)
	local i, f, p, q, t, r, g, b

  h = math.fmod(h, 360)

  if s == 0 then return {v, v, v} end
  h=h/60
  i=math.floor(h)
  f=h-i
  p=v*(1-s)
  q=v*(1-s*f)
  t=v*(1-s*(1-f))

  if     i==0 then r=v g=t b=p
  elseif i==1 then r=q g=v b=p
  elseif i==2 then r=p g=v b=t
  elseif i==3 then r=p g=q b=v
  elseif i==4 then r=t g=p b=v
  else             r=v g=p b=q
  end

  r = r * 255
  g = g * 255
  b = b * 255
  return {r, g, b}
end

local function copy(t)
	local ret = {}
	for i,v in pairs(t) do
		ret[i] = v
		if type(v) == "table" then
			ret[i] = copy(v)
		end
	end
	return ret
end

local function setColor(...)
	-- TODO factor this function out?
	local args = {...}
	love.graphics.setColor(args[1] or 255, args[2] or 255, args[3] or 255, args[4] or 255)
end

-- TODO verify these do not break if using multiple profilers
local color_data = {}
local colors = {} -- NOTE the pool of available colors is removed from every time a new time is used

for i=0,300 do
	table.insert( colors, hsvToRgb(i, 1, 1) )
end

function piefiller:new(settings)
  local self = {}
  setmetatable( self, {__index = piefiller} )

  self.data = {}
	self.parsed = {}
  self.last = 0
  self.timer = 0
  self.depth = 2
  self.small = false
  self.x = 0
  self.y = 0
  self.scale = 0.4
	self.font = love.graphics.newFont(16 / self.scale)
	self.visible = true
  self.step = 1
	self.background = {0, 0, 0, 180}
  self.keys = {
		reset = "r",
		increase_depth = "down",
		decrease_depth = "up",
		increase_step_size = "=",
		decrease_step_size = "-",
		shorten_names = "z",
		show_hidden = "h",
		save_to_file = "e",
		show_profiler = "p",
	}

	if settings then
		for k,v in pairs(settings) do
			if self[k] then
				self[k] = v
			end
		end
	  if not type(self.keys) == "table" then
		  self.keys = {}
  	end
	end

	return self
end

function piefiller:reset()
	self.data = {}
	-- why should these be reset? only the data matters
	-- self.x = 0
	-- self.y = 0
	-- self.scale = 1
end

function piefiller:setKey(table_or_command,key)
	if type(table_or_command) == "table" then
		-- self.keys = table_or_command -- this was stupid and pointless actually, wtf
		for i,v in pairs(table_or_command) do
			if self.keys[i] then self.keys[i] = v end
		end
	elseif type(table_or_command) == "string" then
		if not self.keys[table_or_command] then error("Invalid command: "..tostring(table_or_command)) end
		self.keys[table_or_command] = key
	elseif not table_or_command then
		self.keys = {}
	else
		error("Expected table, string, false, or nil; got: "..type(table_or_command))
	end
end

function piefiller:parse(caller,parent)
	return {
		parent = parent,
		func = caller.func,
		count = 0,
		time = 0,
		child_time = 0,
		named_child_time = 0,
		children = {},
		children_time = {},
		info = caller,
		kids = {},
	}
end

function piefiller:attach()
  self.last = os.clock()

  local function hook()
    local depth = self.depth
    local caller = debug.getinfo(depth)
    local taken = os.clock() - self.last
		if caller then
		  local last_caller
			local own = string.find(caller.source, path)
			if caller.func ~= hook and not own then
				while caller do
					if last_caller and not self.view_children then
						local name = caller.func
						local lc = self.data[last_caller.func]
						if not lc.kids[name] then
							lc.kids[name] = self:parse(caller, last_caller)
						end
						local kid = lc.kids[name]
						kid.count = kid.count + 1
						kid.time = kid.time + taken
					else
						local name = caller.func
						local raw = self.data[name]
						if not raw then
							self.data[name] = self:parse(caller, last_caller)
						end
						raw = self.data[name]
						raw.count = raw.count + 1
						raw.time = raw.time + taken
						last_caller = caller
					end
					depth = depth + 1
					caller = debug.getinfo(depth)
				end
			end
		end
	end

	local step = 10^self.step
	if self.step < 0 then
		step = 1/-self.step
	end

	debug.sethook(hook, "", step)
end

function piefiller:detach(stop) -- TODO figure out what stop is useful for
  local totaltime = 0
  local parsed = {}
  local no = 0

  for i,v in pairs(self.data) do
    no = no + 1
    totaltime = totaltime + v.time
  	local i = no
    parsed[i] = {}
    parsed[i].name = v.info.name
    parsed[i].time = v.time
		parsed[i].src = v.info.source
    parsed[i].def = v.info.linedefined
    parsed[i].cur = v.info.currentline
		parsed[i].item = v
		parsed[i].caller = v.info

		if not color_data[v.func] then
			local i = math.random(#colors)
			color_data[v.func] = colors[i]
			table.remove(colors, i)
		end

		parsed[i].color = color_data[v.func]
	end

  local prc = totaltime/100
  for i,v in ipairs(parsed) do
    parsed[i].prc = v.time/prc
  end
  self.parsed = parsed
  self.totaltime = totaltime

	if not stop then debug.sethook() end
end

function piefiller:getText(v)
	if self.small then
		if v.src:sub(1,1) == "@" then
  		return tostring(math.ceil(v.prc)).."% "..tostring(v.src:sub(2))..":"..tostring(v.def)
		else
  		return tostring(math.ceil(v.prc)).."% "..tostring(v.src)..":"..tostring(v.def)
  	end
	else
		if v.src:sub(1,1) == "@" then
  		return tostring(math.ceil(v.prc)).."% "..tostring(v.name)..tostring(v.src)..":"..tostring(v.def)
		else
  		return tostring(math.ceil(v.prc)).."% "..tostring(v.name).."@"..tostring(v.src)..":"..tostring(v.def)
		end
	end
end

-- local largeFont = love.graphics.newFont(25)

function piefiller:draw(args)
	if not self.visible then return end

  local loading
	local oldFont = love.graphics.getFont()
	local oldLineJoin = love.graphics.getLineJoin()
  local pi = math.pi
	local arc = love.graphics.arc
	local w,h = love.graphics.getDimensions()

	local args = args or {}
	local rad = args.radius or (h * self.scale - 2 / self.scale)
  local mode = args.mode or "original" -- "original" for the original style

	love.graphics.push()

	love.graphics.translate(self.x, self.y)
	love.graphics.scale(self.scale)
	love.graphics.setLineJoin("bevel")
	love.graphics.setFont(self.font)

	local cx = w/2 + (rad*2 - w)/2 + 2 / self.scale
	local cy = h * self.scale

	local maxLength = 0
	for i,v in ipairs(self.parsed) do
		local s = self.font:getWidth(self:getText(v))
		if s > maxLength then maxLength = s end
	end
	setColor(self.background)
	love.graphics.rectangle("fill", 0, 0, cx * 2 + 2 / self.scale + maxLength, cy * 2)

	if self.parsed and self.totaltime > 0  then
    local lastangle = 0

		for i,v in ipairs(self.parsed) do
      local color = v.color
			local angle = math.rad(3.6*v.prc)
			setColor(color)
			arc("fill",cx,cy,rad,lastangle,lastangle + angle)
			setColor(255, 255, 255, 255)
			if v.prc > 1 then
				arc("line",cx,cy,rad,lastangle,lastangle + angle)
			end
			lastangle = lastangle + angle
    end

		love.graphics.circle("line", cx, cy, rad) -- make sure there is an outer white border

		local x = cx + rad + 2 / self.scale
		local y = cy - rad
		love.graphics.print("Depth: "..self.depth.." Step: "..self.step, x, y)
		y = y + self.font:getHeight()

		local sorted = {}
		for i,v in ipairs(self.parsed) do
			sorted[i] = {i, v.prc}
		end
		table.sort(sorted,function(a,b)
			return a[2] > b[2]
		end)

		for _,i in ipairs(sorted) do
			local v = self.parsed[i[1]]
			local color = v.color
			local txt = self:getText(v)
			setColor(color)
			love.graphics.print(txt, x, y)
			y = y + self.font:getHeight()
		end

	else
		-- REFACTOR
		setColor()
		local t = "Loading..."
		local fh = self.font:getHeight()
		fw = self.font:getWidth(t)
		love.graphics.print("Loading...", w/2 - fw/2, h/2)
		-- END
  end

	-- our timing is handled in draw... why? My guess is because we aren't called in update
	self.timer = self.timer + love.timer.getDelta()
	if self.timer > 20 then
		self.timer = 0
	end

	love.graphics.pop()

	love.graphics.setFont(oldFont)
	love.graphics.setLineJoin(oldLineJoin)
end

function piefiller:keypressed(key)
	local command
	for i,v in pairs(self.keys) do
		if key == v then
			command = i
			break
		end
	end
	if command then
		if command == "reset" then
			self:reset()
		elseif command == "increase_depth" then
			self:reset()
			self.depth = self.depth + 1
		elseif command == "decrease_depth" then
			self:reset()
			if self.depth > 1 then
  			self.depth = self.depth - 1
			end
		elseif command == "increase_step_size" then
			self:reset()
			self.step = self.step + 1
		elseif command == "decrease_step_size" then
			self:reset()
			if self.step > 0 then
  			self.step = self.step - 1
			end
		elseif command == "shorten_names" then
			self.small = not self.small
		elseif command == "show_hidden" then
			self:reset()
			self.view_children = not self.view_children
		elseif command == "show_profiler" then
			self.visible = not self.visible
		elseif command == "save_to_file" then
			local parsed = copy(self.parsed)
			table.sort(parsed,function(a,b)
				return a.prc > b.prc
			end)
			local d = {"Depth: "..self.depth.." with step: "..self.step.."\r\n".."Total time: "..self.totaltime.."\r\n"}

			for i,v in ipairs(parsed) do
				local instance = {
					"-----"..(v.name or "def@"..v.def).."-----",
					"source:"..v.src..":"..v.def,
					"current line: "..v.cur,
					"time: "..v.time,
					"percentage: "..math.ceil(v.prc).." %",
					"----------------",
				}
				for i,v in ipairs(instance) do
					instance[i] = v.."\r\n"
				end
				table.insert(d,table.concat(instance))
			end
			local data = table.concat(d)
			love.filesystem.write("Profile.txt",data)
			love.system.openURL(love.filesystem.getRealDirectory("Profile.txt"))
		end
	end
end

function piefiller:unpack(fn)
	local data = {
		items = {},
		about = {
			depth = self.depth,
			step = self.step,
			totalTime = self.totaltime,
		},
	}

	for i,v in ipairs(self.parsed) do
		local a = {
			name = v.name,
			line_defined = v.def,
			current_line = v.cur,
			source = v.src,
			time_taken = v.time,
			percentage = v.prc,
			caller = v.caller,
		}
		if fn then
			assert(type(fn) == "function", "Expected function, got: "..type(fn))
			fn(a)
		end
		table.insert(data.items, a)
	end
	return data
end

setmetatable( piefiller, { __call = piefiller.new } )

return piefiller
