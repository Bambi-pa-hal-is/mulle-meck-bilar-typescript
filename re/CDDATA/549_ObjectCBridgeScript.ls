property child, insideOuter, insideInner, FrameList, listLen, mode, bridgeCounter, opening, waitCounter
global gDir, gMulleGlobals, gSound

on new me, theChild
  set child to theChild
  set insideInner to 0
  set insideOuter to 0
  return me
end

on kill me
  set child to 0
  return 0
end

on init me
  set opening to 1
  set bridgeCounter to 1
  set FrameList to getProp(getFrameList(child), #normal)
  set listLen to count(FrameList)
  set waitCounter to 0
  set the member of sprite the SPUnder of child to member(getAt(FrameList, 1))
  set the loc of sprite the SPUnder of child to the myLoc of child
end

on step me, carLoc
  if insideInner then
    if not (waitCounter and opening = 1) then
      restoreData(the carDriving of gDir)
      setSpeed(the carDriving of gDir, 0)
    end if
  end if
  if waitCounter then
    set waitCounter to waitCounter - 1
  else
    set bridgeCounter to bridgeCounter + opening
    if bridgeCounter = 0 then
      if insideOuter then
        play(gSound, getAt(the sounds of child, 1), #OPEFFECT)
      end if
      set waitCounter to 17
      set bridgeCounter to 1
      set opening to 1
    else
      if bridgeCounter = listLen then
        set waitCounter to 10
        set bridgeCounter to listLen
        set opening to -1
      end if
    end if
    set the member of sprite the SPUnder of child to member(getAt(FrameList, bridgeCounter))
  end if
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
end

on ExitOuterRadius me
end

on EnterInnerRadius me
  saveData(the carDriving of gDir, 1)
end

on ExitInnerRadius me
  saveData(the carDriving of gDir, #none)
end
