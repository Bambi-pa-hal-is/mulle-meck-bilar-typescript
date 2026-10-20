property child, SP, insideInner
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
  set the member of sprite the SPUnder of child to member(getAt(getFrameList(child), 1))
  set the loc of sprite the SPUnder of child to the myLoc of child
end

on step me, carLoc
  set temp to checkRadius(the drivingHandlers of gDir, me, carLoc, the myLoc of child, #Inner)
  if temp = #EnterInnerRadius then
    EnterInnerRadius(me)
  end if
end

on EnterInnerRadius me
  setSpeed(the carDriving of gDir, 0)
  stepback(the carDriving of gDir, 2)
end
