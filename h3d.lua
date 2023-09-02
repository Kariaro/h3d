local h3d_format = require 'h3d_format'
local vsl_format = require 'vsl_format'
local h3d = {}

-- Create a new render pipeline
function h3d.create_pipeline(data)
	local VERTEX_ATTRIBUTES = data.vertex_attributes or {}
	local FACE_ATTRIBUTES   = data.face_attributes or {}
	local LAYERS            = data.layers or {}
	local FRAG_SHADER       = data.frag_shader

	local h = fs.open(fs.combine(shell.dir(), 'h3d_raster.plua'), 'r')
	local content = h.readAll()
	h.close()

	local POSITION_ATTRIBUTE = nil
	for _, v in pairs(VERTEX_ATTRIBUTES) do
		if v.position then
			POSITION_ATTRIBUTE = v
			break
		end
	end

	if POSITION_ATTRIBUTE == nil then
		POSITION_ATTRIBUTE = {
			name = '',
			count = 3,
			position = true
		}
		table.insert(VERTEX_ATTRIBUTES, 1, POSITION_ATTRIBUTE)
	end

	local shader = vsl_format.template(
		FRAG_SHADER,
		LAYERS,
		VERTEX_ATTRIBUTES,
		FACE_ATTRIBUTES,
		POSITION_ATTRIBUTE
	)

	print('Creating raster pipeline')
	local result = h3d_format.template(content, {
		VERTEX_ATTRIBUTES  = VERTEX_ATTRIBUTES,
		FACE_ATTRIBUTES    = FACE_ATTRIBUTES,
		LAYERS             = LAYERS,

		POSITION_ATTRIBUTE = POSITION_ATTRIBUTE,

		FRAG_SHADER = shader
	}, function(name, source)
		local h = fs.open(fs.combine(shell.dir(), name .. '.lua'), 'w')
		h.write(source)
		h.close()
	end)

	return result, h3d.geometry(VERTEX_ATTRIBUTES, FACE_ATTRIBUTES)
end

function h3d.geometry(VERTEX_ATTRIBUTES, FACE_ATTRIBUTES)
	local M = {}
	M.data = {}
	M.va_count = {}
	M.fa_count = {}

	local va_attributes = {}
	local fa_attributes = {}
	local face_size = 0
	for _, v in pairs(VERTEX_ATTRIBUTES) do
		va_attributes[v.name] = {
			count = v.count * 3,
			index = face_size
		}
		face_size = face_size + v.count * 3
	end
	for _, v in pairs(FACE_ATTRIBUTES) do
		fa_attributes[v.name] = {
			count = v.count,
			index = face_size
		}
		face_size = face_size + v.count
	end

	for name, _ in pairs(va_attributes) do
		M.va_count[name] = 0
	end
	for name, _ in pairs(fa_attributes) do
		M.fa_count[name] = 0
	end

	function M.vertex(name, ...)
		local attribute = va_attributes[name]
		if attribute == nil then
			return M
		end

		local vd = {...}
		local vi = attribute.index
		local vc = attribute.count

		-- print('Adding "va_' .. name .. '" [' .. textutils.serialize({...}, { compact=true }) .. ']')
		local count = M.va_count[name]
		for i=1,#vd do
			local step = math.floor(count / vc)
			local rest = count - step * vc
			local idx = step * face_size + vi + 1 + rest
			M.data[idx] = vd[i]
			count = count + 1
		end
		M.va_count[name] = count
		return M
	end

	function M.face(name, ...)
		local attribute = fa_attributes[name]
		if attribute == nil then
			return M
		end

		local vd = {...}
		local vi = attribute.index
		local vc = attribute.count

		-- print('Adding "fa_' .. name .. '" [' .. textutils.serialize({...}, { compact=true }) .. ']')
		local count = M.fa_count[name]
		for i=1,#vd do
			local step = math.floor(count / vc)
			local rest = count - step * vc
			local idx = step * face_size + vi + 1 + rest
			M.data[idx] = vd[i]
			count = count + 1
		end
		M.fa_count[name] = count
		return M
	end

	function M.build()
		local triangles = 0
		for name, value in pairs(va_attributes) do
			triangles = math.max(triangles, math.floor(M.va_count[name] / value.count))
			M.va_count[name] = 0
		end
		for name, value in pairs(fa_attributes) do
			triangles = math.max(triangles, math.floor(M.fa_count[name] / value.count))
			M.fa_count[name] = 0
		end

		local data = M.data
		for i=1,triangles * face_size do
			if data[i] == nil then
				data[i] = 0
			end
		end
		return data
	end
	return M
end

function h3d.load_image(name)
	local f = fs.open('h3d/img/' .. name, 'rb')
	local w = f.read() + f.read() * 256
	local h = f.read() + f.read() * 256
	local data = {}

	while true do
		local read = f.read()
		if read == nil then
			break
		end

		data[#data + 1] = read
	end
	f.close()

	return {
		w = w,
		h = h,
		data = data
	}
end

return h3d
