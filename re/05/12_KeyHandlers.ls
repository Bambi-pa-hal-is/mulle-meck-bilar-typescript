property acc, brake, doIdle, wasKeySteer, up, down
global gDir

on new me
  set acc to 0
  set brake to 0
  set doIdle to 1
  if the machineType = 256 then
    set up to 38
    set down to 40
  else
    set up to 126
    set down to 125
  end if
  return me
end

on kill me
  return 0
end

on setDoIdle me, YesNo
  set doIdle to YesNo
end

on idle me
  if doIdle then
    myidle(me)
  end if
end

on myidle me
  if the gotKeyPoll of gDir then
    set tempKeys to bgAllKeys()
    set tempAcc to the shiftDown or the mouseDown or getPos(tempKeys, up)
    set tempBrake to the controlDown or the rightMouseDown or getPos(tempKeys, down)
  else
    set tempAcc to the shiftDown or the mouseDown
    set tempBrake to the controlDown or the rightMouseDown
  end if
  if acc then
    if not tempAcc then
      keyUp(gDir, #up)
      set acc to 0
    end if
  else
    if tempAcc then
      if the mouseDown then
        set wasKeySteer to the keySteer of the carDriving of gDir
        setKeySteer(gDir, 0)
      else
        setKeySteer(gDir, 1)
      end if
      keyDown(gDir, #up)
      set acc to 1
    end if
  end if
  if brake then
    if not tempBrake then
      keyUp(gDir, #down)
      set brake to 0
    end if
  else
    if tempBrake then
      if the rightMouseDown then
        setKeySteer(gDir, 0)
      else
        setKeySteer(gDir, 1)
      end if
      keyDown(gDir, #down)
      set brake to 1
    end if
  end if
end
