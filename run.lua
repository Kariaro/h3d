local bench = require '../eval/benchmark/generator/triangle_generator'
local h3d = require 'h3d'

local raster, geometry = h3d.create_pipeline({
	debug_files = true,
	debug_statistics = true,
	vertex_attributes = {
		h3d.attr('position', 3, h3d.AttributeType.Position),
		h3d.attr('uv', 2, h3d.AttributeType.Texture),
		h3d.attr('color', 3, h3d.AttributeType.Color),
	},
	face_attributes = {
		h3d.attr('color', 1),
	},
	layers = {
		'color',
		'depth'
	},
	frag_shader =
--[[]]
--[[gl_set_layer('color', gl_face('color'))]]
--[[gl_set_layer('color', gl_depth)]]
[[
	if gl_layer('depth') > gl_depth then
		gl_set_layer('depth', gl_depth)
		-- gl_set_layer('color', gl_rgb(gl_r, gl_g, gl_b))
		gl_set_layer('color', gl_face('color'))
	end
]]
--[[
	if gl_layer('depth') > gl_depth then
		gl_set_layer('depth', gl_depth)
		gl_set_layer('color', gl_tex(gl_uv_x, gl_uv_y))
	end
]]
})

local TEX_BIG = h3d.load_image('cube.bin')
local TEX_DBG = h3d.load_image('debug.bin')
local TEX_FAC = h3d.load_image('pfp.bin')
local CC_FONT = h3d.load_image('cc_font.bin')

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
local function draw_cube(x, y, z, gr, matrix)
	raster.set_texture(TEX_BIG)

	local xs = -0.5 + x
	local xe =  0.5 + x
	local ys = -0.5 + y
	local ye =  0.5 + y
	local zs = -0.5 + z
	local ze =  0.5 + z

	local m = 0
	local groups = {
		front = {
			vertex(xs, ys, zs,      1, 0, 0,    0.25 + m, 0.50 - m),
			vertex(xe, ys, zs,      1, 1, 1,    0.50 - m, 0.50 - m),
			vertex(xs, ye, zs,      0, 0, 0,    0.25 + m, 0.25 + m),
			vertex(xe, ye, zs,      0, 1, 0,    0.50 - m, 0.25 + m),
			vertex(xs, ye, zs,      0, 0, 0,    0.25 + m, 0.25 + m),
			vertex(xe, ys, zs,      1, 1, 1,    0.50 - m, 0.50 - m),
		},
		left = {
			vertex(xs, ys, ze,      1, 1, 0,    0.00 + m, 0.50 - m),
			vertex(xs, ys, zs,      1, 0, 1,    0.25 - m, 0.50 - m),
			vertex(xs, ye, ze,      0, 1, 1,    0.00 + m, 0.25 + m),
			vertex(xs, ye, zs,      0, 0, 0,    0.25 - m, 0.25 + m),
			vertex(xs, ye, ze,      0, 0, 0,    0.00 + m, 0.25 + m),
			vertex(xs, ys, zs,      1, 0, 0,    0.25 - m, 0.50 - m),
		},
		right = {
			vertex(xe, ys, zs,      1, 1, 1,    0.50 + m, 0.50 - m),
			vertex(xe, ys, ze,      0, 0, 1,    0.75 - m, 0.50 - m),
			vertex(xe, ye, zs,      0, 1, 0,    0.50 + m, 0.25 + m),
			vertex(xe, ye, ze,      0, 0, 0,    0.75 - m, 0.25 + m),
			vertex(xe, ye, zs,      0, 1, 0,    0.50 + m, 0.25 + m),
			vertex(xe, ys, ze,      0, 0, 1,    0.75 - m, 0.50 - m),
		},
		back = {
			vertex(xe, ys, ze,      0, 0, 1,    0.75 + m, 0.50 - m),
			vertex(xs, ys, ze,      0, 0, 0,    1.00 - m, 0.50 - m),
			vertex(xe, ye, ze,      0, 0, 0,    0.75 + m, 0.25 + m),
			vertex(xs, ye, ze,      1, 0, 0,    1.00 - m, 0.25 + m),
			vertex(xe, ye, ze,      0, 1, 0,    0.75 + m, 0.25 + m),
			vertex(xs, ys, ze,      0, 0, 1,    1.00 - m, 0.50 - m),
		},
		top = {
			vertex(xe, ye, ze,      0, 0, 1,    0.50 - m, 0.00 + m),
			vertex(xs, ye, ze,      0, 0, 0,    0.25 + m, 0.00 + m),
			vertex(xs, ye, zs,      1, 0, 0,    0.25 + m, 0.25 - m),
			vertex(xs, ye, zs,      1, 0, 0,    0.25 + m, 0.25 - m),
			vertex(xe, ye, zs,      1, 1, 1,    0.50 - m, 0.25 - m),
			vertex(xe, ye, ze,      0, 0, 1,    0.50 - m, 0.00 + m),
		},
		bottom = {
			vertex(xe, ys, zs,      0, 1, 0,    0.50 - m, 0.50 + m),
			vertex(xs, ys, zs,      0, 0, 0,    0.25 + m, 0.50 + m),
			vertex(xs, ys, ze,      0, 0, 0,    0.25 + m, 0.75 - m),
			vertex(xs, ys, ze,      0, 0, 0,    0.25 + m, 0.75 - m),
			vertex(xe, ys, ze,      0, 0, 0,    0.50 - m, 0.75 - m),
			vertex(xe, ys, zs,      0, 1, 0,    0.50 - m, 0.50 + m),
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

	for i=1,#vertices,3 do
		local v1 = vertices[i]
		local v2 = vertices[i + 1]
		local v3 = vertices[i + 2]

		C = (i * 3 + C * 17 + 100) % 220

		geometry
			.position(v1.x, v1.y, v1.z)
			.position(v2.x, v2.y, v2.z)
			.position(v3.x, v3.y, v3.z)
			.texture(v1.u, v1.v)
			.texture(v2.u, v2.v)
			.texture(v3.u, v3.v)
			.color(v1.r, v1.g, v1.b)
			.color(v2.r, v2.g, v2.b)
			.color(v3.r, v3.g, v3.b)
			.face('color', C)

		raster.drawGeometry(geometry.build(), matrix)
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

local BLIT = true

local function raster_setup()
	if BLIT then
		w, h = term.getSize()
	else
		term.setGraphicsMode(2)
		w, h = term.getSize(2)
	end

	print(w, ',', h)
	-- for k,v in pairs(raster) do print(k, v) end
	raster.set_size(w, h, BLIT)
	raster.set_near(1)

	if not BLIT then
		for i=0,6*6*6 do
			local r = (math.floor(i     ) % 6) / 6.0
			local g = (math.floor(i /  6) % 6) / 6.0
			local b = (math.floor(i / 36) % 6) / 6.0
			term.setPaletteColor(i, r, g, b)
		end
	end

	-- for i=0,255 do term.setPaletteColor(i, i / 255.0, i / 255.0, i / 255.0) end
end

local function raster_clear()
	raster.set_layer('depth', 10000)
	raster.set_layer('color', 1 + 6 + 36) -- 215
end


local function draw_text(x, y, str, fg_color, bg_color)
	if BLIT then
		term.setCursorPos(math.floor(x / 11) + 1, math.floor(y / 9) + 1)
		term.write(str)
		return
	end

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
	raster.set_face_culling(true)
	raster.set_near(0.01)

	local t0 = os.clock()

	local index = 0
	local frames = 0
	local start_frame = os.clock()
	local fps_list = {}

	local camera = h3d.camera_matrix()

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

		raster_clear()

		index = index + 1
		local W, H = term.getSize(2)
		camera
			:identity()
			:perspective(90, W / H, 0.00001, math.huge)
			--:perspective(90, 1, 0.1, math.huge)
			:rotate     (p_rx, 1, 0, 0)
			:rotate     (p_ry, 0, 1, 0)
			:rotate     (p_rz, 0, 0, 1)
			:translate  (-p_x, -p_y, -p_z)
		--	:scale         (1, W / H, 1)
		-- print(camera)

		C = 1
		for ix=1,11 do
			for iz=1,10 do
				draw_cube(ix - 6, 1, 2 + iz, nil, camera)
			end
		end

		draw_cube(1, 2, 2, nil, camera)
		draw_cube(2, 3, 2, nil, camera)

		raster.set_texture(nil)
		raster.set_face_culling(false)
		raster.drawGeometry(geometry
			.vertex('position', -1, -1, 1)
			.vertex('position',  0, -1, 1)
			.vertex('position',  0,  0, 1)
			.face('color', 32)
			.build(), camera
		)
		raster.drawGeometry(geometry
			.vertex('position', -0.50, -0.25, 1)
			.vertex('position',  0.00,  0.50, 1)
			.vertex('position',  0.50, -0.25, 1)
			.face('color', 54)
			.build(), camera
		)
		raster.set_face_culling(true)

		term.setFrozen(true)
		if BLIT then
			local blitBuffer = raster.get_blit('color')
			for y, row in ipairs(blitBuffer) do
				term.setCursorPos(1, y)
				term.blit(
					table.concat(row[1], ''),
					table.concat(row[2], ''),
					table.concat(row[3], '')
				)
			end
		else
			term.drawPixels(1, 1, raster.get_layer('color'))
		end
		local info = raster.get_raster_info()

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

	raster.set_near(0.01)

	local count = 10000
	local t0 = os.clock()

	math.randomseed(0)
	local shapes = bench.generate(count, 500, 500, -250, -250)

	local camera = h3d.camera_matrix()
	for i, v in ipairs(shapes) do
		if i > 0 then
			break
		end

		local buffer = geometry
			.position(v[1].x, v[1].y, 500)
			.position(v[2].x, v[2].y, 500)
			.position(v[3].x, v[3].y, 500)
			.face('color', C)
			.build()

		raster.drawGeometry(buffer, camera)
	end
	raster_clear()
	raster.get_raster_info()

	local t1 = os.clock()
	C = 1
	for i, v in ipairs(shapes) do
		C = (i * 3 + C * 17 + 100) % 220
		geometry
			.position(v[1].x, v[1].y, 500)
			.position(v[2].x, v[2].y, 500)
			.position(v[3].x, v[3].y, 500)
			.face('color', C)

		if i % 2000 == 0 then
			os.sleep(0)
		end
	end
	local t2 = os.clock()
	raster.drawGeometry(geometry.build(), camera)

	local info = raster.get_raster_info()
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
				dd = -1
			elseif key == keys.leftShift then
				dd = 1
			elseif key == keys.q then
				p_ry = p_ry + rs
			elseif key == keys.e then
				p_ry = p_ry - rs
			elseif key == keys.r then
				p_rx = p_rx + rs
			elseif key == keys.f then
				p_rx = p_rx - rs
			end

			p_z = p_z - (ff * math.cos(math.rad(p_ry)) + ss * math.sin(math.rad(p_ry))) * ms
			p_x = p_x + (ff * math.sin(math.rad(p_ry)) - ss * math.cos(math.rad(p_ry))) * ms
			p_y = p_y - dd / 3.0
		end
	end, render_loop)
end

-- render_benchmark
-- Make sure we reset
local _, err = xpcall(key_press, function(...)
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
