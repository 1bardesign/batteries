--[[
	extra string routines
]]

local path = (...):gsub("stringx", "")
local assert = require(path .. "assert")
local pretty = require(path .. "pretty")

local stringx = setmetatable({}, {
	__index = string
})

--split a string on a delimiter into an ordered table
function stringx.split(self, delim, limit)
	delim = delim or ""
	limit = (limit ~= nil and limit) or math.huge

	assert:type(self, "string", "stringx.split - self", 1)
	assert:type(delim, "string", "stringx.split - delim", 1)
	assert:type(limit, "number", "stringx.split - limit", 1)

	if limit then
		assert(limit >= 0, "max_split must be positive!")
	end

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
				if #res < limit then
					table.insert(res, i)
				else
					break
				end
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

stringx.pretty = pretty.string

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

--trim the start of a string
function stringx.ltrim(s)
	local head = 1
	for i = 1, #s do
		if not _whitespace_bytes[s:byte(i)] then
			head = i
			break
		end
	end
	if head == 1 then
		return s
	end
	return s:sub(head)
end

--trim the end of a string
function stringx.rtrim(s)
	local tail = #s

	for i = #s, 1, -1 do
		if not _whitespace_bytes[s:byte(i)] then
			tail = i
			break
		end
	end

	if tail == #s then
		return s
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
	while lines[1] == "" do
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
		if line ~= "" then
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
		end
		table.insert(res, line)
	end

	--should we keep any trailing empty lines?
	if not keep_trailing_empty then
		while res[#res] == "" do
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
	local r = s:gsub("%$([%w_]+)", sub)
	return r
end

--check if a given string contains another
--(without garbage)
function stringx.contains(haystack, needle)
	for i = 1, #haystack - #needle + 1 do
		local found = true
		for j = 1, #needle do
			if haystack:byte(i + j - 1) ~= needle:byte(j) then
				found = false
				break
			end
		end
		if found then
			return true
		end
	end
	return false
end

--check if a given string starts with another
--(without garbage)
--Using loops is actually faster than string.find!
function stringx.starts_with(s, prefix)
	for i = 1, #prefix do
		if s:byte(i) ~= prefix:byte(i) then
			return false
		end
	end
	return true
end

--check if a given string ends with another
--(without garbage)
function stringx.ends_with(s, suffix)
	local len = #s
	local suffix_len = #suffix
	for i = 0, suffix_len - 1 do
		if s:byte(len - i) ~= suffix:byte(suffix_len - i) then
			return false
		end
	end
	return true
end

return stringx
