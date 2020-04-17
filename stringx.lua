--[[
	extra string routines
]]

local stringx = setmetatable({}, {
	__index = string
})

--split a string on a delimiter into an ordered table
function stringx:split(delim)
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
--todo: multi-line for big tables
--todo: support self-referential tables at least without crashing :)
function stringx.pretty(input)
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

	--otherwise, we've got to build up a table representation
	--collate into member chunks
	local chunks = {}
	--(tracking for already-seen elements from ipairs)
	local seen = {}
	--sequential part first
	--(in practice, pairs already does this, but the order isn't guaranteed)
	for i, v in ipairs(input) do
		seen[i] = true
		table.insert(chunks, stringx.pretty(v))
	end
	--non sequential follows
	for k, v in pairs(input) do
		if not seen[k] then
			--encapsulate anything that's not a string
			--todo: also keywords
			if type(k) ~= "string" then
				k = "[" .. tostring(k) .. "]"
			end
			table.insert(chunks, k .. " = " .. stringx.pretty(v))
		end
	end
	return "{" .. table.concat(chunks, ", ") .. "}"
end

return stringx
