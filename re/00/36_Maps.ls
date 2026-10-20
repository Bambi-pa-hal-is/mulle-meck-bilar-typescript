property maps

on new me
  set maps to []
  return me
end

on kill me
  set maps to 0
  return 0
end

on loadMap me, map, MapId
  if not objectp(map) then
    return #InvalidObject
  end if
  if getPos(maps, MapId) = 0 then
    return #InvalidId
  end if
  if fromList(map, MapId) then
    return 0
  else
    return #InvalidMember
  end if
end

on toList me
  return maps
end

on fromList me, objectList
  set maps to objectList
end
