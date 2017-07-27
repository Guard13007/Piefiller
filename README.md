# Piefiller

Graphical profiler for Love2D >= 0.9.2

Originally by devfirefly, heavily modified by Guard13007.

# Usage

1) Require the file:
```lua
  local piefiller = require("piefiller")
```
2) Make a new instance of piefiller:
```lua
  local Pie = piefiller:new()
```
3) Attach the piefiller to the part of your application that you want to monitor (love.update and love.draw typically are good places):
```lua
 function love.update()
	Pie:attach()
		-- do something
	Pie:detach()
 end
```
4) Draw the output and pass key events to your piefiller:
```lua
 function love.draw()
	Pie:draw()
 end
 function love.keypressed(key)
 	Pie:keypressed(key)
 end
```
5) With sufficient output, press the `E` key to output to file. Example output:
```
-----drawRectangles-----
source:@main.lua:20
current line: 22
time: 548.325
percentage: 98 %
----------------
```

# Keys

p = shows/hides the profiler

r = resets the pie

up = decreases depth

down = increases depth

\- = decreases step size

=	= increases step size

s	= shortens the names displayed

h	= shows/hides hidden processes

e	= saves to file called "Profile.txt" and opens directory for you

## To redefine these:

Commands available:
```lua
reset
increase_depth
decrease_depth
increase_step_size
decrease_step_size
shorten_names
show_hidden
save_to_file
show_profiler
```

To redefine only one of the keys:
```lua
piefiller:setKey(command, key)
```

example:

```lua
piefiller:setKey("increase_depth","up")
```

To redefine all of the keys:
```lua
table = {
	"increase_depth" = "up"
}
piefiller:setKey(table)
```

# For your own interpretation

If you wish to interpret the data on your own use `piefiller:unpack()`.
Output is a table as such:

```lua
	data = {
		items = {
			{
				name,
				line_defined,
				current_line,
				source,
				time_taken,
				percentage,
				caller,
			}
		},
		about = {
			depth,
			step,
			totalTime,
		},
	}
```

# Additional notes

The best depth to search in is usually 2 and sometimes 3.

When used in large applications the output may be too much to read, however you
most likely will only be wanting to optimize the most expensive items. (And you
can always output the data to review later.)
