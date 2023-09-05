local h3d   = require 'h3d'
local bench = require '../eval/benchmark/generator/triangle_generator'

local raster, geometry = h3d.create_pipeline({
	vertex_attributes = {
		{ name = 'position', count = 3, position = true },

		{ name = 'uv',       count = 2 },
--		{ name = 'color',    count = 3 },
--		{ name = 'normal',   count = 3 },
--		{ name = 'a',        count = 3 },
--		{ name = 'b',        count = 3 },
--		{ name = 'c',        count = 3 },
--		{ name = 'd',        count = 3 },
--		{ name = 'e',        count = 3 },

--		position = { count = 3, position = true },
--		uv       = { count = 2 },
--		color    = { count = 3 },
--		normal   = { count = 3 },
	},
	face_attributes = {
		{ name = 'color',      count = 1 },

--		color = { count = 1 },
	},
	layers = {
		'color',
		'depth'
	},
	frag_shader =
--[[]]
--[[gl_set_layer('color', gl_face('color'))]]
--[[
	local a
	a = gl_vertex('position', 0)
	a = gl_vertex('position', 2)
]]
--[[
	if gl_layer('depth') > gl_depth then
		gl_set_layer('depth', gl_depth)
		gl_set_layer('color', gl_face('color'))
	end
]]
[[
	if gl_layer('depth') > gl_depth then
		gl_set_layer('depth', gl_depth)
		local cc = gl_tex(gl_vertex('uv', 0), gl_vertex('uv', 1))
		-- local cc = gl_rgb(gl_vertex('color', 0), gl_vertex('color', 1), gl_vertex('color', 2))
		gl_set_layer('color', cc) --gl_face('color'))
	end
]]
})

local TEX_BIG = h3d.load_image('cube.bin')
local TEX_DBG = h3d.load_image('debug.bin')
local TEX_FAC = h3d.load_image('pfp.bin')
local CC_FONT = h3d.load_image('cc_font.bin')

local function matrixRotate(px, py, pz, rx, ry, rz, vertices)
	local A = math.rad(rx)
	local B = math.rad(ry)
	local C = math.rad(rz)

	local cosf_A = math.cos(A)
	local sinf_A = math.sin(A)
	local cosf_B = math.cos(B)
	local sinf_B = math.sin(B)
	local cosf_C = math.cos(C)
	local sinf_C = math.sin(C)

	for i=1,#vertices do
		local v = vertices[i]
		local x = v.x + px
		local y = v.y + py
		local z = v.z + pz
		local nx_A = x * cosf_A - z * sinf_A
		--cal ny_A = y
		local nz_A = x * sinf_A + z * cosf_A

		--cal nx_B = nx_A
		local ny_B = y * cosf_B - nz_A * sinf_B
		local nz_B = y * sinf_B + nz_A * cosf_B

		local nx_C = nx_A * cosf_C - ny_B * sinf_C
		local ny_C = nx_A * sinf_C + ny_B * cosf_C
		--cal nz_C = nz_B

		v.x = nx_C
		v.y = ny_C
		v.z = nz_B
	end
end

local function vertex(x, y, z, r, g, b, u, v)
	return {
		x = x,
		y = y,
		z = z,

		r = r or 0,
		g = g or 0,
		b = b or 0,
		a = 0,

		u = u or 0,
		v = v or 0,

		_normal_x = 0,
		_normal_y = 0,
		_normal_z = 0,
	}
end

local C = 10

