property MapId, objects, MapImage, Topology

on new me
  set MapId to EMPTY
  set objects to []
  set MapImage to EMPTY
  set Topology to EMPTY
  return me
end

on kill me
  set objects to 0
  return 0
end

on getMapImage me
  return MapImage
end

on getObjects me
  return objects
end

on getTopology me
  return Topology
end

on toList me
  return [#MapId: MapId, #objects: objects, #MapImage: MapImage, #Topology: Topology]
end

on fromList me, theid
  set memberName to "Map" & string(theid) & "DB"
  if the number of member memberName = -1 then
    alert(memberName & " not found!")
    return 0
  end if
  set objectList to value(the text of member(memberName))
  set MapId to getaProp(objectList, #MapId)
  set objects to getaProp(objectList, #objects)
  set MapImage to getaProp(objectList, #MapImage)
  set Topology to getaProp(objectList, #Topology)
  return 1
end
