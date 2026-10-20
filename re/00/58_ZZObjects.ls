property maps

on new me
  set objects to []
  return me
end

on kill me
  set objects to 0
  return 0
end

on toList me
  return(objects)
end

on fromList me, objectList
  set objects to objectList
end

on loadObject me, object, ObjectId
  if not objectp(object) then
    alert("Not a object object!")
  end if
  if getPos(objects, ObjectId) = 0 then
    alert("Not a valid object id!")
  end if
  if fromList(object, ObjectId) then
    nothing()
  else
  end if
end
