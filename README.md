# H3D
A graphics library for ComputerCraft made by HaruCoded (2023)

This project was inspired by:
+ [Pine3D (Xella)](https://github.com/Xella37/Pine3D)
+ [V3D (Exerro)](https://github.com/exerro/v3d)
+ [C3D (9551-Dev)](https://github.com/9551-Dev/C3D)

# Documentation

## Basic Setup
First you need to create a raster and a geometry buffer
```lua
local h3d = require 'h3d'

local raster, geometry = h3d.create_pipeline({
	vertex_attributes = {
		h3d.attr('position', 3, h3d.AttributeType.Position),
	},
	face_attributes = {
		h3d.attr('color', 1),
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
	.position(-1, -1, 1)
	.position( 0, -1, 1)
	.position( 0,  0, 1)
	.face('color', 32)
	.build(), camera)

raster.drawGeometry(geometry
	.position(-0.50, -0.25, 1)
	.position( 0.00,  0.50, 1)
	.position( 0.50, -0.25, 1)
	.face('color', 54)
	.build(), camera)

term.drawPixels(1, 1, raster.get_layer('color'))
```

## Attributes
There are currently a few types of attributes

### `Default`
**Note:** *All attributes are zero indexed*

For normal attributes you can access them in the shader by using `gl_vertex` and `gl_face`

If the attribute only has one component you can access them using `gl_vertex / gl_face ('attribute_name')`

If it has more than one component you need to specify which position you want `gl_vertex / gl_face ('attribute_name', attribute_index)`

### `h3d.AttributeType.Position`
The position attribute is required and is used to place the triangles on screen

In a shader you can access the position with `gl_x`, `gl_y` and `gl_z`
The position value can be added to a geometry builder using `geometry.position(x, y, z)`

### `h3d.AttributeType.Texture`
The texture attribute is optional and can be used to draw texture

In a shader you can access the texture with `gl_uv_x`, `gl_uv_y`
The texture can be added to a geometry builder using `geometry.texture(x, y)`

### `h3d.AttributeType.Color`
The color attribute is optional and can be used to draw colors

In a shader you can access the color with `gl_r`, `gl_g`, `gl_b`
The color can be added to a geometry builder using `geometry.color(r, g, b)`


# Shader
The shader can be used to create more advanced effects to scenes such as lighting

## Language
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

## Builtin Variables
### `gl_x`
- Get the fragment x coordinate

### `gl_y`
- Get the fragment y coordinate

### `gl_z` / `gl_depth`
- Get the fragment z coordinate

### `gl_uv_x`
- **Note:** *This value is only present if you added a texture attribute*
- Get the uv x coordinate

### `gl_uv_y`
- **Note:** *This value is only present if you added a texture attribute*
- Get the uv y coordinate

### `gl_r`
- **Note:** *This value is only present if you added a color attribute*
- Get the red color value

### `gl_g`
- **Note:** *This value is only present if you added a color attribute*
- Get the green color value

### `gl_b`
- **Note:** *This value is only present if you added a color attribute*
- Get the blue color value

### `gl_HasTexture`
- Get if a texture is currently loaded

## Builtin Functions
### `gl_vertex(name, index)`
- Returns - Number: The vertex attribute with the specified name with the given index

### `gl_face(name, index)`
- Returns - Number: The face attribute with the specified name with the given index

### `gl_tex(u, v)`
- Returns - Number: The texture pixel value at the specified `uv` coordinate

### `gl_layer(name)`
- Returns - Number: The value inside the layer with the specified name

### `gl_set_layer(name, value)`
- Description: Set the value of a layer

## Builtin Math
### `min(...)`
- Returns - Number: The minimum value

### `max(...)`
- Returns - Number: The maximum value

### `floor(value)`
- Returns - Integer: The floor value

### `ceil(value)`
- Returns - Integer: The ceil value


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
