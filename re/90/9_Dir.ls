property testing, myFrame, partToGive, myMarker, spriteList
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
    set partToGive to getOnePart(tempObj, #setWhenDone)
    set MissionId to getAt(getSetWhenDone(tempObj, #missions), 1)
    set tempObj to 0
  else
    set testing to 1
    set MissionId to 4
    set partToGive to 126
  end if
  addCompletedMission(the user of gMulleGlobals, MissionId)
  set myMarker to the frame
  if not testing then
    if partToGive then
      addJunkPart(the user of gMulleGlobals, #yard, partToGive)
      set myMarker to "JustDoIt"
    else
      set myMarker to "Done"
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
