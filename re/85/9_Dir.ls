property testing, spriteList
global gMulleGlobals

on new me
  set spriteList to [#CarStart: 20]
  set tempCar to new(script("DrawCar"), 1)
  drawCar(tempCar, getProp(spriteList, #CarStart))
  set tempCar to 0
  return me
end

on init me
  set testing to 0
  if objectp(the world of gMulleGlobals) then
    set objId to getEnteredObject(the world of gMulleGlobals)
  else
    set objId to 0
  end if
  if objId then
    set tempObj to new(script("Object"))
    fromList(tempObj, objId)
    set cacheToSet to getSetWhenDone(tempObj, #Cache)
    set tempObj to 0
  else
    set testing to 1
    set cacheToSet to #Dog
  end if
  if not testing then
    repeat with index in cacheToSet
      setCacheProp(the car of the user of gMulleGlobals, index)
    end repeat
  end if
end

on startMovie me
  sendSprite(115, #C_Standard)
end

on kill me
  return 0
end
