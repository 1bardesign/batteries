--[[
	pretty formatting and printing for nested data structures

	also able to be parsed by lua in _many_ cases, but _not all cases_, be careful!

	circular references and depth limit will cause the string to contain
	things that cannot be parsed.

	this isn't a full serialisation solution, it's for debugging and display to humans

	all exposed functions take a config table,
	defaults found (and can be modified) in pretty.default_config

		indent
			indentation to use for each line, or "" for single-line packed
			can be a number of spaces, boolean, or a string to use verbatim
		depth
			a limit on how deep to explore the table
		per_line
			how many fields to print per line
]]

local path = (...):gsub("pretty", "")
local table = require(path.."tablex") --shadow global table module

local pretty = {}

pretty.default_config = {
	indent = true,
	depth = math.huge,
	per_line = 1,
}

--indentation to use when `indent = true` is provided
pretty.default_indent = "\t"

--pretty-print something directly
function pretty.print(input, config)
	print(pretty.string(input, config))
end

--pretty-format something into a string
function pretty.string(input, config)
	return pretty._process(input, config)
end

--internal
--actual processing part
function pretty._process(input, config, processing_state)
	--if the input is not a table, or it has a tostring metamethod
	--then we can just use tostring directly
	local mt = getmetatable(input)
	if type(input) ~= "table" or mt and mt.__tostring then
		local s = tostring(input)
		--quote strings
		if type(input) == "string" then
			s = '"' .. s .. '"'
		end
		return s
	end

	--pull out config
	config = table.overlay({}, pretty.default_config, config or {})

	local per_line = config.per_line
	local depth = config.depth
	local indent = config.indent
	if type(indent) == "number" then
		indent = (" "):rep(indent)
	elseif type(indent) == "boolean" then
		indent = indent and pretty.default_indent or ""
	end

	--dependent vars
	local newline = indent == "" and "" or "\n"

	--init or collect processing state
	processing_state = processing_state or {
		circular_references = {i = 1},
		depth = 0,
	}

	processing_state.depth = processing_state.depth + 1
	if processing_state.depth > depth then
		processing_state.depth = processing_state.depth - 1
		return "{...}"
	end

	local circular_references = processing_state.circular_references
	local ref = circular_references[input]
	if ref then
		if not ref.string then
			ref.string = string.format("%%%d", circular_references.i)
			circular_references.i = circular_references.i + 1
		end
		return ref.string
	end
	ref = {}
	circular_references[input] = ref

	local function internal_value(v)
		v = pretty._process(v, config, processing_state)
		if indent ~= "" then
			v = v:gsub(newline, newline..indent)
		end
		return v
	end

	--otherwise, we'll build up a table representation of our data
	--collate into member chunks
	local chunks = {}
	--(tracking for already-seen elements from ipairs)
	local seen = {}
	--sequential part first
	--(in practice, pairs already does this, but the order isn't guaranteed)
	for i, v in ipairs(input) do
		seen[i] = true
		table.insert(chunks, internal_value(v))
	end
	--non sequential follows
	for k, v in table.spairs(input) do
		if not seen[k] then
			--encapsulate anything that's not a string
			--todo: also keywords and strings with spaces
			if type(k) ~= "string" then
				k = "[" .. tostring(k) .. "]"
			end
			table.insert(chunks, k .. " = " .. internal_value(v))
		end
	end

	--resolve number to newline skip after
	if per_line > 1 then
		local line_chunks = {}
		while #chunks > 0 do
			local break_next = false
			local line = {}
			for i = 1, per_line do
				if #chunks == 0 then
					break
				end
				local v = chunks[1]
				--tables split to own line
				if v:find("{") then
					--break line here
					break_next = true
					break
				else
					table.insert(line, table.remove(chunks, 1))
				end
			end
			if #line > 0 then
				table.insert(line_chunks, table.concat(line, ", "))
			end
			if break_next then
				table.insert(line_chunks, table.remove(chunks, 1))
			end
		end
		chunks = line_chunks
	end

	--drop depth
	processing_state.depth = processing_state.depth - 1

	--remove circular
	circular_references[input] = nil

	local multiline = #chunks > 1
	local separator = (indent == "" or not multiline) and ", " or ",\n"..indent

	local prelude = ref.string and (string.format(" <referenced as %s> ",ref.string)) or ""
	if multiline then
		return "{" .. prelude .. newline ..
			indent .. table.concat(chunks, separator) .. newline ..
		"}"
	end
	return "{" .. prelude .. table.concat(chunks, separator) .. "}"
end

return pretty
