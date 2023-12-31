local h3d_format_code = require 'h3d_format'

local MINIFY = false
local MINIFY_PRE_GEN = false

-- First load code of each required file
local function readfile(path)
	local h = fs.open(fs.combine(shell.dir(), path), 'r')
	if h == nil then
		error("Could not load file '" .. path .. "'")
	end
	local r = h.readAll()
	h.close()
	return r
end

local function applyPlua(text)
	-- Only keep lines that doesn't have lines
	local lines = {}
	for s in string.gmatch(text .. "\n", "(.-)\n") do
		if not s:find('%-%-') then
			table.insert(lines, s)
		end
	end
	return table.concat(lines, '\n')
end

local function reduceNT(text)
	-- Match '(\\[nt])+'
	return text
		:gsub('\\n', '§'):gsub('\\t', '§')
		:gsub('§+', ' ')
end


-- File contents
local h3d_raster = readfile('h3d_raster.plua')
local h3d_raster_definition = readfile('h3d_raster_definition.lua')
local h3d_matrix = readfile('h3d_matrix.lua')
local h3d_format = readfile('h3d_format.lua')
local vsl_format = readfile('vsl_format.lua')
local h3d = readfile('h3d.lua')

h3d_raster = applyPlua(h3d_raster)

local function apply(text)
	local lines = {}
	local removeStart = false
	for s in string.gmatch(text .. "\n", "(.-)\n") do
		if s:find('%-%-%$%$START_REMOVE') ~= nil then
			removeStart = true
		elseif s:find('%-%-%$%$END_REMOVE') ~= nil then
			removeStart = false
		elseif not removeStart then
			if s:find('%-%-%$%$H3D_SHADER_CODE') then
				if MINIFY then
					table.insert(lines, "\tshader.frag_shader = shader.frag_shader:gsub('[\\n\\t ]+', ' ')")
				end
			elseif s:find('%-%-%$%$H3D_RASTER_CODE') then
				-- Replace with text
				local code = h3d_format_code.pre_template(h3d_raster)
				if MINIFY_PRE_GEN then
					code = code:gsub('\n[ \t]+', '\n'):gsub('\n+', ' ')
				end
				if MINIFY then
					code = reduceNT(code)
				end
				table.insert(lines, '\tlocal content = [[' .. code .. ']]')
			elseif s:find('%-%-%$%$REMOVE') ~= nil then
				-- Don't add code
			else
				table.insert(lines, s)
			end
		end
	end
	return table.concat(lines, '\n')
end

local result = table.concat({
	MINIFY and '' or apply(h3d_raster_definition),
	apply(h3d_matrix),
	apply(h3d_format),
	apply(vsl_format),
	apply(h3d),
[[
h3d.matrix = h3d_matrix
return h3d
]]
}, '\n')


local annotationTypes = {
	-- h3d
	'H3DAttributeType',
	'H3DPipelineData',
	'H3DAttribute',
	'H3DGeometry',
	'H3DTexture',
	'H3DRaster',
	'H3DMatrix',

	-- vsl
	'VSLContext',
	'VSLOutput',
}
for _, value in ipairs(annotationTypes) do
	result = result:gsub(value .. '([^a-zA-Z])', value .. 'Dev%1')
end

local h = fs.open(fs.combine(shell.dir(), 'build/h3d.lua'), 'w')
h.write(result)
h.close()
