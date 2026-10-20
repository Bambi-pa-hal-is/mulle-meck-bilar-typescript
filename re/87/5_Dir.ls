property testing, myMarker, spriteList
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
    set stuffToSet to getAt(getSetWhenDone(tempObj, #Cache), 1)
    set partNeeded to getAt(getCheckFor(tempObj, #parts), 1)
    set mission to getAt(getCheckFor(tempObj, #missions), 1)
    set tempObj to 0
  else
    set testing to 1
    set partNeeded to 172
    set stuffToSet to #Lemonade
    set mission to 1
  end if
  set myMarker to the frame
  if not testing then
    if not (getCacheProp(the car of the user of gMulleGlobals, stuffToSet) = #NoProp) or isMissionCompleted(the user of gMulleGlobals, mission) then
      set myMarker to "Done"
    else
      if findPart(the car of the user of gMulleGlobals, partNeeded) then
        setCacheProp(the car of the user of gMulleGlobals, stuffToSet)
        set myMarker to "JustDoIt"
      else
        set myMarker to "CantDoIt"
      end if
    end if
  end if
end

on startMovie me
  sendSprite(115, #C_Standard)
  go(myMarker)
end

on kill me
  return 0
end
