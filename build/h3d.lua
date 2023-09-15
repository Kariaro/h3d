--- @class H3DMatrix
local h3d_matrix = {}

--- Construct a new 4x3 matrix
--- @return H3DMatrix
function h3d_matrix:new()
	local o = {}
	setmetatable(o, self)
	self.__index = self
	self.m00 = 1
	self.m01 = 0
	self.m02 = 0
	self.m10 = 0
	self.m11 = 1
	self.m12 = 0
	self.m20 = 0
	self.m21 = 0
	self.m22 = 1
	self.m30 = 0
	self.m31 = 0
	self.m32 = 0
	return o
end

function h3d_matrix:__tostring()
	local pattern =
		'Matrix[\n' ..
			'%.4f, %.4f, %.4f, %.4f,\n' ..
			'%.4f, %.4f, %.4f, %.4f,\n' ..
			'%.4f, %.4f, %.4f, %.4f\n' ..
		']'

	return string.format(pattern,
		self.m00, self.m10, self.m20, self.m30,
		self.m01, self.m11, self.m21, self.m31,
		self.m02, self.m12, self.m22, self.m32
	)
end

--- Transform this into the identity matrix
--- @return H3DMatrix self
function h3d_matrix:identity()
	self.m00 = 1
	self.m01 = 0
	self.m02 = 0
	self.m10 = 0
	self.m11 = 1
	self.m12 = 0
	self.m20 = 0
	self.m21 = 0
	self.m22 = 1
	self.m30 = 0
	self.m31 = 0
	self.m32 = 0
	return self
end


--- Create the invert of this matrix
--- @param dest H3DMatrix? the destination matrix
--- @return H3DMatrix matrix the destination matrix
function h3d_matrix:invert(dest)
	dest = dest or h3d_matrix:new()
	local m11m00, m10m01, m10m02 = self.m00 * self.m11, self.m01 * self.m10, self.m02 * self.m10
	local m12m00, m12m01, m11m02 = self.m00 * self.m12, self.m01 * self.m12, self.m02 * self.m11
	local m10m22, m10m21, m11m22 = self.m10 * self.m22, self.m10 * self.m21, self.m11 * self.m22
	local m11m20, m12m21, m12m20 = self.m11 * self.m20, self.m12 * self.m21, self.m12 * self.m20
	local m20m02, m20m01, m21m02 = self.m20 * self.m02, self.m20 * self.m01, self.m21 * self.m02
	local m21m00, m22m01, m22m00 = self.m21 * self.m00, self.m22 * self.m01, self.m22 * self.m00
	local s = 1.0 / ((m11m00 - m10m01) * self.m22 + (m10m02 - m12m00) * self.m21 + (m12m01 - m11m02) * self.m20)
	local nm00 = (m11m22 - m12m21) * s
	local nm01 = (m21m02 - m22m01) * s
	local nm02 = (m12m01 - m11m02) * s
	local nm10 = (m12m20 - m10m22) * s
	local nm11 = (m22m00 - m20m02) * s
	local nm12 = (m10m02 - m12m00) * s
	local nm20 = (m10m21 - m11m20) * s
	local nm21 = (m20m01 - m21m00) * s
	local nm22 = (m11m00 - m10m01) * s
	local nm30 = (m10m22 * self.m31 - m10m21 * self.m32 + m11m20 * self.m32 - m11m22 * self.m30 + m12m21 * self.m30 - m12m20 * self.m31) * s
	local nm31 = (m20m02 * self.m31 - m20m01 * self.m32 + m21m00 * self.m32 - m21m02 * self.m30 + m22m01 * self.m30 - m22m00 * self.m31) * s
	local nm32 = (m11m02 * self.m30 - m12m01 * self.m30 + m12m00 * self.m31 - m10m02 * self.m31 + m10m01 * self.m32 - m11m00 * self.m32) * s
	dest.m00 = nm00
	dest.m01 = nm01
	dest.m02 = nm02
	dest.m10 = nm10
	dest.m11 = nm11
	dest.m12 = nm12
	dest.m20 = nm20
	dest.m21 = nm21
	dest.m22 = nm22
	dest.m30 = nm30
	dest.m31 = nm31
	dest.m32 = nm32
	return dest
end


--- Translate this matrix locally
--- @param x number the x translation
--- @param y number the y translation
--- @param z number the z translation
--- @return H3DMatrix self
function h3d_matrix:translate(x, y, z)
	self.m30 = self.m00 * x + self.m10 * y + self.m20 * z + self.m30
	self.m31 = self.m01 * x + self.m11 * y + self.m21 * z + self.m31
	self.m32 = self.m02 * x + self.m12 * y + self.m22 * z + self.m32
	return self
end


--- Scale this matrix locally
--- @param x number the x scale
--- @param y number the y scale
--- @param z number the z scale
--- @return H3DMatrix self
function h3d_matrix:scale(x, y, z)
	self.m00 = self.m00 * x
	self.m01 = self.m01 * y
	self.m02 = self.m02 * z
	self.m10 = self.m10 * x
	self.m11 = self.m11 * y
	self.m12 = self.m12 * z
	self.m20 = self.m20 * x
	self.m21 = self.m21 * y
	self.m22 = self.m22 * z
	self.m30 = self.m30 * x
	self.m31 = self.m31 * y
	self.m32 = self.m32 * z
	return self
end


--- Rotate this matrix locally around an axis
--- @param angle number the angle in degrees
--- @param x number the x component of the axis
--- @param y number the y component of the axis
--- @param z number the z component of the axis
--- @return H3DMatrix self
function h3d_matrix:rotate(angle, x, y, z)
	local s = math.sin(math.rad(angle))
	local c = math.cos(math.rad(angle))
	local C = 1.0 - c
	local xx, xy, xz = x * x, x * y, x * z
	local yy, yz = y * y, y * z
	local zz = z * z
	local rm00 = xx * C + c
	local rm01 = xy * C + z * s
	local rm02 = xz * C - y * s
	local rm10 = xy * C - z * s
	local rm11 = yy * C + c
	local rm12 = yz * C + x * s
	local rm20 = xz * C + y * s
	local rm21 = yz * C - x * s
	local rm22 = zz * C + c
	local nm00 = self.m00 * rm00 + self.m10 * rm01 + self.m20 * rm02
	local nm01 = self.m01 * rm00 + self.m11 * rm01 + self.m21 * rm02
	local nm02 = self.m02 * rm00 + self.m12 * rm01 + self.m22 * rm02
	local nm10 = self.m00 * rm10 + self.m10 * rm11 + self.m20 * rm12
	local nm11 = self.m01 * rm10 + self.m11 * rm11 + self.m21 * rm12
	local nm12 = self.m02 * rm10 + self.m12 * rm11 + self.m22 * rm12
	self.m20 = self.m00 * rm20 + self.m10 * rm21 + self.m20 * rm22
	self.m21 = self.m01 * rm20 + self.m11 * rm21 + self.m21 * rm22
	self.m22 = self.m02 * rm20 + self.m12 * rm21 + self.m22 * rm22
	self.m00 = nm00
	self.m01 = nm01
	self.m02 = nm02
	self.m10 = nm10
	self.m11 = nm11
	self.m12 = nm12
	return self
end


--- Rotate this matrix locally around the x axis
--- @param angle number the angle in degrees
--- @return H3DMatrix self
function h3d_matrix:rotateX(angle)
	return self:rotate(angle, 1, 0, 0)
end


--- Rotate this matrix locally around the y axis
--- @param angle number the angle in degrees
--- @return H3DMatrix self
function h3d_matrix:rotateY(angle)
	return self:rotate(angle, 0, 1, 0)
end


