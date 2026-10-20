property child, OKToPass, insideInner, insideOuter, hillType, medalId, sndId
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
  set hillType to getaProp(getOptionalData(child), #hillType)
  if not (hillType = #BigHill) then
    set hillType to #SmallHill
  end if
  if getProp(the criteria of the carDriving of gDir, hillType) = 1 then
    set OKToPass to 1
    set medalId to getAt(getSetWhenDone(child, #medals), 1)
  else
    set OKToPass to 0
  end if
end

on step me, carLoc
  set temp to checkRadius(the drivingHandlers of gDir, me, carLoc, the myLoc of child, #both)
  case temp of
    #enterOuterRadius:
      enterOuterRadius(me)
    #ExitOuterRadius:
      ExitOuterRadius(me)
    #EnterInnerRadius:
      EnterInnerRadius(me)
    #ExitInnerRadius:
      ExitInnerRadius(me)
    #EnterBoth:
      enterOuterRadius(me)
      EnterInnerRadius(me)
    #ExitBoth:
      ExitInnerRadius(me)
      ExitOuterRadius(me)
  end case
end

on enterOuterRadius me
  saveData(the carDriving of gDir, 1)
end

on ExitOuterRadius me
  saveData(the carDriving of gDir, #none)
end

on ExitInnerRadius me
end

on EnterInnerRadius me
  if not OKToPass then
    if finished(gSound, sndId) then
      if hillType = #BigHill then
        set sndId to play(gSound, getAt(the sounds of child, 1), #EFFECT)
      else
        set sndId to play(gSound, getAt(the sounds of child, 2), #EFFECT)
      end if
    end if
    restoreData(the carDriving of gDir)
    setSpeed(the carDriving of gDir, 0)
  else
    if hillType = #BigHill then
      set medalId to 1
      if not getMedal(the car of the user of gMulleGlobals, medalId) then
        addMedal(the car of the user of gMulleGlobals, medalId)
        sendSprite(getProp(the spriteList of gDir, #medal), #Blink, medalId)
      end if
    end if
  end if
end
