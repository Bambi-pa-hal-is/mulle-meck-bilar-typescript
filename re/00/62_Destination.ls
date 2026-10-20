property child, sndId, insideOuter, insideInner, counter, FrameList, listLen, readyToGo, canEnter, externalSoundFinished
global gDir, gSound, gMulleGlobals

on new me, theChild
  set child to theChild
  set sndId to 0
  set insideInner to 0
  set insideOuter to 0
  set counter to 0
  set FrameList to []
  set readyToGo to 1
  return me
end

on kill me
  set child to 0
  return 0
end

on init me, carLoc
  set tempDiff to carLoc - the myLoc of child
  set tempH to getAt(tempDiff, 1)
  set tempV to getAt(tempDiff, 2)
  set hypo to sqrt(tempH * tempH + tempV * tempV)
  if hypo <= the OuterRadius of child then
    set insideOuter to 1
    set readyToGo to 0
  end if
  if hypo <= the InnerRadius of child then
    set insideInner to 1
  end if
  set FrameList to getProp(getFrameList(child), #normal)
  set listLen to count(FrameList)
  set counter to 0
  set the member of sprite the SPUnder of child to member(getAt(FrameList, 1))
  set the loc of sprite the SPUnder of child to the myLoc of child
end

on step me, carLoc
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
  if externalSoundFinished then
    if readyToGo and insideInner and the canEnter of child then
      if finished(gSound, sndId) then
        enteredObject(the world of gMulleGlobals, getId(child))
        prepareToLeave(gDir, getDirResource(child))
        exit
      end if
    end if
  else
    if readyToGo and insideOuter then
      set externalSoundFinished to sendSprite(getProp(the spriteList of gDir, #medal), #FinishedSound)
      if externalSoundFinished then
        playSound(me)
      end if
    end if
  end if
  set counter to counter + 1
  set the member of sprite the SPUnder of child to member(getAt(FrameList, counter))
  if counter = listLen then
    set counter to 0
  end if
end

on enterOuterRadius me
  global gSound, gMulleGlobals
  set temp to getProp(getFrameList(child), #Outer)
  if listp(temp) then
    set FrameList to temp
    set listLen to count(FrameList)
    set counter to 0
  end if
  set externalSoundFinished to sendSprite(getProp(the spriteList of gDir, #medal), #FinishedSound)
  if externalSoundFinished then
    playSound(me)
  end if
end

on playSound me
  if the canEnter of child then
    if count(the sounds of child) then
      if finished(gSound, sndId) then
        set sndId to play(gSound, getAt(the sounds of child, 1), #EFFECT)
      end if
    end if
  else
    if count(the sounds of child) > 1 then
      if finished(gSound, sndId) then
        set sndId to play(gSound, getAt(the sounds of child, 2), #EFFECT)
      end if
    end if
  end if
end

on ExitOuterRadius me
  set FrameList to getProp(getFrameList(child), #normal)
  set listLen to count(FrameList)
  set counter to 0
  set readyToGo to 1
end

on EnterInnerRadius me
  if readyToGo and the canEnter of child then
    programControl(the carDriving of gDir, 1)
    set saveThis to symbol("Visited" & getDirResource(child))
    setUserProp(the user of gMulleGlobals, saveThis)
    setSpeed(the carDriving of gDir, 0)
    steer(the carDriving of gDir, 0)
  end if
end

on ExitInnerRadius me
end
