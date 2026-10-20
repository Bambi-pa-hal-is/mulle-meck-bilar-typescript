property child, insideOuter, insideInner, FrameList, listLen, counter, canDoIt, exists, sndId, wasCarSoundOn
global gDir, gMulleGlobals, gSound

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
  set exists to 1
  if getProperty(the car of the user of gMulleGlobals, #Weight) < 20 then
    set canDoIt to 1
  else
    set canDoIt to 0
  end if
  set FrameList to getProp(getFrameList(child), #normal)
  set listLen to count(FrameList)
  set counter to 0
  set the member of sprite the SPUnder of child to member(getAt(FrameList, 1))
  set the loc of sprite the SPUnder of child to the myLoc of child
end

on step me, carLoc
  set counter to counter + 1
  if insideInner and not canDoIt then
    if counter = 9 then
      show(the carDriving of gDir, 0)
    else
      if counter > listLen then
        play(gSound, getAt(the sounds of child, 2), #EFFECT)
        restoreData(the carDriving of gDir)
        set carLoc to getShowCoordinate(the carDriving of gDir)
        set FrameList to getProp(getFrameList(child), #Gone)
        set listLen to count(FrameList)
        set counter to 1
        if wasCarSoundOn then
          changecarSound(the displayObject of the carDriving of gDir, 1)
        end if
      end if
    end if
  else
    if counter > listLen then
      set counter to 1
    end if
  end if
  set the member of sprite the SPUnder of child to member(getAt(FrameList, counter))
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
  if not exists then
    setSpeed(the carDriving of gDir, 0)
    restoreData(the carDriving of gDir)
  end if
end

on ExitOuterRadius me
  saveData(the carDriving of gDir, #none)
end

on EnterInnerRadius me
  if not canDoIt then
    set exists to 0
    programControl(the carDriving of gDir, 1)
    set sndId to play(gSound, getAt(the sounds of child, 1), #EFFECT)
    setSpeed(the carDriving of gDir, 0)
    set FrameList to getProp(getFrameList(child), #Splash)
    doubleFrames(me)
    set listLen to count(FrameList)
    set counter to 1
    set wasCarSoundOn to the soundOn of the displayObject of the carDriving of gDir
    changecarSound(the displayObject of the carDriving of gDir, 0)
  else
    set medalId to 6
    if not getMedal(the car of the user of gMulleGlobals, medalId) then
      addMedal(the car of the user of gMulleGlobals, medalId)
      sendSprite(getProp(the spriteList of gDir, #medal), #Blink, medalId)
    end if
  end if
end

on ExitInnerRadius me
  programControl(the carDriving of gDir, 0)
  show(the carDriving of gDir, 1)
end

on doubleFrames me
  set nr to 6
  set n to 1
  repeat while 1
    repeat with X = 1 to nr
      addAt(FrameList, n, getAt(FrameList, n))
    end repeat
    set n to n + nr + 2
    if n > count(FrameList) then
      exit repeat
    end if
  end repeat
end
