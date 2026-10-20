property MissionId, type, image, sound

on new me
  set MissionId to EMPTY
  set type to EMPTY
  set image to EMPTY
  set sound to EMPTY
  return me
end

on kill me
  return 0
end

on getMissionId me
  return MissionId
end

on getType me
  return type
end

on getimage me
  return image
end

on getSound me
  return sound
end

on toList me
  return [#MissionId: MissionId, #type: type, #image: image, #sound: sound]
end

on fromList me, theid
  set memberName to "Mission" & string(theid) & "DB"
  if the number of member memberName = -1 then
    alert(memberName & " not found!")
    return 0
  end if
  set objectList to value(the text of member(memberName))
  set MissionId to getaProp(objectList, #MissionId)
  set type to getaProp(objectList, #type)
  set image to getaProp(objectList, #image)
  set sound to getaProp(objectList, #sound)
  return 1
end
