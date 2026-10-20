property testing, SPToChange, spriteList, myMarker
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
end

on startMovie me
  set testing to 0
  if objectp(the world of gMulleGlobals) then
    set objId to getEnteredObject(the world of gMulleGlobals)
  else
    set objId to 0
  end if
  if objId then
    set tempObj to new(script("Object"))
    fromList(tempObj, objId)
    set stuffToSet to getAt(getSetWhenDone(tempObj, #UserStuff), 1)
    set MissionId to getAt(getSetWhenDone(tempObj, #missions), 1)
    set tempObj to 0
  else
    set testing to 1
    set partNeeded to 173
    set stuffToSet to #FerryTicket
    set MissionId to 5
  end if
  set partNeeded to 173
  sendSprite(115, #C_Standard)
  if not testing then
    if not (getUserProp(the user of gMulleGlobals, stuffToSet) = #NoProp) then
      set myMarker to "Done"
    else
      if findPart(the car of the user of gMulleGlobals, partNeeded) then
        if testing then
          set SPToChange to 18
        else
          set tempPart to getPart(the parts of gMulleGlobals, partNeeded)
          set snapPoint to getRequiredPoints(tempPart)
          if listp(snapPoint) then
            set snapPoint to getAt(snapPoint, 1)
            set SPToChange to getAt(getSnapInfo(the car of the user of gMulleGlobals, snapPoint, #layers), 1)
          end if
        end if
        setUserProp(the user of gMulleGlobals, stuffToSet)
        addCompletedMission(the user of gMulleGlobals, MissionId)
        set myMarker to "JustDoIt"
      else
        set myMarker to "CantDoIt"
      end if
    end if
    go(myMarker)
  end if
end

on kill me
  return 0
end
