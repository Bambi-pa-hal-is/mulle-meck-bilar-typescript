property screenObjects, isOn, startSP, coverSP, active, rolling, sndId
global gDir, gSound

on beginSprite me
  set active to 1
  set rolling to 0
  set isOn to 0
  set startSP to 1 + the spriteNum of me
  set coverSP to 110
end

on activate me, YesNo
  set active to YesNo
end

on mouseEnter me
  set rolling to 1
end

on mouseLeave me
  set rolling to 0
  stop(gSound, sndId)
end

on exitFrame me
  if rolling then
    set rolling to rolling + 1
    if rolling = 15 then
      stopAllEffects(gSound)
      if the mode of gDir = #save then
        set sndId to play(gSound, "06d007v0", #EFFECT)
      else
        set sndId to play(gSound, "07d005v0", #EFFECT)
      end if
    end if
  end if
end

on mouseUp me
  if active then
    play(gSound, "SndMouseClick", #OPEFFECT)
    if the controlDown and the shiftDown and the key = "f" then
      set the cheatLoad of gDir to 1
    else
      set the cheatLoad of gDir to 0
    end if
    disk(me)
    exit
    if not isOn then
      set the member of sprite coverSP to member("rectum")
      set the foreColor of sprite coverSP to 0
      set the rect of sprite coverSP to rect(0, 0, 640, 480)
      set isOn to 1
      set screenObjects to []
      set midPoint to point(515, 438)
      set tempDiff to midPoint - point(309, 385)
      set tempObj to new(script("ScreenObject"), me, rect(229, 380, 290, 411), EMPTY, point(0, 0))
      addScreenObject(gDir, tempObj)
      add(screenObjects, tempObj)
      moveRegLoc(tempObj, tempDiff)
      set tempObj to new(script("ScreenObject"), me, rect(297, 380, 358, 411), EMPTY, point(0, 0))
      addScreenObject(gDir, tempObj)
      add(screenObjects, tempObj)
      moveRegLoc(tempObj, tempDiff)
      set tempObj to new(script("ScreenObject"), me, rect(362, 384, 390, 412), EMPTY, point(0, 0))
      addScreenObject(gDir, tempObj)
      add(screenObjects, tempObj)
      moveRegLoc(tempObj, tempDiff)
      set the loc of sprite startSP to midPoint
      if the mode of gDir = #load then
        set the member of sprite startSP to member("07b003v0")
        play(gSound, "07d003v0", #EFFECT)
      else
        set the member of sprite startSP to member("06b013v0")
      end if
    end if
  end if
end

on report me, theObject, what
  if what = #clicked then
    set tempPos to getPos(screenObjects, theObject)
    close(me)
    updateStage()
    if tempPos = 1 then
      if the mode of gDir = #load then
        loadCar(gDir)
      else
        if the slotOccupied of gDir then
          replaceAsk(gDir)
        else
          prepareEnterName(gDir)
        end if
      end if
    else
      if tempPos = 2 then
        disk(me)
      else
      end if
    end if
  end if
end

on close me
  set the member of sprite coverSP to member("Dummy")
  set the member of sprite startSP to member("Dummy")
  set isOn to 0
  if listp(screenObjects) then
    if objectp(gDir) then
      repeat with index in screenObjects
        deleteScreenObject(gDir, index)
      end repeat
      set screenObjects to 0
    end if
  end if
end

on endSprite me
  close(me)
end

on disk me
  if the mode of gDir = #save then
    if the slotOccupied of gDir then
      saveIfNecessary(gDir)
      set tempDefault to correctFileName(me, the text of member("SavedCarName"))
      set the defaultFilename of gDir to tempDefault
    else
      set the defaultFilename of gDir to the text of member("06t001v0")
    end if
  end if
  openWindow(gDir)
end

on correctFileName me, theName
  if the machineType = 256 then
    set theName to changeChars("\", EMPTY, theName)
    set theName to changeChars("*", EMPTY, theName)
    set theName to changeChars(":", EMPTY, theName)
    set theName to changeChars("?", EMPTY, theName)
    set theName to changeChars(QUOTE, EMPTY, theName)
  else
    set theName to changeChars(":", EMPTY, theName)
  end if
  return theName
end
