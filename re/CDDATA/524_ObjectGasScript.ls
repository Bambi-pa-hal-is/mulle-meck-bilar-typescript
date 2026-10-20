property child, counter, insideInner, sndId, OKToEnter
global gDir, gSound

on new me, theChild
  set child to theChild
  set insideInner to 0
  return me
end

on kill me
  set child to 0
  return 0
end

on init me
  set sndId to 0
  if getProp(the quickCarProps of the carDriving of gDir, #FuelConsumption) > 0 or the gotElectricEngine of the carDriving of gDir then
    set OKToEnter to 1
  else
    set OKToEnter to 0
  end if
  set tempShow to getaProp(the optionalData of child, #show)
  if not voidp(tempShow) then
  end if
end

on step me, carLoc
  if sndId then
    if finished(gSound, sndId) then
      set sndId to 0
      programControl(the carDriving of gDir, 0)
    end if
  else
    set tempDiff to carLoc - the myLoc of child
    set tempH to getAt(tempDiff, 1)
    set tempV to getAt(tempDiff, 2)
    set hypo to sqrt(tempH * tempH + tempV * tempV)
    if hypo < the InnerRadius of child then
      if not insideInner then
        EnterInnerRadius(me)
      end if
    else
      if insideInner then
        ExitInnerRadius(me)
      end if
    end if
  end if
end

on enterOuterRadius me
end

on ExitOuterRadius me
end

on EnterInnerRadius me
  if OKToEnter then
    set sndId to play(gSound, getAt(the sounds of child, 1), #OPEFFECT)
    setSpeed(the carDriving of gDir, 0)
    steer(the carDriving of gDir, 0)
    programControl(the carDriving of gDir, 1)
    fillErUp(the carDriving of gDir)
  end if
  set insideInner to 1
end

on ExitInnerRadius me
  set insideInner to 0
end
