property child, sndId, insideInner, insideOuter, allowed, FrameList, SP, listLen, counter, mode, allFrameList, opSndId
global gDir, gSound

on new me, theChild
  set child to theChild
  set sndId to 0
  set insideInner to 0
  set insideOuter to 0
  return me
end

on kill me
  set child to 0
  return 0
end

on init me
  global gMulleGlobals
  if getProperty(the car of the user of gMulleGlobals, #HornType) <> 0 then
    set allowed to 1
  else
    set allowed to 0
  end if
  set FrameList to getProp(getFrameList(child), #normal)
  set listLen to count(FrameList)
  set SP to the SPUnder of child
  set the member of sprite SP to member(getAt(FrameList, 1))
  set the loc of sprite SP to the myLoc of child
  set counter to 0
end

on step me, carLoc
  set counter to counter + 1
  if counter > listLen then
    if mode = #Parting then
      setFrames(me, #Outer)
    else
      if mode = #Gathering then
        setFrames(me, #normal)
      else
        set counter to 1
      end if
    end if
  end if
  set the member of sprite SP to member(getAt(FrameList, counter))
  set temp to checkRadius(the drivingHandlers of gDir, me, carLoc, the myLoc of child, #both)
  case temp of
    #EnterInnerRadius:
      EnterInnerRadius(me)
    #ExitInnerRadius:
      ExitInnerRadius(me)
    #enterOuterRadius:
      enterOuterRadius(me)
    #ExitOuterRadius:
      ExitOuterRadius(me)
    #EnterBoth:
      enterOuterRadius(me)
      EnterInnerRadius(me)
    #ExitBoth:
      ExitInnerRadius(me)
      ExitOuterRadius(me)
  end case
end

on enterOuterRadius me
  set opSndId to play(gSound, getAt(the sounds of child, 2), #OPEFFECT)
end

on ExitOuterRadius me
  stop(gSound, opSndId)
end

on EnterInnerRadius me
  if allowed then
    setFrames(me, #Parting)
    set sndId to play(gSound, the hornSound of the carDriving of gDir, #EFFECT)
  else
    if finished(gSound, sndId) then
      set sndId to play(gSound, getAt(the sounds of child, 1), #EFFECT)
    end if
    setSpeed(the carDriving of gDir, 0)
    stepback(the carDriving of gDir, 2)
    set insideInner to 0
  end if
end

on ExitInnerRadius me
  if allowed then
    setFrames(me, #Gathering)
  end if
end

on setFrames me, theMode
  set mode to theMode
  set FrameList to getProp(getFrameList(child), mode)
  set listLen to count(FrameList)
  set the member of sprite SP to member(getAt(FrameList, 1))
  set counter to 1
end
