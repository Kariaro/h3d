local h3d_format = {}

-- TODO: Create a system that gives accurate line / column errors for 'code_pre' and 'code_gen'

--- Format an input source code
---
--- @param source      string     the input source code
--- @param environment table      custom environment table
--- @param callback    function?  callback function for pre and gen stages
---
--- @return any parsed the parsed output of the input source
function h3d_format.process(source, environment, callback)
	local function quote(text)
		return '\'' .. text:gsub('[\\\'\"\n\t]', { ['\\'] = '\\\\', ['\''] = '\\\'', ['\"'] = '\\\"', ['\n'] = '\\n', ['\t'] = '\\t' }) .. '\''
	end

	source = source:gsub('${([^}]+)}', '{!%1!}')

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

	if callback then
		callback('code_pre', source)
	end

	local env = {}
	env._G = env
	env._VERSION = _VERSION
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
			print('  ' .. (...))
		end)
	else
		print('Failed to load generated code: ' .. err)
	end
	return code()
end

return h3d_format
