local vsl_format = {}

local function quote(text)
	return '\'' .. text:gsub('[\\\'\"\n\t]', {
		['\\'] = '\\\\',
		['\''] = '\\\'',
		['\"'] = '\\\"',
		['\n'] = '\\n',
		['\t'] = '\\t'
	}) .. '\''
end


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


--- Process the vsl code and convert it into a shader
---
--- @param source string the vsl shader code
--- @param context table a table with data
--- @return table a table containing the output
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
		{ 'name', _get('[a-zA-Z][a-zA-Z0-9_]*') },
	}

	local tokens = tokenize(source, patterns)

	--[[
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
	local FACE_ATTRIBUTES    = context.face_attributes
	local VERTEX_ATTRIBUTES  = context.vertex_attributes
	local LAYERS             = context.layers

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

	local ast = vsl_format.parse(token_list(tokens))
	output.frag_shader = vsl_format.build_code(ast, {
		variable = function(ast_error, name)
			if name == 'gl_x' then
				return '__va_' .. POSITION_ATTRIBUTE.name .. '_x', 'va_' .. POSITION_ATTRIBUTE.name .. '_x'
			elseif name == 'gl_y' then
				return '__va_' .. POSITION_ATTRIBUTE.name .. '_y', 'va_' .. POSITION_ATTRIBUTE.name .. '_y'
			elseif name == 'gl_z' then
				return '__va_' .. POSITION_ATTRIBUTE.name .. '_z', 'va_' .. POSITION_ATTRIBUTE.name .. '_z'
			elseif name == 'gl_depth' then
				return '__va', 'depth'
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
				end

				if attribute.count > 1 and #args ~= 2 then
					ast_error("Built in 'gl_face' requires 2 parameters")
				elseif #args ~= 1 then
					ast_error("Built in 'gl_face' only has 1 parameter")
				end

				local suffix = ''
				local used = output.used_face_attributes[data] or 0
				if attribute.count > 1 then
					local idx = tonumber(args[2]) + 1
					suffix = '_' .. (("xyzw"):sub(idx, idx))
					output.used_face_attributes[data] = bit32.bor(used, 2 ^ (idx - 1))
				else
					output.used_face_attributes[data] = bit32.bor(used, 1)
				end

				return nil, '_' .. attribute.name .. suffix
			end,

			gl_vertex = function(ast_error, args)
				if not args[1]:match("^'") then
					ast_error("Expected string parameter")
				end

				local data = args[1]:sub(2, #args[1] - 1)
				local attribute = find_vertex_attribute(data)
				if attribute == nil then
					ast_error("Could not find vertex attribute '" .. data .. "'")
				end

				local suffix = ''
				local used = output.used_vertex_attributes[data] or 0
				if attribute.count > 1 then
					local idx = tonumber(args[2]) + 1
					suffix = '_' .. (("xyzw"):sub(idx, idx))
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
				return nil, 'layer_' .. data .. '_y[xx] = ' .. args[2] .. '\nlayer_' .. data .. '_write = layer_' .. data .. '_write + 1'
			end,

			gl_rgb = function(ast_error, args)
				local result = (
					'(_math_floor(_math_clamp({1} * 6, 0, 5.999))) + ' ..
					'(_math_floor(_math_clamp({2} * 6, 0, 5.999)) * 6) + ' ..
					'(_math_floor(_math_clamp({3} * 6, 0, 5.999)) * 36)'
				):gsub('{1}', args[1]):gsub('{2}', args[2]):gsub('{3}', args[3])
				return nil, result
			end,

			gl_tex = function(ast_error, args)
				local idx = '_math_clamp(_math_floor({x} * tw), 0, tw - 1) + (_math_clamp(_math_floor({y} * th), 0, th - 1) * tw) + 1'
				idx = idx
					:gsub('{x}', args[1])
					:gsub('{y}', args[2])
				return nil, 'td[' .. idx .. ']'
			end
		},
		format_data = function(data)
			local lines = {}
			local has_bary = false
			for name, _ in pairs(data) do
				if name:match('^__va') then
					has_bary = true
					if #name > 4 then
						lines[#lines + 1] = 'local ' .. name:sub(3) .. ' = depth * ' ..
							('({t}1 * c_x + {t}2 * c_y + {t}3 * c_z)'):gsub('{t}', name:sub(5))
					end
				end
			end

			output.uses_barycentric = has_bary

			if has_bary then
				for idx, line in pairs({
					'local xxx = xx - x_min + 0.5',
					'local c_y = (xxx * cyy - yyy * cyx) * det',
					'local c_z = (yyy * czx - xxx * czy) * det',
					'local c_x = 1.0 - c_y - c_z',
					'local depth = 1 / ({t}z1 * c_x + {t}z2 * c_y + {t}z3 * c_z)\n'
				}) do
					line = line:gsub('{t}', '_' .. POSITION_ATTRIBUTE.name .. '_')
					table.insert(lines, idx, line)
				end
			end

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

			-- print(ast[2], data, value)

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
			indent(format_statements(ast[3]), 1),
			'end'
		}
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
		elseif r_type == 'str' or r_type == 'num' then -- Stop
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
			end

			local result = { 'C_EXPR', a; pos = a.pos }
			if n_expr[1] == 'C_EXPR' then
				for i=2,#n_expr do
					result[#result + 1] = n_expr[i]
				end
			else
				result[#result + 1] = n_expr
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
		reader.require_value('end')
		return { 'IF', condition, body; pos = pos }
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
				-- Only assignements or calls are allowed

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

return vsl_format