local function draw_cube(x, y, z, rx, ry, rz, near, gr, cx, cy, cz)
	raster.set_texture(TEX_BIG) -- TEX_BIG)

	local s = -0.5
	local e =  0.5

	local xs = -0.5 + x
	local xe =  0.5 + x
	local ys = -0.5 + y
	local ye =  0.5 + y
	local zs =  0.5 + z
	local ze = -0.5 + z

	local m = 0
	local groups = {
	-- Front
		front = {
			vertex(xs, ys, ze,      1, 0, 0,    0.25 + m, 0.25 + m),
			vertex(xe, ys, ze,      1, 1, 1,    0.50 - m, 0.25 + m),
			vertex(xs, ye, ze,      0, 0, 0,    0.25 + m, 0.50 - m),
			vertex(xe, ye, ze,      0, 1, 0,    0.50 - m, 0.50 - m),
			vertex(xs, ye, ze,      0, 0, 0,    0.25 + m, 0.50 - m),
			vertex(xe, ys, ze,      1, 1, 1,    0.50 - m, 0.25 + m),
		},
	-- Left
		left = {
			vertex(xs, ys, zs,      1, 1, 0,    0.00 + m, 0.25 + m),
			vertex(xs, ys, ze,      1, 0, 1,    0.25 - m, 0.25 + m),
			vertex(xs, ye, zs,      0, 1, 1,    0.00 + m, 0.50 - m),
			vertex(xs, ye, ze,      0, 0, 0,    0.25 - m, 0.50 - m),
			vertex(xs, ye, zs,      0, 0, 0,    0.00 + m, 0.50 - m),
			vertex(xs, ys, ze,      1, 0, 0,    0.25 - m, 0.25 + m),
		},
	-- Right
		right = {
			vertex(xe, ys, ze,      1, 1, 1,    0.50 + m, 0.25 + m),
			vertex(xe, ys, zs,      0, 0, 1,    0.75 - m, 0.25 + m),
			vertex(xe, ye, ze,      0, 1, 0,    0.50 + m, 0.50 - m),
			vertex(xe, ye, zs,      0, 0, 0,    0.75 - m, 0.50 - m),
			vertex(xe, ye, ze,      0, 1, 0,    0.50 + m, 0.50 - m),
			vertex(xe, ys, zs,      0, 0, 1,    0.75 - m, 0.25 + m),
		},
	-- Back
		back = {
			vertex(xe, ys, zs,      0, 0, 1,    0.75 + m, 0.25 + m),
			vertex(xs, ys, zs,      0, 0, 0,    1.00 - m, 0.25 + m),
			vertex(xe, ye, zs,      0, 0, 0,    0.75 + m, 0.50 - m),
			vertex(xs, ye, zs,      1, 0, 0,    1.00 - m, 0.50 - m),
			vertex(xe, ye, zs,      0, 1, 0,    0.75 + m, 0.50 - m),
			vertex(xs, ys, zs,      0, 0, 1,    1.00 - m, 0.25 + m),
		},
	-- Top
		top = {
			vertex(xs, ys, zs,      0, 0, 0,    0.25 + m, 0.00 + m),
			vertex(xe, ys, zs,      0, 0, 1,    0.50 - m, 0.00 + m),
			vertex(xs, ys, ze,      1, 0, 0,    0.25 + m, 0.25 - m),
			vertex(xe, ys, ze,      1, 1, 1,    0.50 - m, 0.25 - m),
			vertex(xs, ys, ze,      1, 0, 0,    0.25 + m, 0.25 - m),
			vertex(xe, ys, zs,      0, 0, 1,    0.50 - m, 0.00 + m),
			--[[
			vertex(xs, ys, zs,      1, 0, 0,    0.25 + m, 0.00 + m),
			vertex(xe, ys, zs,      0, 1, 0,    0.50 - m, 0.00 + m),
			vertex(xs, ys, ze,      0, 0, 1,    0.25 + m, 0.25 - m),
			vertex(xe, ys, ze,      1, 1, 0,    0.50 - m, 0.25 - m),
			vertex(xs, ys, ze,      1, 0, 1,    0.25 + m, 0.25 - m),
			vertex(xe, ys, zs,      0, 1, 1,    0.50 - m, 0.00 + m),
			]]
		},
	-- Bottom
		bottom = {
			vertex(xs, ye, ze,      0, 0, 0,    0.25 + m, 0.50 + m),
			vertex(xe, ye, ze,      0, 1, 0,    0.50 - m, 0.50 + m),
			vertex(xs, ye, zs,      0, 0, 0,    0.25 + m, 0.75 - m),
			vertex(xe, ye, zs,      0, 0, 0,    0.50 - m, 0.75 - m),
			vertex(xs, ye, zs,      0, 0, 0,    0.25 + m, 0.75 - m),
			vertex(xe, ye, ze,      0, 1, 0,    0.50 - m, 0.50 + m),
		}
	}

	local vertices = {}
	if gr == nil then
		for i, v in pairs(groups) do
			for _, vv in pairs(v) do
				vertices[#vertices + 1] = vv
			end
		end
	else
		for _, name in pairs(gr) do
			for _, vv in pairs(groups[name]) do
				local cc = {}
				for aa,bb in pairs(vv) do
					cc[aa] = bb
				end
				vertices[#vertices + 1] = cc
			end
		end
	end

	matrixRotate(cx or 0, cy or 0, cz or 0, rx, ry, rz, vertices)

	for i=1,#vertices,3 do
		local v1 = vertices[i]
		local v2 = vertices[i + 1]
		local v3 = vertices[i + 2]
		-- v1.x = v1.x + x
		-- v2.x = v2.x + x
		-- v3.x = v3.x + x
		-- 
		-- v1.y = v1.y + y
		-- v2.y = v2.y + y
		-- v3.y = v3.y + y
		-- 
		-- v1.z = v1.z + z
		-- v2.z = v2.z + z
		-- v3.z = v3.z + z

		C = (i * 3 + C * 17 + 100) % 220

		geometry
			.vertex('position', v1.x, v1.y, v1.z)
			.vertex('position', v2.x, v2.y, v2.z)
			.vertex('position', v3.x, v3.y, v3.z)
			.vertex('color', v1.r, v1.g, v1.b)
			.vertex('color', v2.r, v2.g, v2.b)
			.vertex('color', v3.r, v3.g, v3.b)
			.vertex('uv', v1.u, v1.v)
			.vertex('uv', v2.u, v2.v)
			.vertex('uv', v3.u, v3.v)
			.face('color', C)
		-- print()
		-- print(v1.r, v1.g, v1.b, '  ', v1.x, v1.y, v1.z)
		-- print(v2.r, v2.g, v2.b, '  ', v2.x, v2.y, v2.z)
		-- print(v3.r, v3.g, v3.b, '  ', v3.x, v3.y, v3.z)
		-- print(v1.u, v1.v, v2.u, v2.v, v3.u, v3.v)

		raster.drawGeometry(geometry.build(), near)
	end
end

local p_x  = 0
local p_y  = 0
local p_z  = 0
local p_rx = 0
local p_ry = 0
local p_rz = 0
local running = true
local w, h

local function raster_setup()
	term.setGraphicsMode(2)
	w, h = term.getSize(2)

	print(w, ',', h)
	-- for k,v in pairs(raster) do print(k, v) end
	raster.set_size(w, h)

	for i=0,6*6*6 do
		local r = (math.floor(i     ) % 6) / 6.0
		local g = (math.floor(i /  6) % 6) / 6.0
		local b = (math.floor(i / 36) % 6) / 6.0
		term.setPaletteColor(i, r, g, b)
	end

	-- for i=0,255 do term.setPaletteColor(i, i / 255.0, i / 255.0, i / 255.0) end
end


local function raster_clear()
	raster.set_layer('depth', 10000)
	raster.set_layer('color', 1 + 6 + 36) -- 215
end


local function draw_text(x, y, str, fg_color, bg_color)
	local column = 0
	local line = 0
	for i=1,#str do
		local px = x + column * 6
		local py = y + line * 9

		local c = str:sub(i,i)
		if c == '\n' then
			line = line + 1
			column = 0
		else
			column = column + 1
			c = string.byte(c)

			local c_x = (c % 16) * 8
			local c_y = math.floor(c / 16) * 11

			for yy=1,9 do
				for xx=1,6 do
					local ix = c_x + xx
					local iy = c_y + yy
					local cc = CC_FONT.data[ix + iy * 128 + 1]

					if cc > 0 then
						term.setPixel(px + xx, py + yy, fg_color)
					elseif bg_color ~= nil then
						term.setPixel(px + xx, py + yy, bg_color)
					end
				end
			end
		end
	end
end

local function render_loop()
	raster_setup()
	raster_clear()

	local t0 = os.clock()

	local index = 500
	local frames = 0
	local start_frame = os.clock()
	local fps_list = {}

	while true do
		os.sleep(0)
		if not running then
			break
		end

		if os.clock() - start_frame > 1 then
			start_frame = start_frame + 1
			table.insert(fps_list, 1, frames)
			if #fps_list > 3 then
				table.remove(fps_list, #fps_list)
			end
			frames = 0
		end

		local fps = 0
		for _, i in pairs(fps_list) do
			fps = fps + i
		end
		fps = fps / math.max(1, #fps_list)

		if os.clock() - t0 > 1000 then
			break
		end

		local s = (os.clock() * 100)
		raster_clear()

		index = index + 1
		local x = (math.sin(-index / 80.0) - 0.5) * 1
		local y = (math.cos( index / 60.0) - 0.5) * 0.5
		local z = -0.5 - 1
		local e = 0
		math.randomseed(p_z)

		local near = 1
		C = 1
		-- draw_cube(0, 0, 0, p_rx, p_ry, p_rz, near, nil, p_x, p_y, p_z)

		--[[
		draw_cube(0, 0, 2.5, index / 10, index / 20, 0, near, {
			'back', 'left',
		})
		draw_cube( 1.7, 0, 2.5, index / 2, index / 20, 0, near)
		draw_cube(-1.2, 0, 2.5, index / 10, index / 5, index, near)
		draw_cube(0, 0.2, 2.6, -index / 4, -index / 10, -index / 2, near)
		]]

		C = 1
		local dz = (index - 500) / 10
		for ix=1,10 do
			for iz=1,10 do
				draw_cube(ix - 5, 1, 2 + iz, p_rx, p_ry, p_rz, near, nil, p_x, p_y, p_z)
			end
		end

		term.setFrozen(true)
		term.drawPixels(1, 1, raster.get_layer('color'))
		local info = raster.get_rastered_info()

		draw_text(0,  0, "fps      : " .. fps, 215, 0)
		draw_text(0,  9, "pixels   : " .. info.fragment.color, 215, 0)
		draw_text(0, 18, "triangles: " .. info.triangles, 215, 0)

		--[[
		local str = ""
		for i=0,255 do
			local c = string.char(i)
			if c == '\n' then
				c = ' '
			end

			str = str .. c

			if ((i + 1) % 16) == 0 then
				str = str .. '\n'
			end
		end
		draw_text(200, 10, str, 215, 0)
		]]

		term.setFrozen(false)

		frames = frames + 1
	end

	local t1 = os.clock()

	local elapsed = t1 - t0
	print('average fps ' .. (frames / elapsed))
	print(frames .. ' frames over ' .. elapsed .. ' s')
end

local function render_benchmark()
	raster_setup()
	raster_clear()
	term.drawPixels(1, 1, 0, w, h)

	local count = 100000
	local t0 = os.clock()

	math.randomseed(0)
	local shapes = bench.generate(count, 500, 500, -250, -250)

	for i, v in ipairs(shapes) do
		if i > 0 then
			break
		end

		local buffer = geometry
			.vertex('position', v[1].x, v[1].y, 500)
			.vertex('position', v[2].x, v[2].y, 500)
			.vertex('position', v[3].x, v[3].y, 500)
			.face('color', C)
			.build()

		raster.drawGeometry(buffer, 0.01)
	end
	raster_clear()
	raster.get_rastered_info()

	local t1 = os.clock()
	C = 1
	for i, v in ipairs(shapes) do
		C = (i * 3 + C * 17 + 100) % 220
		geometry
			.vertex('position', v[1].x, v[1].y, 500)
			.vertex('position', v[2].x, v[2].y, 500)
			.vertex('position', v[3].x, v[3].y, 500)
			.face('color', C)

		if i % 2000 == 0 then
			os.sleep(0)
		end
	end
	local t2 = os.clock()
	raster.drawGeometry(geometry.build(), 0.01)

	local info = raster.get_rastered_info()
	print('pixels ' .. info.fragment.color)
	term.drawPixels(1, 1, raster.get_layer('color'))
	local t3 = os.clock()
	os.sleep(1)

	local gen_t = t1 - t0
	local geo_t = t2 - t1
	local dra_t = t3 - t2
	print('shapes     ' .. #shapes)
	print('generating ' .. (gen_t * 1000) .. ' ms')
	print('geometry   ' .. (geo_t * 1000) .. ' ms')
	print('drawing    ' .. (dra_t * 1000) .. ' ms, (' .. ((dra_t * 1000) / #shapes) .. ' ms average)')
end

local function key_press()
	parallel.waitForAny(function()
		local rs = 5.0
		local ms = 0.5
		while true do
			local ff = 0
			local ss = 0
			local dd = 0

			local _, key = os.pullEvent('key')
			if key == keys.p then
				running = false
				break
			elseif key == keys.w then
				ff = -1
			elseif key == keys.s then
				ff = 1
			elseif key == keys.a then
				ss = 1
			elseif key == keys.d then
				ss = -1
			elseif key == keys.space then
				dd = 1
			elseif key == keys.leftShift then
				dd = -1
			elseif key == keys.q then
				p_rx = p_rx - rs
			elseif key == keys.e then
				p_rx = p_rx + rs
			elseif key == keys.r then
				p_ry = p_ry - rs
			elseif key == keys.f then
				p_ry = p_ry + rs
			end

			p_z = p_z + (ff * math.cos(math.rad(p_rx)) - ss * math.sin(math.rad(p_rx))) * ms
			p_x = p_x + (ff * math.sin(math.rad(p_rx)) + ss * math.cos(math.rad(p_rx))) * ms
			p_y = p_y + dd / 3.0
		end
	end, render_loop)
end

-- render_benchmark
-- Make sure we reset
local _, err = xpcall(render_benchmark, function(...)
	print(...)
	print(debug.traceback())
	term.setFrozen(false)
end)
if err then
	print(err)
end

term.setFrozen(false)
term.setGraphicsMode(0)
for i=0,15 do
	local c = 2^i
	term.setPaletteColor(c, term.nativePaletteColor(c))
end
