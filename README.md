# H3D
A graphics library for ComputerCraft made by HaruCoded (2023)

This project was inspired by:
+ [Pine3D (Xella)](https://github.com/Xella37/Pine3D)
+ [V3D (Exerro)](https://github.com/exerro/v3d)
+ [C3D (9551-Dev)](https://github.com/9551-Dev/C3D)

# Documentation

## Setup
First you need to create a raster and a geometry buffer
```lua
local h3d = require 'h3d'

local raster, geometry = h3d.create_pipeline({
	vertex_attributes = {
		{ name = 'position', count = 3, position = true },
	},
	face_attributes = {
		{ name = 'color', count = 1 },
	},
	layers = {
		'color',
		'depth'
	},
	frag_shader = [[
		if gl_layer('depth') > gl_depth then
			gl_set_layer('depth', gl_depth)
			gl_set_layer('color', gl_face('color'))
		end
	]]
})

local width, height = term.getSize(2)
raster.set_size(width, height)
```

Then you need to create a camera matrix
```lua
local camera = h3d.camera_matrix()
	:perspective(90, width / height, 0.01, 10000)
```

After that you can render geometry
```lua
raster.drawGeometry(geometry
	.vertex('position', -1, -1, 1)
	.vertex('position',  0, -1, 1)
	.vertex('position',  0,  0, 1)
	.face('color', 32)
	.build(), camera)

raster.drawGeometry(geometry
	.vertex('position', -0.50, -0.25, 1)
	.vertex('position',  0.00,  0.50, 1)
	.vertex('position',  0.50, -0.25, 1)
	.face('color', 54)
	.build(), camera)

term.drawPixels(1, 1, raster.get_layer('color'))
```

## Shader
The shader can be used to create more advanced effects to scenes such as lighting

### Language
The language is a simplified version of lua with only `if` statements,
there are no `elseif` statements so you need to nest `else`

```lua
if a then
	-- First
else
	if b then
		-- Second
	end
end
```

### Builtin

#### Variables
+ `gl_x`

	Get the fragment x coordinate
+ `gl_y`

	Get the fragment y coordinate
+ `gl_z` / `gl_depth`

	Get the fragment z coordinate

#### Functions
+ `gl_vertex(name, index)`

	Returns the vertex attribute with the specified name with the given index
+ `gl_face(name, index)`

	Returns the vertex attribute with the specified name with the given index
+ `gl_tex(u, v)`

	Returns the texture pixel value at the specified `uv` coordinate
+ `gl_layer(name)`

	Returns the value inside the layer with the specified name
+ `gl_set_layer(name, value)`

	Set the value of a layer
+ `min(...)`

    Returns the minimum value
+ `max(...)`

    Returns the maximum value
+ `floor(value)`

    Returns the floor value
+ `ceil(value)`

    Returns the ceil value

# PLUA Format
PreProcessed LUA files

These are used to automatically generate code

```lua
{%
-- Compile time code
%}

{!
-- Insert this into the code as a string
!}
```