--- Rotate this matrix locally around the z axis
--- @param angle number the angle in degrees
--- @return H3DMatrix self
function h3d_matrix:rotateZ(angle)
	return self:rotate(angle, 0, 0, 1)
end


--- Apply perspective to this matrix
--- @param fovy number the angle of view vertically
--- @param aspect number the aspect ratio of the window
--- @param zNear number the near value
--- @param zFar number the far value
--- @return H3DMatrix self
function h3d_matrix:perspective(fovy, aspect, zNear, zFar)
	local h = math.tan(math.rad(fovy) * 0.5)
	local rm00 = 1.0 / (h * aspect)
	local rm11 = 1.0 / h
	local rm22
	local rm32
	local farInf  = zFar  == math.huge
	local nearInf = zNear == math.huge
	if farInf then
		rm22 = (1.0 - 1e-6)
		rm32 = (2.0 - 1e-6) * zNear
	elseif nearInf then
		rm22 = (1e-6 - 1.0)
		rm32 = (1e-6 - 2.0) * zFar
	else
		rm22 = (zFar + zNear) / (zFar - zNear)
		rm32 = (zFar + zFar ) * zNear / (zFar - zNear)
	end
	local nm20 = self.m20 * rm22 - self.m30
	local nm21 = self.m21 * rm22 - self.m31
	local nm22 = self.m22 * rm22 - self.m32
	self.m00 = self.m00 * rm00
	self.m01 = self.m01 * rm00
	self.m02 = self.m02 * rm00
	self.m10 = self.m10 * rm11
	self.m11 = self.m11 * rm11
	self.m12 = self.m12 * rm11
	self.m30 = self.m20 * rm32
	self.m31 = self.m21 * rm32
	self.m32 = self.m22 * rm32
	self.m20 = nm20
	self.m21 = nm21
	self.m22 = nm22
	return self
end


--- Translate a point using this matrix
--- @param x number the x coordinate
--- @param y number the y coordinate
--- @param z number the z coordinate
--- @return number x, number y, number z the translated point
function h3d_matrix:transfer(x, y, z)
	local nx = self.m00 * x + self.m10 * y + self.m20 * z + self.m30
	local ny = self.m01 * x + self.m11 * y + self.m21 * z + self.m31
	local nz = self.m02 * x + self.m12 * y + self.m22 * z + self.m32
	return nx, ny, nz
end


local h3d_format = {}

-- TODO: Create a system that gives accurate line / column errors for 'code_pre' and 'code_gen'

--- Construct the pre template code from a source text
--- @param source string the input source
--- @return string template the template string
function h3d_format.pre_template(source)
	local function quote(text)
		return '\'' .. text:gsub('[\\\'\"\n\t]', { ['\\'] = '\\\\', ['\''] = '\\\'', ['\"'] = '\\\"', ['\n'] = '\\n', ['\t'] = '\\t' }) .. '\''
	end

	local lines = {}
	lines[1] = 'local __groups = { [\'__output\'] = {} }'
	lines[2] = 'local __output = __groups[\'__output\']'
	lines[3] = 'local __insert = function(text) for _, data in pairs(__groups) do table.insert(data, text) end end'

	local open_groups = {}
	local closed_groups = {}

	while #source > 0 do
		local s, _, t = source:find('{([%%!#])')
		if not s then
			table.insert(lines, '__insert(' .. quote(source) .. ')')
			break
		end
		local e, l = source:find((t == '%' and '%' or '') .. t .. '}(\n?)')
		if not e then
			error("Unclosed syntax '{" .. t .. "'")
		end
		if t == '!' then
			l = e + 1
		end

		table.insert(lines, '__insert(' .. quote(source:sub(1, s - 1)) .. ')')
		if t == '%' then
			local content = (source:sub(s + 2, e - 1):gsub('@insert', '__insert'))
			content = content:gsub('{#([a-zA-Z_]+)#}', 'table.concat(___%1, \'\')')

			table.insert(lines, content)
		elseif t == '!' then
			local content = source:sub(s + 2, e - 1)
			content = content:gsub('{#([a-zA-Z_]+)#}', 'table.concat(___%1, \'\')')
			table.insert(lines, '__insert(tostring(' .. content .. '))')
		elseif t == '#' then
			local name = source:sub(s + 2, e - 1)
			if name:find('$[a-zA-Z0-9_-]+^') then
				error("Group had invalid name")
			end

			name = '___' .. name
			if closed_groups[name] then
				table.insert(lines, '__insert(table.concat(' ..  name .. ', \'\'))')
			elseif open_groups[name] then
				table.insert(lines, '__groups[\'' .. name .. '\'] = nil')
				closed_groups[name] = true
				open_groups[name] = nil
			else
				table.insert(lines, 'local ' .. name .. ' = {}')
				table.insert(lines, '__groups[\'' .. name .. '\'] = ' .. name)
				open_groups[name] = true
			end
		end
		source = source:sub(l + 1)
	end
	table.insert(lines, 'return table.concat(__output, \'\')')

	source = table.concat(lines, '\n')
	return source
end

--- Format an input source code
---
--- @param source      string     the input source code
--- @param environment table      custom environment table
--- @param callback    function?  callback function for pre and gen stages
--- @return any parsed the parsed output of the input source
function h3d_format.process(source, environment, callback)

	if callback then
		callback('code_pre', source)
	end

	local env = {}
	env._G = env
	env._VERSION = _VERSION
	env.bit32 = bit32
	env.assert = assert
	env.error = error
	env.getmetatable = getmetatable
	env.ipairs = ipairs
	env.load = load
	env.next = next
	env.pairs = pairs
	env.pcall = pcall
	env.print = print
	env.rawequal = rawequal
	env.rawget = rawget
	env.rawlen = rawlen
	env.rawset = rawset
	env.select = select
	env.setmetatable = setmetatable
	env.tonumber = tonumber
	env.tostring = tostring
	env.type = type
	env.xpcall = xpcall
	env.math = math
	env.string = string
	env.table = table
	for k,v in pairs(environment) do
		env[k] = v
	end

--- @diagnostic disable
	local f, err = load(source, 'template_code', 't', env)
	if not f then
		error('Invalid code syntax: ' .. err)
	end
	local status, result = xpcall(f, function(...)
		print(debug.traceback())
		return ...
	end)
	if not status then
		error('Invalid precode syntax: ' .. tostring(result))
	end

	if callback then
		callback('code_gen', result)
	end

	local code, err = load(result, 'generated', 't')
	if code then
		xpcall(code, function(...)
			print('Failed to run generated code')
			print(debug.traceback())
			print()
			print('error:')
			local a = ...
			print('  ' .. a)
		end)
	else
		print('Failed to load generated code: ' .. err)
	end
	return code()
--- @diagnostic enable
end


local vsl_format = {}

--- Split a string into tokens
--- 
--- @param source string a string
--- @param patterns table a table containing the patterns
--- @return table tokens a table of tokens
local function tokenize(source, patterns)
	local result = {}
	local column = 1
	local line   = 1

	while #source > 0 do
		local group = nil
		local count = nil
		for _, pattern in pairs(patterns) do
			for i=2,#pattern do
				local cmd = pattern[i]
				if type(cmd) == 'function' then
					local e = cmd(source)
					if e ~= nil and e > 0 then
						group = pattern[1]
						count = e
						break
					end
				else
					local s, e = source:find(cmd, 0, true)
					if s == 1 and e > 0 then
						group = pattern[1]
						count = e
						break
					end
				end
			end

			if count ~= nil then
				break
			end
		end

		if count == nil then
			error('vsl parser got stuck on (column: ' .. column .. ', line: ' .. line .. ')')
		end

		local content = source:sub(1, count)

		if group ~= nil then
			result[#result + 1] = {
				type = group,
				value = content,
				line = line,
				column = column
			}
		end

		for i=1,count do
			local c = source:sub(i,i)
			if c == '\n' then
				line = line + 1
				column = 1
			else
				column = column + 1
			end
		end

		source = source:sub(count + 1)
	end

	return result
