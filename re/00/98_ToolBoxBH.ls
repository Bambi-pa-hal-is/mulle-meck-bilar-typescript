property counter, mode, SP, startLocH, max, step, centerH, activeClick, isInside, trackRect, checkForLeave
global gDir, gSound

on beginSprite me
  set SP to the spriteNum of me
  set startLocH to the locH of sprite SP
  set max to 4
  set step to 11
  set counter to 0
  set mode to #in
  set centerH to 640
  set isInside to 0
  set trackRect to rect(560, 400, 800, 650)
  set checkForLeave to 0
  set activeClick to 1
end

on activateClick me, theState
  set activeClick to theState
end

on exitFrame me
  if checkForLeave then
    if not inside(point(the mouseH, the mouseV), trackRect) then
      mymouseLeave(me)
    end if
  end if
  if counter then
    set counter to counter - 1
    if mode = #in then
      set the locH of sprite SP to startLocH - counter * step
    else
      if mode = #Out then
        set the locH of sprite SP to startLocH - (max - counter) * step
      end if
    end if
  end if
end

on mouseEnter me
  if activeClick then
    set checkForLeave to 1
    if mode = #in then
      if counter < 4 then
        play(gSound, "00e040v0", #OPEFFECT)
      end if
      set mode to #Out
      set counter to max - counter
      set isInside to 0
    end if
  else
    if mode = #Out then
      set mode to #in
      set counter to max - counter
    end if
  end if
end

on mymouseLeave me
  set isInside to 0
  set checkForLeave to 0
  if mode = #Out then
    set mode to #in
    set counter to max - counter
  end if
end

on mouseUp me
  if activeClick then
    if char 1 to 2 of the movie = "02" then
      sendSprite(getaProp(the spriteList of gDir, #drag), #forceLetGo)
    end if
    set counter to 0
    set mode to #Out
    set the locH of sprite SP to startLocH - max * step
    sendSprite(getProp(the spriteList of gDir, #fDialog), #functionDialogSwitch)
  end if
end
