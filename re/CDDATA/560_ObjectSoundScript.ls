property child, insideInner, mySound, doneIt
global gDir, gMulleGlobals, gSound

on new me, theChild
  set child to theChild
  return me
end

on kill me
  set child to 0
  return 0
end

on init me
  set mySound to getaProp(getOptionalData(child), #sound)
  if voidp(mySound) then
    set mySound to EMPTY
  end if
  set doneIt to 0
end

on step me, carLoc
  set temp to checkRadius(the drivingHandlers of gDir, me, carLoc, the myLoc of child, #Inner)
  if temp = #EnterInnerRadius then
    EnterInnerRadius(me)
  end if
end

on EnterInnerRadius me
  if not doneIt then
    set doneIt to 1
    play(gSound, mySound, #EFFECT)
  end if
end
