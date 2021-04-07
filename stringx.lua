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

--(generate a map of whitespace byte values)
local _whitespace_bytes = {}
do
	local _whitespace = " \t\n\r"
	for i = 1, _whitespace:len() do
		_whitespace_bytes[_whitespace:byte(i)] = true
	end
end

--trim all whitespace off the head and tail of a string
--	specifically trims space, tab, newline, and carriage return characters
--	ignores form feeds, vertical tabs, and backspaces
--
--	only generates one string of garbage in the case there's actually space to trim
function stringx.trim(s)
	--cache
	local len = s:len()

	--we search for the head and tail of the string iteratively
	--we could fuse these loops, but two separate loops is a lot easier to follow
	--and branches less as well.
	local head = 0
	for i = 1, len do
		if not _whitespace_bytes[s:byte(i)] then
			head = i
			break
		end
	end

	local tail = 0
	for i = len, 1, -1 do
		if not _whitespace_bytes[s:byte(i)] then
			tail = i
			break
		end
	end

	--overlapping ranges means no content
	if head > tail then
		return ""
	end
	--limit ranges means no trim
	if head == 1 and tail == len then
		return s
	end

	--pull out the content
	return s:sub(head, tail)
end

function stringx.ltrim(s)
    if s == "" or s == string.rep(" ", s:len()) then return "" end

    local head = 1
    for i = 1, #s do
        local c = s:sub(i, i)
        if c ~= " " then
            head = i
            break
        end
    end
    return s:sub(head)

end

function stringx.rtrim(s)
    if s == "" or s == string.rep(" ", s:len()) then return "" end

	local tail = #s
	for i=#s, 1 do
        local c = s:sub(i, i)
        if c ~= " " then
            tail = i
            break
        end
	end
	return s:sub(1, tail)
end

function stringx.deindent(s, keep_trailing_empty)
	--detect windows or unix newlines
	local windows_newlines = s:find("\r\n", nil, true)
	local newline = windows_newlines and "\r\n" or "\n"
	--split along newlines
	local lines = stringx.split(s, newline)
	--detect and strip any leading blank lines
	local leading_newline = false
	while lines[1] == "" do
		leading_newline = true
		table.remove(lines, 1)
	end

	--nothing to do
	if #lines == 0 then
		return ""
	end

	--detect indent
	local _, _, indent = lines[1]:find("^([ \t]*)")
	local indent_len = indent and indent:len() or 0

	--not indented
	if indent_len == 0 then
		return table.concat(lines, newline)
	end

	--de-indent the lines
	local res = {}
	for _, line in ipairs(lines) do
		local line_start = line:sub(1, indent:len())
		local start_len = line_start:len()
		if
			line_start == indent
			or (
				start_len < indent_len
				and line_start == indent:sub(1, start_len)
			)
		then
			line = line:sub(start_len + 1)
		end
		table.insert(res, line)
	end

	--should
	if not keep_trailing_empty then
		if res[#res] == "" then
			table.remove(res)
		end
	end

	return table.concat(res, newline)
end

--alias
stringx.dedent = stringx.deindent

--apply a template to a string
--supports $template style values, given as a table or function
-- ie ("hello $name"):format({name = "tom"}) == "hello tom"
function stringx.apply_template(s, sub)
	local r = s:gsub("%$(%w+)", sub)
	return r
end

--check if a given string starts with another
--(without garbage)
function stringx.starts_with(s, prefix)
	for i = 1, #prefix do
		if s:byte(i) ~= prefix:byte(i) then
			return false
		end
	end
	return true
end

function stringx.ends_with(s, prefix)
	if prefix == "" then return true end

	if #prefix > #s then return false end

	for i = 0, #prefix-1 do
		if s:byte(#s-i) ~= prefix:byte(#prefix-i) then
			return false
		end
	end
	return true
end

return stringx