end

local function token_list(tokens)
	local M = {}
	M.tokens = tokens
	M.idx = 1

	function M.next()
		M.idx = M.idx + 1
		return M.tokens[M.idx - 1]
	end

	function M.token()
		return M.tokens[M.idx]
	end

	function M.value()
		local token = M.token()
		return token and token.value or nil
	end

	function M.type()
		local token = M.token()
		return token and token.type or nil
	end

	function M.require_value(r_value)
		local value = M.value()
		if value ~= r_value then
			M.error("Required value '%s' but got '%s'", r_value, value)
		end
		M.next()
	end

	function M.pos()
		local token = M.token()
		return token and { line = token.line, column = token.column } or nil
	end

	function M.index()
		return M.idx
	end

	function M.hasMore()
		return M.idx <= #M.tokens
	end

	function M.error(message, ...)
		message = string.format(message, ...)
		local curr = M.token()
		error('(line: ' .. curr.line .. ', column: ' .. curr.column .. ') ' .. message)
	end

	return M
end

--- @class VSLOutput
--- @field used_layers table A table that contains which layers were used
-- @field used_textures table (EXPERIMENTAL)
--- @field used_vertex_attributes table A table that contains which vertex attribute components were used
--- @field used_face_attributes table A table that contains which face attribute components were used
--- @field uses_barycentric boolean If the shader needs barycentric coordinates
--- @field frag_shader string? The shader code


--- @class VSLContext
--- @field vertex_attributes H3DAttribute[] An array of vertex attributes
--- @field face_attributes H3DAttribute[] An array of face attributes
--- @field layers string[] An array of layer names
--- @field position H3DAttribute A position attribute
--- @field texture H3DAttribute? A texture attribute
--- @field color H3DAttribute? A color attribute
--- @field debug boolean If debug data should be added

