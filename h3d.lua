local h3d_format = require 'h3d_format'
local h3d_matrix = require 'h3d_matrix'
local vsl_format = require 'vsl_format'
local h3d = {}


--- Returns a geometry builder object
--- @return H3DGeometry geometry a geometry builder object
local function geometry(
	VERTEX_ATTRIBUTES,
	FACE_ATTRIBUTES,
	position_attr,
	texture_attr,
	color_attr
)
	--- @class H3DGeometry
	--- @field private data table
	--- @field private fa_count table
	--- @field private va_count table
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

	--- Add vertex position data
	--- @param ... any the values added to the attribute
	function M.position(...)
		return position_attr and M.vertex(position_attr.name, ...) or M
	end

	--- Add vertex texture data
	--- @param ... any the values added to the attribute
	function M.texture(...)
		return texture_attr and M.vertex(texture_attr.name, ...) or M
	end

	--- Add color texture data
	--- @param ... any the values added to the attribute
	function M.color(...)
		return color_attr and M.vertex(color_attr.name, ...) or M
	end

	--- Add vertex data
	--- @param name string the name of the vertex attribute
	--- @param ... any the values added to the attribute
	function M.vertex(name, ...)
		local attribute = va_attributes[name]
		if attribute == nil then
			return M
		end

		local vd = {...}
		local vi = attribute.index
		local vc = attribute.count
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

	--- Add face data
	--- @param name string the name of the face attribute
	--- @param ... any the values added to the attribute
	function M.face(name, ...)
		local attribute = fa_attributes[name]
		if attribute == nil then
			return M
		end

		local vd = {...}
		local vi = attribute.index
		local vc = attribute.count
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

	--- Returns a reference to the built geometry
	--- @return number[] buffer an array of geometry data
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

--- @class H3DPipelineData
--- @field vertex_attributes H3DAttribute[] An array of attribute data
--- @field face_attributes H3DAttribute[] An array of attribute data
--- @field layers string[] An array of layer names
--- @field frag_shader string The fragment shader code
--- @field debug_statistics boolean If the pipeline should add debug statistics


--- Create a default render pipeline that contains `position`, `uv` and `color`
--- @return H3DRaster raster, H3DGeometry pipeline
function h3d.create_default_pipeline()
	return h3d.create_pipeline({
		debug_statistics = false,
		vertex_attributes = {
			h3d.attr('position', 3, h3d.AttributeType.Position),
			h3d.attr('uv', 2, h3d.AttributeType.Texture),
			h3d.attr('color', 3, h3d.AttributeType.Color),
		},
		face_attributes = {},
		layers = {
			'color',
			'depth'
		},
		frag_shader = [[
			if gl_layer('depth') > gl_depth then
				gl_set_layer('depth', gl_depth)
				if gl_HasTexture then
					local textureValue = gl_tex(gl_uv_x, gl_uv_y)
					gl_set_layer('color', textureValue)
				else
					local colorValue = gl_rgb(gl_r, gl_g, gl_b)
					gl_set_layer('color', colorValue)
				end
			end
		]]
	})
end


--- Create a new render pipeline
--- @param data H3DPipelineData data
--- @return H3DRaster raster, H3DGeometry pipeline
function h3d.create_pipeline(data)
	local VERTEX_ATTRIBUTES = data.vertex_attributes or {}
	local FACE_ATTRIBUTES   = data.face_attributes or {}
	local LAYERS            = data.layers or {}
	local FRAG_SHADER       = data.frag_shader
	local DEBUG_STATISTICS  = data.debug_statistics

	local h = fs.open(fs.combine(shell.dir(), 'h3d_raster.plua'), 'r')
	local content = h.readAll()
	h.close()

	local POSITION_ATTRIBUTE = nil
	local TEXTURE_ATTRIBUTE  = nil
	local COLOR_ATTRIBUTE    = nil
	for _, v in pairs(VERTEX_ATTRIBUTES) do
		if v.position then
			POSITION_ATTRIBUTE = v
		elseif v.texture then
			TEXTURE_ATTRIBUTE = v
		elseif v.color then
			COLOR_ATTRIBUTE = v
		end
	end

	if POSITION_ATTRIBUTE == nil then
		error('Pipeline does not define a position vertex attribute')
	end

	local shader = vsl_format.process(FRAG_SHADER, {
		layers = LAYERS,
		vertex_attributes = VERTEX_ATTRIBUTES,
		face_attributes = FACE_ATTRIBUTES,
		position = POSITION_ATTRIBUTE,
		texture = TEXTURE_ATTRIBUTE,
		color = COLOR_ATTRIBUTE,
		debug = DEBUG_STATISTICS,
	})

	--- @type H3DRaster
	local result = h3d_format.process(content, {
		VERTEX_ATTRIBUTES  = VERTEX_ATTRIBUTES,
		FACE_ATTRIBUTES    = FACE_ATTRIBUTES,
		LAYERS             = LAYERS,

		POSITION_ATTRIBUTE = POSITION_ATTRIBUTE,

		FRAG_SHADER = shader.frag_shader,
		SHADER = shader
	}, function(name, source)
		if data.debug_files then
			local tmp = fs.open(fs.combine(shell.dir(), name .. '.lua'), 'w')
			tmp.write(source)
			tmp.close()
		end
	end)

	return result, geometry(
		-- Attribute arrays
		VERTEX_ATTRIBUTES,
		FACE_ATTRIBUTES,

		-- Special attributes
		POSITION_ATTRIBUTE,
		TEXTURE_ATTRIBUTE,
		COLOR_ATTRIBUTE
	)
end


--- Returns a new camera matrix
--- @return H3DMatrix matrix An identity matrix
function h3d.camera_matrix()
	return h3d_matrix:new()
end


--- Returns a new camera matrix
--- @param settings { fov: number, aspect: number, x: number, y: number, z: number, yaw: number, pitch: number, roll: number } the settings of the camera
--- @return H3DMatrix
--- @deprecated do not use
function h3d.camera(settings)
	return h3d_matrix:new()
		:perspective(settings.fov, settings.aspect, 0.0001, 10000)
		:rotate     (settings.pitch, 1, 0, 0)
		:rotate     (settings.yaw,   0, 1, 0)
		:rotate     (settings.roll,  0, 0, 1)
		:translate  (-settings.x, -settings.y, -settings.z)
end

--- @enum H3DAttributeType
h3d.AttributeType = {
	Position = 1,
	Texture  = 2,
	Color    = 3,
}

--- @class H3DAttribute
--- @field name string The attribute name
--- @field count integer The number of components this attribute has
--- @field position boolean? If this is a position attribute
--- @field texture boolean? If this is a texture attribute 
--- @field color boolean? If this is a color attribute 

--- Creates an attribute to be used in a pipeline
--- @param name string the name of the attribute
--- @param count integer the number of values in the attribute
--- @param type H3DAttributeType? special attribute data
--- @nodiscard
--- @return H3DAttribute attribute a new vertex attribute
function h3d.attr(name, count, type)
	local attribute = {
		name = name,
		count = count
	}

	if type == nil then
		-- Do nothing
	elseif type == h3d.AttributeType.Position then
		attribute.position = true
	elseif type == h3d.AttributeType.Texture then
		attribute.texture = true
	elseif type == h3d.AttributeType.Color then
		attribute.color = true
	end

	return attribute
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
