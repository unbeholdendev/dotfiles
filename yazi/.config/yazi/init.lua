require("zoxide"):setup {
  update_db = true,
}

local function stamp(time)
  time = math.floor(time or 0)
  if time == 0 then
    return "     -     "
  elseif os.date("%Y", time) == os.date("%Y") then
    return os.date("%m/%d %H:%M", time)
  else
    return os.date("%m/%d  %Y", time)
  end
end

function Linemode:full()
  local size = self._file:size()
  if size then
    size = ya.readable_size(size)
  else
    local folder = cx.active:history(self._file.url)
    size = folder and tostring(#folder.files) or ""
  end
  return string.format("%s %s %9s", stamp(self._file.cha.btime), stamp(self._file.cha.mtime), size)
end
