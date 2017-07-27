profilerOn = true
drawRect = true

local Profiler = require("piefiller")
local profiler = Profiler:new()

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

	if profilerOn then
		-- profiler:draw({50}) -- did not appear to have a difference in 0.9.2 or 0.10.2
		profiler:draw()
	end
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
		profilerOn = not profilerOn
	elseif key == ";" then
		drawRect = not drawRect
	end

	profiler:keypressed(key)
end

function love.mousepressed(...)
	profiler:mousepressed(...)
end
