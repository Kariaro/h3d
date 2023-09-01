local h3d_format = require 'h3d_format'
local h3d = {}

-- Create a new render pipeline
function h3d.create_pipeline(data)
	local VERTEX_ATTRIBUTES = data.vertex_attributes
	local FACE_ATTRIBUTES   = data.face_attributes
	local FRAG_SHADER       = data.frag_shader

	local h = fs.open(fs.combine(shell.dir(), 'h3d_raster.plua'), 'r')
	local content = h.readAll()
	h.close()

	print('Creating raster pipeline')
	local result = h3d_format.template(content, {
		VERTEX_ATTRIBUTES = VERTEX_ATTRIBUTES,
		FACE_ATTRIBUTES   = FACE_ATTRIBUTES
	}, function(name, source)
		local h = fs.open(fs.combine(shell.dir(), name .. '.lua'), 'w')
		h.write(source)
		h.close()
	end)

	return result
end

function h3d.load_image(name)
	local f = fs.open('dev/test/img/' .. name, 'rb')
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
