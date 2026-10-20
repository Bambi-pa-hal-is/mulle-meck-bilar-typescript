property testing, myFrame, partToGive, myMarker
global gMulleGlobals

on new me
  set myMarker to "JustDoIt"
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
    set cacheToSet to getAt(getSetWhenDone(tempObj, #Cache), 1)
    set cacheToSetJustDo to getAt(getSetWhenDone(tempObj, #Cache), 2)
    set tempObj to 0
  else
    set testing to 1
    set cacheToSet to #MudCar
    set cacheToSetJustDo to #RescuedMudCar
    set partToGive to 126
  end if
  setCacheProp(the car of the user of gMulleGlobals, cacheToSet)
  set myMarker to the frame
  if not testing then
    if getProperty(the car of the user of gMulleGlobals, #Strength) > 4 then
      addJunkPart(the user of gMulleGlobals, #yard, partToGive)
      setCacheProp(the car of the user of gMulleGlobals, cacheToSetJustDo)
      set myMarker to "JustDoIt"
    else
      set myMarker to "CantDoIt"
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
