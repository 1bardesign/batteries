--[[
	extra string routines
]]

local path = (...):gsub(".stringx", ".")
local assert = require(path .. "assert")

local stringx = setmetatable({}, {
	__index = string
})

--split a string on a delimiter into an ordered table
function stringx.split(self, delim)
	assert:type(self, "string", "stringx.split - self", 1)
	assert:type(delim, "string", "stringx.split - delim", 1)

	--we try to create as little garbage as possible!
	--only one table to contain the result, plus the split strings.
	--so we do two passes, and  work with the bytes underlying the string
	--partly because string.find is not compiled on older luajit :)
	local res = {}
	local length = self:len()
	--
	local delim_length = delim:len()
	--empty delim? split to individual characters
	if delim_length == 0 then
		for i = 1, length do
			table.insert(res, self:sub(i, i))
		end
		return res
	end
	local delim_start = delim:byte(1)
	--pass 1
	--collect split sites
	local i = 1
	while i <= length do
		--scan for delimiter
		if self:byte(i) == delim_start then
			local has_whole_delim = true
			for j = 2, delim_length do
				if self:byte(i + j - 1) ~= delim:byte(j) then
					has_whole_delim = false
					break
				end
			end
			if has_whole_delim then
				table.insert(res, i)
			end
			--iterate forward
			i = i + delim_length
		else
			--iterate forward
			i = i + 1
		end
	end
	--pass 2
	--collect substrings
	i = 1
	for si, j in ipairs(res) do
		res[si] = self:sub(i, j-1)
		i = j + delim_length
	end
	--add the final section
	table.insert(res, self:sub(i, -1))
	--return the collection
	return res
end


--turn input into a vaguely easy to read string
--(which is also able to be parsed by lua in many cases)
--todo: support cyclic references without crashing :)
function stringx.pretty(input, indent, after)
	--if the input is not a table, or it has a tostring metamethod
	--then we can just use tostring
	local mt = getmetatable(input)
	if type(input) ~= "table" or mt and mt.__tostring then
		local s = tostring(input)
		--quote strings
		if type(input) == "string" then
			s = '"' .. s .. '"'
		end
		return s
	end

	--resolve indentation requirements
	indent = indent or ""
	if type(indent) == "number" then
		indent = (" "):rep(indent)
	end

	local newline = indent == "" and "" or "\n"

	local function internal_value(v)
		v = stringx.pretty(v, indent, after)
		if indent ~= "" then
			v = v:gsub(newline, newline..indent)
		end
		return v
	end

	--otherwise, we've got to build up a table representation
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
	for k, v in pairs(input) do
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
	after = after or 1
	if after and after > 1 then
		local line_chunks = {}
		while #chunks > 0 do
			local break_next = false
			local line = {}
			for i = 1, after do
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
				break_next = false
			end
		end
		chunks = line_chunks
	end

	local multiline = #chunks > 1
	local separator = (indent == "" or not multiline) and ", " or ",\n"..indent

	if multiline then
		return "{" .. newline ..
			indent .. table.concat(chunks, separator) .. newline ..
		"}"
	end
	return "{" .. table.concat(chunks, separator) .. "}"
end

return stringx
