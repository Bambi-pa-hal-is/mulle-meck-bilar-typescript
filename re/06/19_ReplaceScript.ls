property SP, screenObjects
global gDir, gSound

on new me
  play(gSound, "06d004v0", #EFFECT)
  set SP to getProp(the spriteList of gDir, #Dialogue)
  set the member of sprite SP to member("06b015v0")
  set midPoint to point(528, 437)
  set the loc of sprite SP to midPoint
  set screenObjects to []
  set tempDiff to midPoint - point(528, 437)
  set tempObj to new(script("ScreenObject"), me, rect(469, 433, 524, 464), EMPTY, point(0, 0))
  addScreenObject(gDir, tempObj)
  add(screenObjects, tempObj)
  moveRegLoc(tempObj, tempDiff)
  set tempObj to new(script("ScreenObject"), me, rect(530, 432, 585, 463), EMPTY, point(0, 0))
  addScreenObject(gDir, tempObj)
  add(screenObjects, tempObj)
  moveRegLoc(tempObj, tempDiff)
  return me
end

on report me, theObject, what
  if what = #clicked then
    set tempPos to getPos(screenObjects, theObject)
    kill(me)
    if tempPos = 1 then
      prepareEnterName(gDir)
    end if
  end if
end

on kill me
  set the member of sprite SP to member("Dummy")
  if listp(screenObjects) then
    repeat with index in screenObjects
      deleteScreenObject(gDir, index)
    end repeat
    set screenObjects to 0
  end if
  return 0
end
