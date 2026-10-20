property partList, currentlyAvailable

on new me
  set partList to [:]
  return me
end

on kill me
  set partList to 0
  return 0
end

on getCurrentlyAvailable me, theCategory
  return getaProp(currentlyAvailable, theCategory)
end

on calcCurrentlyAvailable me, theCategory
  global gMulleGlobals
  if voidp(theCategory) then
    repeat with n = 1 to count(partList)
      set category to getAt(partList, n)
      set availList to []
      repeat with partId in category
        if findPart(the user of gMulleGlobals, partId) = 0 then
          add(availList, partId)
        end if
      end repeat
      setAt(currentlyAvailable, n, duplicate(availList))
    end repeat
  else
    set category to getaProp(partList, theCategory)
    if listp(category) then
      set availList to []
      repeat with partId in category
        if findPart(the user of gMulleGlobals, partId) = 0 then
          add(availList, partId)
        end if
      end repeat
      setProp(currentlyAvailable, theCategory, duplicate(availList))
    end if
  end if
end

on getParts me, theCategory
  if voidp(theCategory) then
    return partList
  end if
  return getaProp(partList, theCategory)
end

on toList me
  return partList
end

on fromList me, objectList
  set partList to objectList
  set currentlyAvailable to [#Postal: [], #JunkMan: [], #Destinations: [], #random: []]
  if voidp(partList) then
    set partList to duplicate(currentlyAvailable)
  else
    if count(partList) = 0 then
      set partList to duplicate(currentlyAvailable)
    end if
  end if
end
