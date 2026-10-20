property testing, partToGive, myMarker, spriteList
global gMulleGlobals

on new me
  set myMarker to "JustDoIt"
  set spriteList to [#CarStart: 35]
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
    set cacheToCheck to getAt(getCheckFor(tempObj, #Cache), 1)
    set partToGive to getAt(getSetWhenDone(tempObj, #parts), 1)
    set mission to getAt(getSetWhenDone(tempObj, #missions), 1)
    set tempObj to 0
  else
    set testing to 1
    set cacheToCheck to #Lemonade
    set partToGive to 121
    set mission to 3
  end if
  set myMarker to the frame
  if not testing then
    if isMissionCompleted(the user of gMulleGlobals, mission) or not (findPart(the user of gMulleGlobals, partToGive) = 0) then
      set myMarker to "Done"
    else
      if not (getCacheProp(the car of the user of gMulleGlobals, cacheToCheck) = #NoProp) then
        addJunkPart(the user of gMulleGlobals, #yard, partToGive)
        addCompletedMission(the user of gMulleGlobals, mission)
        set myMarker to "JustDoIt"
      else
        set myMarker to "CantDoIt"
        set the member of sprite 1 to member("88b002v0")
      end if
    end if
  end if
end

on startMovie me
  sendSprite(115, #C_Standard)
  go(myMarker)
end

on getPartToGive me
  return partToGive
end

on kill me
  return 0
end