--- Process the vsl code and convert it into a shader
---
--- @param source string the vsl shader code
--- @param context VSLContext a table with data
--- @return VSLOutput output a table containing the processed shader
function vsl_format.process(source, context)
	local function _get(pattern)
		return function(text)
			local s, e = text:find(pattern)
			if s == 1 then
				return e
			end
			return 0
		end
	end

	local patterns = {
		{ nil,    _get('%-%-[^\n]+') },
		{ nil,    _get('[ \t\r\n]+') },
		{ 'str',  _get("'[^\n]-'") },
		{ 'num',  _get("[0-9]+%.[0-9]+"), _get("[0-9]+") },
		{ 'op',   '==', '>=', '<=', '~=', '%', '<', '>', '*', '-', '+', '/', '(', ')', '=', '.', ',' },
		{ 'op',   'if', 'then', 'else', 'end', 'for', 'do', 'local' },
		{ 'bool', 'true', 'false' },
		{ 'name', _get('[a-zA-Z][a-zA-Z0-9_]*') },
	}

	local tokens = tokenize(source, patterns)

	--[[
	local function quote(text)
		return '\'' .. text:gsub('[\\\'\"\n\t]', {
			['\\'] = '\\\\',
			['\''] = '\\\'',
			['\"'] = '\\\"',
			['\n'] = '\\n',
			['\t'] = '\\t'
		}) .. '\''
	end
	for _, v in pairs(tokens) do
		print(string.format('(line: %3d, column: %3d) %-10s %s',
			v.line,
			v.column,
			v.type,
			quote(v.value)
		))
	end
	]]

	local POSITION_ATTRIBUTE = context.position
	local TEXTURE_ATTRIBUTE  = context.texture
	local COLOR_ATTRIBUTE    = context.color
	local FACE_ATTRIBUTES    = context.face_attributes
	local VERTEX_ATTRIBUTES  = context.vertex_attributes
	local LAYERS             = context.layers
	local DEBUG              = context.debug

	--- @type VSLOutput
	local output = {
		-- A list of accessed layers
		used_layers = {},

		-- A list of accessed textures (EXPERIMENTAL)
		used_textures = {},

		-- A list of used vertex attributes
		used_vertex_attributes = {},

		-- A list of used face attributes
		used_face_attributes = {},

		-- If the pipeline used barycentric coordinates
		uses_barycentric = false,

		-- The fragment shader output
		frag_shader = nil
	}

	local function find_vertex_attribute(name)
		for _, attr in pairs(VERTEX_ATTRIBUTES) do
			if attr.name == name then
				return attr
			end
		end
		return nil
	end

	local function find_face_attribute(name)
		for _, attr in pairs(FACE_ATTRIBUTES) do
			if attr.name == name then
				return attr
			end
		end
		return nil
	end

	local function find_layer(name)
		for _, layer in pairs(LAYERS) do
			if layer == name then
				return layer
			end
		end
		return nil
	end

	local suffix_list = { 'x', 'y', 'z', 'w'}
	local ast = vsl_format.parse(token_list(tokens))
	output.frag_shader = vsl_format.build_code(ast, {
		variable = function(ast_error, name)
			if name == 'gl_x' or name == 'gl_y' or name == 'gl_z' or name == 'gl_depth' then
				local attribute = POSITION_ATTRIBUTE
				if attribute == nil then
					ast_error('No position attribute has been defined')
				else
					local lookup_value  = { gl_x = 1, gl_y = 2, gl_z = 4, gl_depth = 4 }
					local lookup_suffix = { gl_x = 'x', gl_y = 'y' }
					local used = output.used_vertex_attributes[attribute.name] or 0
					output.used_vertex_attributes[attribute.name] = bit32.bor(used, lookup_value[name])

					if name == 'gl_z' or name == 'gl_depth' then
						return '__va', 'depth'
					end
					local value = 'va_' .. attribute.name .. '_' .. lookup_suffix[name]
					return '__' .. value, value
				end
			elseif name == 'gl_r' or name == 'gl_g' or name == 'gl_b' then
				local attribute = COLOR_ATTRIBUTE
				if attribute == nil then
					ast_error('No color attribute has been defined')
				else
					local lookup_value  = { gl_r = 1, gl_g = 2, gl_b = 4 }
					local lookup_suffix = { gl_r = 'x', gl_g = 'y', gl_b = 'z' }
					local used = output.used_vertex_attributes[attribute.name] or 0
					output.used_vertex_attributes[attribute.name] = bit32.bor(used, lookup_value[name])
					local value = 'va_' .. attribute.name .. '_' .. lookup_suffix[name]
					return '__' .. value, value
				end
			elseif name == 'gl_uv_x' or name == 'gl_uv_y' then
				local attribute = TEXTURE_ATTRIBUTE
				if attribute == nil then
					ast_error('No texture attribute has been defined')
				else
					local lookup_value  = { gl_uv_x = 1, gl_uv_y = 2 }
					local lookup_suffix = { gl_uv_x = 'x', gl_uv_y = 'y' }
					local used = output.used_vertex_attributes[attribute.name] or 0
					output.used_vertex_attributes[attribute.name] = bit32.bor(used, lookup_value[name])
					local value = 'va_' .. attribute.name .. '_' .. lookup_suffix[name]
					return '__' .. value, value
				end
			elseif name == 'gl_HasTexture' then
				return nil, 'TEXTURE ~= nil'
			end
			return nil, nil
		end,

		builtin = {
			gl_face = function(ast_error, args)
				if not args[1]:match("^'") then
					ast_error("Expected string parameter")
				end

				local data = args[1]:sub(2, #args[1] - 1)
				local attribute = find_face_attribute(data)
				if attribute == nil then
					ast_error("Could not find face attribute '" .. data .. "'")
					error()
				end

				if attribute.count > 1 and #args ~= 2 then
					ast_error("Built in 'gl_face' requires 2 parameters")
					error()
				elseif #args ~= 1 then
					ast_error("Built in 'gl_face' only has 1 parameter")
					error()
				end

				local suffix = ''
				local used = output.used_face_attributes[data] or 0
				if attribute.count > 1 then
					local idx = tonumber(args[2]) + 1
					suffix = '_' .. suffix_list[idx]
					output.used_face_attributes[data] = bit32.bor(used, 2 ^ (idx - 1))
				else
					output.used_face_attributes[data] = bit32.bor(used, 1)
				end

				return nil, 'fa_' .. attribute.name .. suffix
			end,

			gl_vertex = function(ast_error, args)
				if not args[1]:match("^'") then
					ast_error("Expected string parameter")
				end

				local data = args[1]:sub(2, #args[1] - 1)
				local attribute = find_vertex_attribute(data)
				if attribute == nil then
					ast_error("Could not find vertex attribute '" .. data .. "'")
					error()
				end

				local suffix = ''
				local used = output.used_vertex_attributes[data] or 0
				if attribute.count > 1 then
					local idx = tonumber(args[2]) + 1
					suffix = '_' .. suffix_list[idx]
					output.used_vertex_attributes[data] = bit32.bor(used, 2 ^ (idx - 1))
				else
					output.used_face_attributes[data] = bit32.bor(used, 1)
				end

				return '__va_' .. attribute.name .. suffix, 'va_' .. attribute.name .. suffix
			end,

			gl_layer = function(ast_error, args)
				if #args ~= 1 then
					ast_error("Built in 'gl_layer' only has 1 parameter")
				end

				if not args[1]:match("^'") then
					ast_error("Expected string parameter")
				end

				local data = args[1]:sub(2, #args[1] - 1)
				local layer = find_layer(data)
				if layer == nil then
					ast_error("Layer '" .. data .. "' does not exist")
				end

				output.used_layers[data] = true
				return nil, 'layer_' .. data .. '_y[xx]'
			end,

			gl_set_layer = function(ast_error, args)
				if #args ~= 2 then
					ast_error("Built in 'gl_set_layer' only has 2 parameters")
				end

				if not args[1]:match("^'") then
					ast_error("Expected string parameter")
				end

				local data = args[1]:sub(2, #args[1] - 1)
				local layer = find_layer(data)
				if layer == nil then
					ast_error("Layer '" .. data .. "' does not exist")
				end

				output.used_layers[data] = true
				local result = 'layer_' .. data .. '_y[xx] = ' .. args[2]
				if DEBUG then
					result = result .. '\nlayer_' .. data .. '_write = layer_' .. data .. '_write + 1'
				end
				return nil, result
			end,

			gl_rgb = function(ast_error, args)
				local result = (
					'(_math_floor(_math_clamp({1} * 6, 0, 5.999))) + ' ..
					'(_math_floor(_math_clamp({2} * 6, 0, 5.999)) * 6) + ' ..
					'(_math_floor(_math_clamp({3} * 6, 0, 5.999)) * 36)'
				)
				result = result:gsub('{1}', args[1]):gsub('{2}', args[2]):gsub('{3}', args[3])
				return nil, result
			end,

			gl_tex = function(ast_error, args)
				local idx = '_math_clamp(_math_floor({x} * tw), 0, tw - 1) + (_math_clamp(_math_floor({y} * th), 0, th - 1) * tw) + 1'
				idx = idx
					:gsub('{x}', args[1])
					:gsub('{y}', args[2])
				return nil, 'td[' .. idx .. ']'
			end,

			min = function(ast_error, args)
				return nil, '_math_min(' .. table.concat(args, ', ') .. ')'
			end,

			max = function(ast_error, args)
				return nil, '_math_max(' .. table.concat(args, ', ') .. ')'
			end,

			floor = function(ast_error, args)
				return nil, '_math_floor(' .. args[1] .. ')'
			end,

			ceil = function(ast_error, args)
				return nil, '_math_ceil(' .. args[1] .. ')'
			end
		},
		format_data = function(data)
			local lines = {}
			local has_bary = false
			for name, _ in pairs(data) do
				if name:match('^__va') then
					has_bary = true
					if #name > 4 then
						local value = 'local ' .. name:sub(3) .. ' = depth * ' .. ('({t}1 + in_{t}2 * l_a + in_{t}3 * l_b)')
						table.insert(lines, value:gsub('{t}', name:sub(3)))
					end
				end
			end

			output.uses_barycentric = has_bary
			return table.concat(lines, '\n')
		end
	})

	return output
end


--- Build the code from the constructed AST
---
--- @param in_ast any a tree of syntax
--- @param context table context methods
--- @return string code the output code
function vsl_format.build_code(in_ast, context)
	local scope = {}
	local l_scope = nil
	local function push_scope()
		l_scope = {}
		scope[#scope + 1] = l_scope
	end

	local function pop_scope()
		table.remove(scope, #scope)
		l_scope = scope[#scope]
	end

	local function ast_error(ast, message)
		local l = ast.pos and ast.pos.line or -1
		local c = ast.pos and ast.pos.column or -1
		error('(line: ' .. l .. ', column: ' .. c .. ', type: ' .. ast[1] .. ') ' .. message)
	end

	local function get_var(name)
		for i=#scope,1,-1 do
			local f_name = scope[i][name]
			if f_name ~= nil then
				return f_name
			end
		end
		return nil
	end

	local function add_var(name, f_name)
		l_scope[name] = f_name
	end

	local function indent(text, tabs)
		local lines = {}
		for s in string.gmatch(text .. "\n", "(.-)\n") do
			table.insert(lines, s)
		end
		local pad = ''
		for i=1,tabs do
			pad = pad .. '\t'
		end
		return pad .. table.concat(lines, '\n' .. pad):gsub('\n[\t]+\n', '\n\n')
	end

	push_scope()

	local pre_data = {}
	local format_statements
	local format_call

	local function format_expr(ast)
		if ast[1] == 'P_EXPR' then
			return '(' .. format_expr(ast[2]) .. ')'
		elseif ast[1] == 'B_EXPR' then
			return format_expr(ast[3]) .. ' ' .. ast[2] .. ' ' .. format_expr(ast[4])
		elseif ast[1] == 'U_EXPR' then
			return ast[2] .. ' ' .. format_expr(ast[3])
		elseif ast[1] == 'ATOM' then
			return ast[2]
		elseif ast[1] == 'NAME' then
			local data, value = context.variable(
				function(message) ast_error(ast, message) end,
				ast[2]
			)

			if data ~= nil then
				pre_data[data] = true
			end

			local name = get_var(ast[2])

			return value and value or (name or ast[2])
		elseif ast[1] == 'CALL' then
			return format_call(ast)
		end

		return '<not-impl-' .. tostring(ast[1]) .. '>'
	end

	local function format_if(ast)
		push_scope()
		local lines = {
			'if ' .. format_expr(ast[2]) .. ' then',
			indent(format_statements(ast[3]), 1)
		}

		if ast[4] ~= nil then
			table.insert(lines, 'else')
			table.insert(lines, indent(format_statements(ast[4]), 1))
		end

		table.insert(lines, 'end')
		pop_scope()
		return table.concat(lines, '\n')
	end

	local function format_set(ast)
		local f_name = get_var(ast[2])
		if get_var(ast[2]) == nil then
			ast_error(ast, "Variable '" .. ast[2] .. "' is not defined")
		end

		return f_name .. ' = ' .. format_expr(ast[3])
	end

	local function format_var(ast)
		for index, name in ipairs(ast[2]) do
			if get_var(name) then
				ast_error(ast, "Variable '" .. name .. "' is redefined")
			end
			local f_name = '___' .. name
			add_var(name, f_name)
			ast[2][index] = f_name
		end

		local result = 'local ' .. table.concat(ast[2], ', ')
		if #ast > 2 then
			result = result .. ' = ' .. format_expr(ast[3])
		end

		return result
	end

	format_call = function(ast)
		local args = {}
		for index, expr in ipairs(ast[3]) do
			if index > 1 then
				args[#args + 1] = format_expr(expr)
			end
		end

		local func = context.builtin[ast[2]]
		if func == nil then
			return ast[2] .. '(' .. table.concat(args, ', ') .. ')'
		end

		local data, value = func(
			function(message) ast_error(ast, message) end,
			args
		)

		if data ~= nil then
			pre_data[data] = true
		end

		if value == nil then
			return ''
		end

		return value
	end

	format_statements = function(ast)
		local lines = {}
		for i=2,#ast do
			local stat = ast[i]
			local type = stat[1]

			if stat == nil then
				ast_error(ast, "Nil statement '" .. type .. "'")
			end

			if type == 'IF' then
				lines[#lines + 1] = format_if(stat)
			elseif type == 'VAR' then
				lines[#lines + 1] = format_var(stat)
			elseif type == 'SET' then
				lines[#lines + 1] = format_set(stat)
			elseif type == 'CALL' then
				lines[#lines + 1] = format_call(stat)
			else
				ast_error(ast, "Unknown type '" .. type .. "'")
			end
		end

		return table.concat(lines, '\n')
	end

	local code = format_statements(in_ast)
	local before = context.format_data(pre_data) or ''
	if #before > 1 then
		before = before .. '\n'
	end

	return before .. code
end

--- Parse a given list of tokens into an AST
---
--- @param reader any a token reader
--- @return table ast an AST containing all the symbols
function vsl_format.parse(reader)
	local function create_lookup(...)
		local result = {}
		for _, v in ipairs({...}) do
			result[v] = true
		end
		return result
	end

	local binary = create_lookup('>=', '==', '<=', '<', '>', '+', '-', '*', '/', 'and', 'or', '.')
	local unary  = create_lookup('not', '-')
	local expression
	local statement_list

	local function sub_expression()
		local pos = reader.pos()
		local r_type = reader.type()
		local r_value = reader.value()

		if r_value == '(' then -- First check for parenthesis
			reader.next()
			local content = expression(true)
			reader.require_value(')')
			return { 'P_EXPR', content; pos = pos }
		elseif r_type == 'name' then
			reader.next()
			if reader.value() == '(' then
				reader.next()
				local args = expression(true)
				if args[1] ~= 'C_EXPR' then
					args = { 'C_EXPR', args; pos = args.pos }
				end
				reader.require_value(')')
				return { 'CALL', r_value, args; pos = pos }
			end
			return { 'NAME', r_value; pos = pos }
		elseif unary[r_value] then -- Then check for unary
			reader.next()
			return { 'U_EXPR', r_value, expression(false); pos = pos }
		elseif r_type == 'str' or r_type == 'num' or r_type == 'bool' then -- Stop
			reader.next()
			return { 'ATOM', r_value; pos = pos }
		end

		reader.error("Could not parse sub expression '%s'", r_value)
	end

	expression = function(allow_comma)
		local a = sub_expression()

		local r_value = reader.value()
		if binary[r_value] then
			reader.next()
			local b = expression(false)
			if b ~= nil then
				a = { 'B_EXPR', r_value, a, b; pos = a.pos }
			end
		end

		if allow_comma and reader.value() == ',' then
			reader.next()
			local n_expr = expression(true)

			if n_expr == nil then
				reader.error('Expected expression after comma')
				error()
			end

			local result = { 'C_EXPR', a; pos = a.pos }
			if n_expr[1] == 'C_EXPR' then
				for i=2,#n_expr do
					table.insert(result, n_expr[i])
				end
			else
				table.insert(result, n_expr)
			end

			return result
		end

		-- reader.error('Expression Not implemented')
		return a
	end

	local function statement_local()
		local pos = reader.pos()
		reader.next()

		-- For all names defined after this
		local names = {}
		local result = { 'VAR', names; pos = pos }

		while true do
			if reader.type() == 'name' then
				names[#names + 1] = reader.value()
				reader.next()
				if reader.value() == '=' then
					reader.next()
					table.insert(result, expression(true))
					return result
				elseif reader.value() == ',' then
					reader.next()
					-- Continue
				else
					-- End of the statement
					return result
				end
			else
				reader.error('Invalid local expression')
			end
		end
	end

	local function statement_if()
		local pos = reader.pos()
		reader.next()
		local condition = expression(false)
		reader.require_value('then')
		local body = statement_list()
		local elseBody = nil
		if reader.value() == 'else' then
			reader.next()
			elseBody = statement_list()
		end
		reader.require_value('end')
		return { 'IF', condition, body, elseBody; pos = pos }
	end

	statement_list = function()
		local result = { 'LIST'; pos = reader.pos() }
		local idx = 0
		while reader.hasMore() do
			local nidx = reader.index()
			if idx == nidx then
				break
			end
			idx = nidx

			local pos = reader.pos()
			local r_value = reader.value()
			local r_type = reader.type()
			if r_value == 'local' then
				table.insert(result, statement_local())
			elseif r_value == 'if' then
				table.insert(result, statement_if())
			elseif r_type == 'name' then
				reader.next()
				if reader.value() == '=' then
					reader.next()
					table.insert(result, { 'SET', r_value, expression(false); pos = pos })
				elseif reader.value() == '(' then
					reader.next()
					local expr = expression(true)
					if expr[1] ~= 'C_EXPR' then
						expr = { 'C_EXPR', expr; pos = expr.pos }
					end
					table.insert(result, { 'CALL', r_value, expr; pos = pos })
					reader.require_value(')')
				else
					reader.error("Invalid symbol '%s'", r_value)
				end
			end
		end

		return result
	end

	local result = statement_list()
	if reader.hasMore() then
		reader.error('Did not parse correctly')
	end

	return result
end


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
-- @field debug_statistics boolean If the pipeline should add debug statistics


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
	local DEBUG_STATISTICS  = data.debug_statistics or false

local content = [[local __groups = { ['__output'] = {} } local __output = __groups['__output'] local __insert = function(text) for _, data in pairs(__groups) do table.insert(data, text) end end __insert('') if false then  __insert('local raster = {} ') else  __insert('local raster = {} local blit_buffer = {} ') end  __insert(' ') for _, name in pairs(LAYERS) do __insert('local layer_' .. name .. ' = {} ') __insert('local layer_' .. name .. '_write = 0 ') end __insert(' local layers = { ') for _, name in pairs(LAYERS) do __insert(' ' .. name .. ' = layer_' .. name .. ', ') end __insert('} local TRIANGLES = 0 local H = 1 local W = 1 local TEXTURE = nil local MISSING_TEXTURE = { w = 8, h = 8, data = { 0, 185, 0, 185, 0, 185, 0, 185, 185, 0, 185, 0, 185, 0, 185, 0, 0, 185, 0, 185, 0, 185, 0, 185, 185, 0, 185, 0, 185, 0, 185, 0, 0, 185, 0, 185, 0, 185, 0, 185, 185, 0, 185, 0, 185, 0, 185, 0, 0, 185, 0, 185, 0, 185, 0, 185, 185, 0, 185, 0, 185, 0, 185, 0, } } local NEAR = 0.01 local USE_FACE_CULLING = false ') local function get_va_attribute_name(attribute, index) local result = 'va_' .. attribute.name if attribute.count > 1 then result = result .. '_' .. ("xyzw"):sub(index, index) end return result end local function get_fa_attribute_name(attribute, index) local result = 'fa_' .. attribute.name if attribute.count > 1 then result = result .. '_' .. ("xyzw"):sub(index, index) end return result end local pos_attr = 'va_' .. POSITION_ATTRIBUTE.name .. '_' local function textindent(text, tabs) local lines = {} for s in string.gmatch(text .. " ", "(.-) ") do table.insert(lines, s) end local pad = '' for i=1,tabs do pad = pad .. ' ' end return pad .. table.concat(lines, ' ' .. pad):gsub(' [ ]+ ', ' ') end local function if_greater(variables, gt, callback, indent) indent = indent or 1 local function internal(state, index) if index <= #variables then state[index] = true local a = internal(state, index + 1) state[index] = false local b = internal(state, index + 1) if a ~= '' then local result = 'if ' .. variables[index] .. ' > ' .. gt .. ' then ' .. textindent(a, indent) if b ~= '' then result = result .. ' else ' .. textindent(b, indent) end return result .. ' end' elseif b ~= '' then return 'if ' .. variables[index] .. ' <= ' .. gt .. ' then ' .. textindent(b, indent) .. ' end' end return '' else return callback(state) end end local state = {} for i = 1, #variables do state[i] = false end return internal(state, 1) end local function if_sorted(variables, callback, indent) indent = indent or 1 local function permgen(a, n, states) if n == 0 then local clone = {} for i,v in pairs(a) do clone[i] = v end states[#states + 1] = clone else for i = 1, n, 1 do a[n], a[i] = a[i], a[n] permgen(a, n - 1, states) a[n], a[i] = a[i], a[n] end end end local function internal(matrix, perms) if #perms == 0 then return '' elseif #perms == 1 then local state = {} for i, v in pairs(perms[1]) do state[v] = i end return callback(state) end local a_elm = matrix[1] local a_idx = 1 for i=2,#variables do local match = matrix[i] if a_elm.count < match.count then a_elm = match a_idx = i end end local b_idx = nil for i=1,#variables do if a_elm[i] then b_idx = i break end end local s_t = {} local s_f = {} for _, v in pairs(perms) do if v[a_idx] < v[b_idx] then s_t[#s_t + 1] = v else s_f[#s_f + 1] = v end end matrix[a_idx][b_idx] = nil matrix[a_idx].count = matrix[a_idx].count - 1 local a = internal(matrix, s_t) local b = internal(matrix, s_f) matrix[a_idx][b_idx] = true matrix[a_idx].count = matrix[a_idx].count + 1 if a ~= '' then if b ~= '' then return 'if ' .. variables[a_idx] .. ' >= ' .. variables[b_idx] .. ' then ' .. textindent(a, indent) .. ' else ' .. textindent(b, indent) .. ' end'  end return a elseif b ~= '' then return b end return '' end local matrix = {} local a = {} for i=1,#variables do matrix[i] = {} matrix[i].count = #variables - i a[i] = i for j=i+1,#variables do matrix[i][j] = true end end local states = {} permgen(a, #variables, states) local perms = {} for i=1,#states do perms[i] = {} for j,v in pairs(states[i]) do perms[i][v] = j end end return internal(matrix, perms) end local function get_used_parameters_sort(allowed, keep_comma) allowed = allowed or {} keep_comma = keep_comma or false local lines = {} for _,v in pairs(VERTEX_ATTRIBUTES) do local fields = SHADER.used_vertex_attributes[v.name] or 0 if allowed['position'] and v.position then fields = (2 ^ v.count) - 1 end if fields > 0 then for index=1,v.count do if bit32.extract(fields, index - 1) == 1 then local element = get_va_attribute_name(v, index) lines[#lines + 1] = ', ' .. element .. '{1}, ' .. element .. '{2}, ' .. element .. '{3}' end end end end for _,v in pairs(FACE_ATTRIBUTES) do local fields = SHADER.used_face_attributes[v.name] or 0 if fields > 0 then for index=1,v.count do if bit32.extract(fields, index - 1) == 1 then local element = get_fa_attribute_name(v, index) lines[#lines + 1] = ', ' .. element end end end end local result = table.concat(lines, ' ') if not keep_comma then result = result:gsub('^(.-),( .*)', '%1 %2') end return result end local function get_used_parameters(allowed, keep_comma) return get_used_parameters_sort(allowed, keep_comma) :gsub('{1}', '1') :gsub('{2}', '2') :gsub('{3}', '3') end __insert(' local _math_clamp = function(x, min, max) if x < min then return min end if x > max then return max end return x end local function renderTriangleInternal( y_min, y_mid, y_max, x_min, x_mid, x_max, x_sta, x_end ') __insert(tostring( textindent(get_used_parameters(nil, true), 1) )) __insert(' ) local _math_floor = math.floor local _math_ceil  = math.ceil local _math_max   = math.max local _math_min   = math.min ') local ___full_function = {} __groups['___full_function'] = ___full_function __insert(' TRIANGLES = TRIANGLES + 1 ') if POSITION_ATTRIBUTE.count > 2 and #VERTEX_ATTRIBUTES > 1 then local use_z = false for _, v in pairs(VERTEX_ATTRIBUTES) do local fields = SHADER.used_vertex_attributes[v.name] or 0 if fields > 0 then use_z = true break end end if use_z then for i=1,3 do __insert(' ' .. pos_attr .. 'z' .. i .. ' = 1 / ' .. pos_attr .. 'z' .. i .. ' ') end end for _, v in pairs(VERTEX_ATTRIBUTES) do local fields = SHADER.used_vertex_attributes[v.name] or 0 if fields > 0 then if not v.position then for index=1,v.count do if bit32.extract(fields, index - 1) == 1 then for i=1,3 do local element = get_va_attribute_name(v, index) __insert(' ' .. element .. i .. ' = ' .. element .. i .. ' * ' .. pos_attr .. 'z' .. i .. ' ') end end end end __insert(' ') end end for _, v in pairs(VERTEX_ATTRIBUTES) do local fields = SHADER.used_vertex_attributes[v.name] or 0 if fields > 0 then for index=1,v.count do if bit32.extract(fields, index - 1) == 1 then for i=2,3 do local element = get_va_attribute_name(v, index) __insert(' local in_' .. element .. i .. ' = ' .. element .. i .. ' - ' .. element .. 1 .. ' ') end end end __insert(' ') end end end __insert('') if SHADER.uses_barycentric then  __insert(' local cyx = x_max - x_min local cyy = y_max - y_min local czx = x_mid - x_min local czy = y_mid - y_min local det = 1 / (czx * cyy - cyx * czy) cyx = cyx * det cyy = cyy * det czx = czx * det czy = czy * det ') end  __insert(' local tex = TEXTURE or MISSING_TEXTURE local tw = tex.w local th = tex.h local td = tex.data local y_d0 = y_mid - y_max local y_d1 = y_min - y_mid if y_d0 > 0 then local x13_s = (x_sta - x_max) / y_d0 local x23_s = (x_end - x_max) / y_d0 local dy0 = _math_ceil(y_max - 0.5) local dy1 = dy0 + (0.5 - y_max) y_d0     = _math_min(y_d0 - dy1, H - dy0) local ys = _math_max(0         , 1 - dy0) for yy=ys,y_d0 do local xs = (yy + dy1) * x13_s + x_max local xe = (yy + dy1) * x23_s + x_max local yb = yy + dy0 ') local ___triangle = {} __groups['___triangle'] = ___triangle __insert('') for name, _ in pairs(SHADER.used_layers) do __insert(' local layer_' .. name .. '_y = layer_' .. name .. '[yb] ') end __insert('') if SHADER.uses_barycentric then  __insert(' local yyy = yb - y_min + 0.5 local yya = yyy * cyx local yyb = yyy * czx ') end  __insert(' xs = _math_max(xs, 1) xe = _math_min(xe, W) xs = _math_ceil(xs - 0.5) xe = _math_ceil(xe - 0.5) - 1 for xx=xs,xe do ') if SHADER.uses_barycentric then  __insert(' local xxx = xx - x_min + 0.5 local l_a = xxx * cyy - yya local l_b = yyb - xxx * czy local depth = 1 / (') __insert(tostring(pos_attr)) __insert('z1 + in_') __insert(tostring(pos_attr)) __insert('z2 * l_a + in_') __insert(tostring(pos_attr)) __insert('z3 * l_b) ') end  __insert('') __insert(tostring( textindent(FRAG_SHADER, 4) )) __insert(' end ') __groups['___triangle'] = nil __insert(' end end if y_d1 > 0 then local x13_s = (x_min - x_sta) / y_d1 local x23_s = (x_min - x_end) / y_d1 local dy0 = _math_ceil(y_mid - 0.5) local dy1 = dy0 + (0.5 - y_mid) y_d1     = _math_min(y_d1 - dy1, H - dy0) local ys = _math_max(0         , 1 - dy0) for yy=ys,y_d1 do local xs = (yy + dy1) * x13_s + x_sta local xe = (yy + dy1) * x23_s + x_end local yb = yy + dy0 ') __insert(table.concat(___triangle, '')) __insert(' end end ') __groups['___full_function'] = nil __insert('end local function renderTriangle( ') __insert(tostring( textindent(get_used_parameters({ position = true }), 1) )) __insert(' ) local half_w = W * 0.5 local half_h = H * 0.5 local sx1 = half_w + (') __insert(tostring(pos_attr)) __insert('x1 * half_w) / ') __insert(tostring(pos_attr)) __insert('z1 local sx2 = half_w + (') __insert(tostring(pos_attr)) __insert('x2 * half_w) / ') __insert(tostring(pos_attr)) __insert('z2 local sx3 = half_w + (') __insert(tostring(pos_attr)) __insert('x3 * half_w) / ') __insert(tostring(pos_attr)) __insert('z3 local sy1 = half_h - (') __insert(tostring(pos_attr)) __insert('y1 * half_h) / ') __insert(tostring(pos_attr)) __insert('z1 local sy2 = half_h - (') __insert(tostring(pos_attr)) __insert('y2 * half_h) / ') __insert(tostring(pos_attr)) __insert('z2 local sy3 = half_h - (') __insert(tostring(pos_attr)) __insert('y3 * half_h) / ') __insert(tostring(pos_attr)) __insert('z3 if USE_FACE_CULLING and ((sx2 - sx1) * (sy3 - sy1) - (sx3 - sx1) * (sy2 - sy1)) > 0 then return end ') __insert(tostring( textindent(if_sorted({ 'sy1', 'sy2', 'sy3' }, function(state) local res = '' for i,v in pairs(state) do if i > 1 then res = res .. ',' end res = res .. v end local out = table.concat({ 'local x_sta = ((sx{1} - sx{3}) / (sy{1} - sy{3})) * (sy{2} - sy{1}) + sx{1}', 'local x_end = sx{2}', 'if x_sta > x_end then', '	x_sta, x_end = x_end, x_sta', 'end', 'renderTriangleInternal(', '	sy{1}, sy{2}, sy{3},', '	sx{1}, sx{2}, sx{3},', '	x_sta, x_end', textindent(get_used_parameters_sort(nil, true), 1), ')' }, ' ') out = out:gsub('{1}', tostring(state[1])) :gsub('{2}', tostring(state[2])) :gsub('{3}', tostring(state[3])) return out end), 1) )) __insert(' end function raster.drawGeometry(geometry, matrix) ') local face_size = 0 for _, v in pairs(VERTEX_ATTRIBUTES) do face_size = face_size + v.count * 3 end for _, v in pairs(FACE_ATTRIBUTES) do face_size = face_size + v.count end __insert(' for i=1,#geometry,') __insert(tostring(face_size)) __insert(' do ') local idx = 0 for _, v in pairs(VERTEX_ATTRIBUTES) do local fields = SHADER.used_vertex_attributes[v.name] or 0 if v.position then fields = 2 ^ v.count - 1 end if fields > 0 then for i=1,3 do for index=1,v.count do if bit32.extract(fields, index - 1) == 1 then local element = get_va_attribute_name(v, index) local pattern = ' local {t}{1} = geometry[i + ' .. (idx + index + (i - 1) * v.count - 1) .. '] ' __insert(pattern:gsub('{t}', element):gsub('{1}', i)) end end end __insert(' ') end idx = idx + v.count * 3 end for _, v in pairs(FACE_ATTRIBUTES) do local fields = SHADER.used_face_attributes[v.name] or 0 if fields > 0 then for index=1,v.count do if bit32.extract(fields, index - 1) == 1 then local element = get_fa_attribute_name(v, index) __insert(' local ' .. element .. ' = geometry[i + ' .. (idx + index - 1) .. ']' .. ' ') end end __insert(' ') end idx = idx + v.count end for _, v in pairs(VERTEX_ATTRIBUTES) do local fields = SHADER.used_vertex_attributes[v.name] or 0 if v.position then for i=1,3 do local pattern = 'matrix.m0{n} * {a} + matrix.m1{n} * {b} + matrix.m2{n} * {c} + matrix.m3{n}' local data_a = {} local data_b = {} for index=1,v.count do data_a[#data_a + 1] = get_va_attribute_name(v, index) .. i data_b[#data_b + 1] = pattern :gsub('{n}', index - 1) :gsub('{a}', get_va_attribute_name(v, 1) .. i) :gsub('{b}', get_va_attribute_name(v, 2) .. i) :gsub('{c}', get_va_attribute_name(v, 3) .. i) end __insert(' ' .. table.concat(data_a, ', ') .. ' ') __insert(' = ' .. table.concat(data_b, ' , ') .. ' ') end __insert(' ') end idx = idx + v.count * 3 end __insert('') __insert(tostring( textindent(if_greater({ pos_attr .. 'z1', pos_attr .. 'z2', pos_attr .. 'z3' }, 'NEAR', function(state) local function delta(t, use_a, use_b, use_c) local pattern = '({t}{1} - {t}{{v}}) * m{1}{{v}} + {t}{{v}}' local result = (use_a ~= nil and pattern:gsub('{v}', use_a) or '{t}{1}') .. ', ' .. (use_b ~= nil and pattern:gsub('{v}', use_b) or '{t}{2}') .. ', ' .. (use_c ~= nil and pattern:gsub('{v}', use_c) or '{t}{3}') return result:gsub('{t}', t) end local function delta_z(t, use_a, use_b, use_c) local result = (use_a ~= nil and 'NEAR' or '{t}{1}') .. ', ' .. (use_b ~= nil and 'NEAR' or '{t}{2}') .. ', ' .. (use_c ~= nil and 'NEAR' or '{t}{3}') return result:gsub('{t}', t) end local function get_variables(a, b, c) local lines = {} for _,v in pairs(VERTEX_ATTRIBUTES) do local fields = SHADER.used_vertex_attributes[v.name] or 0 if v.position then fields = 2 ^ v.count - 1 end if fields > 0 then for index=1,v.count do if bit32.extract(fields, index - 1) == 1 then local element = get_va_attribute_name(v, index) if v.position and index == 3 then lines[#lines + 1] = ', ' .. delta_z(element, a, b, c) else lines[#lines + 1] = ', ' .. delta(element, a, b, c) end end end end end for _,v in pairs(FACE_ATTRIBUTES) do local fields = SHADER.used_face_attributes[v.name] or 0 if fields > 0 then for index=1,v.count do if bit32.extract(fields, index - 1) == 1 then local element = get_fa_attribute_name(v, index) lines[#lines + 1] = ', ' .. element end end end end return table.concat(lines, ' '):gsub('^(.-),( .*)', '%1 %2') end local inside = 0 local i_idx = 0 local o_idx = 0 local desc = '' for i, v in ipairs(state) do if i > 1 then desc = desc .. ' ' end desc = desc .. (v and i or '.') inside = inside + (v and 1 or 0) if v then i_idx = i else o_idx = i end end if inside == 0 then return '' end local s_idx = 1 local out = '' if inside == 1 then out = table.concat({ 'local m{1}{2} = (NEAR - {p}z{2}) / ({p}z{1} - {p}z{2})', 'local m{1}{3} = (NEAR - {p}z{3}) / ({p}z{1} - {p}z{3})', 'renderTriangle(', textindent(get_variables(nil, 2, 3), 1), ')' }, ' ') s_idx = i_idx elseif inside == 2 then out = table.concat({ 'local m{1}{2} = (NEAR - {p}z{2}) / ({p}z{1} - {p}z{2})', 'local m{1}{3} = (NEAR - {p}z{3}) / ({p}z{1} - {p}z{3})', 'renderTriangle(', textindent(get_variables(2, nil, nil), 1), ')', 'renderTriangle(', textindent(get_variables(3, 2, nil), 1), ')' }, ' ') s_idx = o_idx else out = table.concat({ 'renderTriangle(', textindent(get_variables(nil, nil, nil), 1), ')' }, ' ') end return out:gsub('{1}', tostring(s_idx)) :gsub('{2}', tostring(1 + (s_idx + 0) % 3)) :gsub('{3}', tostring(1 + (s_idx + 1) % 3)) :gsub('{p}', pos_attr) end), 2) )) __insert(' end return raster end function raster.set_layer(name, value) local layer = layers[name] if layer == nil then return raster end for y=1,H do local row = layer[y] for x=1,W do row[x] = value end end return raster end function raster.get_layer(name) return layers[name] end function raster.set_size(width, height, blit) if blit == nil then blit = true end local OW, OH = W, H W = width * (blit and 2 or 1) H = height * (blit and 3 or 1) for y=OH,H do ') for _, name in pairs(LAYERS) do  __insert(' layer_') __insert(tostring(name)) __insert('[y] = nil ') end  __insert(' end for y=1,H do ') for _, name in pairs(LAYERS) do  __insert(' local layer_') __insert(tostring(name)) __insert('_row = layer_') __insert(tostring(name)) __insert('[y] if layer_') __insert(tostring(name)) __insert('_row == nil then layer_') __insert(tostring(name)) __insert('_row = {} layer_') __insert(tostring(name)) __insert('[y] = layer_') __insert(tostring(name)) __insert('_row end ') end  __insert(' for x=W,OW do ') for _, name in pairs(LAYERS) do  __insert(' layer_') __insert(tostring(name)) __insert('_row[x] = nil ') end  __insert(' end for x=1,W do ') for _, name in pairs(LAYERS) do  __insert(' layer_') __insert(tostring(name)) __insert('_row[x] = 0 ') end  __insert(' end end return raster end function raster.set_near(near) NEAR = near return raster end function raster.set_face_culling(enable) USE_FACE_CULLING = enable return raster end function raster.set_texture(texture) TEXTURE = texture return raster end local texel_bits = {} local texel_char = {} local ic = 0 for i=0,63 do local a = i local b = bit32.band(bit32.bnot(i), 63) if texel_bits[a] == nil and texel_bits[b] == nil then texel_bits[a] = ic texel_bits[b] = -ic texel_char[ic] = string.char(128 + ic) ic = ic + 1 end end local teletext_lookup = {} local EMPTY_TABLE = {} local function calculateTexelWithColor(x, y, layer) local y1 = layer[y    ] or EMPTY_TABLE local y2 = layer[y + 1] or EMPTY_TABLE local y3 = layer[y + 2] or EMPTY_TABLE local p1 = y1[x    ] or 0 local p2 = y1[x + 1] or 0 local p3 = y2[x    ] or 0 local p4 = y2[x + 1] or 0 local p5 = y3[x    ] or 0 local p6 = y3[x + 1] or 0 local freq = {} freq[p1] = 1 freq[p2] = (freq[p2] or 0) + 1 freq[p3] = (freq[p3] or 0) + 1 freq[p4] = (freq[p4] or 0) + 1 freq[p5] = (freq[p5] or 0) + 1 freq[p6] = (freq[p6] or 0) + 1 local A, A_C = p1, 0 local B, B_C = p1, 0 for color, count in pairs(freq) do if count > B_C then if count > A_C then B = A B_C = A_C A = color A_C = count else B = color B_C = count end end end if A == B then return A, A, \' \' end local mask = 0 if p1 == A then mask = mask +  1 end if p2 == A then mask = mask +  2 end if p3 == A then mask = mask +  4 end if p4 == A then mask = mask +  8 end if p5 == A then mask = mask + 16 end if p6 == A then mask = mask + 32 end local v = texel_bits[mask] if v < 0 then return B, A, texel_char[-v] else return A, B, texel_char[v] end end function raster.get_blit(layer) layer = layers[layer] local colors = { \'0\', \'1\', \'2\', \'3\', \'4\', \'5\', \'6\', \'7\', \'8\', \'9\', \'a\', \'b\', \'c\', \'d\', \'e\', \'f\' } for y=1,H do local prev = blit_buffer[y] if prev == nil then prev = { {}, {}, {} } blit_buffer[y] = prev end local row = prev[1] local fg = prev[2] local bg = prev[3] for i=W+1,#row do row[i] = nil fg[i] = nil bg[i] = nil end for x=1,W do local t_fg, t_bg, t_cc = calculateTexelWithColor(x * 2 - 1, y * 3 - 2, layer) t_bg = ((16 + (t_bg % 16)) % 16) + 1 t_fg = ((16 + (t_fg % 16)) % 16) + 1 row[x] = t_cc fg[x] = colors[t_fg] bg[x] = colors[t_bg] end end for i=H+1,#blit_buffer do blit_buffer[i] = nil end return blit_buffer end function raster.get_raster_info() local result = { fragment = { ') for _, name in pairs(LAYERS) do __insert(' ' .. name .. ' = layer_' .. name .. '_write, ') end __insert(' }, triangles = TRIANGLES } TRIANGLES = 0 ') for _, name in pairs(LAYERS) do __insert(' layer_' .. name .. '_write = 0 ') end __insert(' return result end return raster ') return table.concat(__output, '')]]

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

	for _, v in pairs(FACE_ATTRIBUTES) do
		if v.type ~= h3d.AttributeType.Default then
			error("Invalid face attribute '" .. v.name .. "', must be AttributeType.Default")
		end
	end

	if POSITION_ATTRIBUTE == nil then
		error("Pipeline does not define a position vertex attribute")
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

shader.frag_shader = shader.frag_shader:gsub('[\n\t ]+', ' ')

	--- @type H3DRaster
	local result = h3d_format.process(content, {
		VERTEX_ATTRIBUTES  = VERTEX_ATTRIBUTES,
		FACE_ATTRIBUTES    = FACE_ATTRIBUTES,
		LAYERS             = LAYERS,

		POSITION_ATTRIBUTE = POSITION_ATTRIBUTE,

		FRAG_SHADER = shader.frag_shader,
		SHADER = shader
	}, function(name, source)
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
	Default  = 0,
	Position = 1,
	Texture  = 2,
	Color    = 3,
}

--- @class H3DAttribute
--- @field name string The attribute name
--- @field count integer The number of components this attribute has
--- @field type integer The type of this attribute
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
		count = count,
		type = type or h3d.AttributeType.Default
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


h3d.matrix = h3d_matrix
return h3d
