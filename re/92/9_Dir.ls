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
    set cacheToSet to getAt(getSetWhenDone(tempObj, #Cache), 1)
    set stuffNeeded to getAt(getCheckFor(tempObj, #Cache), 1)
    set mission to getAt(getSetWhenDone(tempObj, #missions), 1)
    set tempObj to 0
  else
    set testing to 1
    set cacheToSet to #ExtraTank
    set stuffNeeded to #Dog
    set mission to 1
  end if
  set myMarker to the frame
  if not testing then
    if not (getCacheProp(the car of the user of gMulleGlobals, stuffNeeded) = #NoProp) then
      set myMarker to "JustDoIt"
      addCompletedMission(the user of gMulleGlobals, mission)
      deleteCacheProp(the car of the user of gMulleGlobals, stuffNeeded)
      setCacheProp(the car of the user of gMulleGlobals, cacheToSet, 20)
      set maxFuel to 120 * getProperty(the car of the user of gMulleGlobals, #FuelVolume) / 100
      setProp(the drivingInfo of the user of gMulleGlobals, #fuel, #Full)
    else
      if isMissionCompleted(the user of gMulleGlobals, mission) then
        set myMarker to "Done"
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
