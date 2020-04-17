--[[
	extra string routines
]]

local stringx = setmetatable({}, {
	__index = string
})

--split a string on a delimiter into an ordered table
function stringx:split(delim)
	--try to create as little garbage as possible!
	--one table to contain the result, plus the split strings should be all we need
	--as such we work with the bytes underlying the string, as string.find is not compiled on older luajit :)
	local length = self:len()
	--
	local delim_length = delim:len()
	local delim_start = delim:byte(1)
	--iterate through and collect split sites
	local res = {}
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
	--re-iterate, collecting substrings
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

return stringx
