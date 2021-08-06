--
-- utils.lua
--

local function len(value)
  return #value
end

local function slice(tbl, first, last)
  if type(tbl) == 'string' then
    return string.sub(tbl, first, last)
  end

  if first < 0 then
    first = #tbl + 1 + first
  end

  if last ~= nil and last < 0 then
    last = #tbl + 1 + last
  end

  local sliced = {}

  for i = first or 1, last or #tbl do
    sliced[#sliced+1] = tbl[i]
  end

  return sliced
end

local function slice_right(tbl, length)
  local current_length = #tbl

  if current_length <= length then
    return tbl
  end

  local diff = current_length - length
  local last = #tbl + 1
  local first = last - diff

  if type(tbl) == 'string' then
    return string.sub(tbl, first, last)
  end

  local sliced = {}

  for i = first, last do
    sliced[#sliced+1] = tbl[i]
  end

  return sliced
end

local function word_pattern(p)
  return '%f[%w]' .. p .. '%f[^%w]'
end

return {
  len = len,
  slice = slice,
  slice_right = slice_right,
  word_pattern = word_pattern,
}
