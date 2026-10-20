property partList

on new me
  set partList to [:]
  return me
end

on kill me
  set partList to 0
  set snapInfo to 0
  return 0
end

on addPart me, part
  addProp(partList, getId(part), part)
end

on deletePart me, partId
  deleteProp(partList, partId)
end

on getPart me, partId
  set part to getaProp(partList, partId)
  if objectp(part) then
    return part
  end if
  return 0
  repeat with part in partList
    if getId(part) = partId then
      return part
      exit repeat
    end if
  end repeat
  return 0
end

on toList me
  set result to []
  repeat with part in partList
    add(result, toList(part))
  end repeat
  return result
end

on fromList me, objectList
  set partList to [:]
  repeat with l in objectList
    set newPart to new(script("Part"))
    if fromList(newPart, l) then
      addPart(me, newPart)
      next repeat
    end if
  end repeat
end
