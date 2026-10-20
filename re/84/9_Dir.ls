property testing, partToGive, spriteList
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
    set partToGive to getOnePart(tempObj, #setWhenDone)
    set stuffToSet to getAt(getSetWhenDone(tempObj, #Cache), 1)
    set tempObj to 0
  else
    set testing to 1
    set partToGive to 126
    set stuffToSet to #RoadThing1
  end if
  if not testing then
    addJunkPart(the user of gMulleGlobals, #yard, partToGive)
    setCacheProp(the car of the user of gMulleGlobals, stuffToSet)
  end if
end

on getPartToGive me
  return partToGive
end

on startMovie me
  sendSprite(115, #C_Standard)
end

on kill me
  return 0
end
