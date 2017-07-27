drawRect = true

local Profiler = require("piefiller")
local profiler = Profiler()

function iterateSmall()
	for i=1,1000 do
	end
end
function iterateLarge()
	for i=1,1000000 do
	end
end
function iterateHuge()
	for i=1,1000000000 do
	end
end

function drawRectangles()
	for i=1,100 do
		love.graphics.setColor(255,0,0)
		love.graphics.rectangle("line",i,i,i,i)
	end
end

function love.draw()
	if drawRect then
		drawRectangles()
	end

	profiler:detach() -- was attached in update function

	-- temporary
	local w, h = love.graphics.getWidth(), love.graphics.getHeight()
	love.graphics.setColor(255, 255, 255, 255)
	love.graphics.rectangle("fill", 0, 0, w, h)

	profiler:draw()

	-- temporary
	love.graphics.line(w/2, 0, w/2, h)
	love.graphics.line(0, h/2, w, h/2)
end

function love.update(dt)
	profiler:attach()

	iterateSmall()
	iterateLarge()
	iterateHuge()

	-- detached in draw function
end

function love.keypressed(key)
	if key == "escape" then
		love.event.quit()
	elseif key == ";" then
		drawRect = not drawRect
	end

	profiler:keypressed(key)
end
