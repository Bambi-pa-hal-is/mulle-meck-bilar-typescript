property child, insideOuter, insideInner, sndId, enterOK
global gDir, gMulleGlobals, gSound

on new me, theChild
  set child to theChild
  set insideInner to 0
  set enterOK to 1
  return me
end

on kill me
  set child to 0
  return 0
end

on init me
  set listLen to 0
end

on step me, carLoc
  if enterOK then
    set temp to checkRadius(the drivingHandlers of gDir, me, carLoc, the myLoc of child, #Outer)
    if temp = #enterOuterRadius then
      enterOuterRadius(me)
    end if
  end if
end

on enterOuterRadius me
  set enterOK to 0
  set medalId to getAt(getSetWhenDone(child, #medals), 1)
  if not getMedal(the car of the user of gMulleGlobals, medalId) then
    sendSprite(getProp(the spriteList of gDir, #medal), #Blink, medalId)
    addMedal(the car of the user of gMulleGlobals, medalId)
  end if
end
