property mediaName, trackRect, tracking, active
global gSound, gMulleGlobals

on beginSprite me
  set tracking to 0
  set trackRect to EMPTY
  set active to 1
end

on activate me, theState
  set active to theState
end

on mouseEnter me
  if active and not tracking then
    set tracking to 1
    set trackRect to the rect of sprite the spriteNum of me
    if the releaseOk of sprite(120) = 0 then
      sendSprite(115, #c_click)
    else
      sendSprite(115, #c_MoveIn)
    end if
    play(gSound, "02e016v0", #OPEFFECT)
    set the member of sprite the spriteNum of me to the memberNum of sprite the spriteNum of me + 1
  end if
end

on isMouseOver me
  if inside(point(the mouseH, the mouseV), trackRect) then
    return 1
  else
    return 0
  end if
end

on enterFrame me
  if trackRect = EMPTY then
    set trackRect to the rect of sprite the spriteNum of me
  end if
end

on prepareFrame me
  if tracking then
    if not inside(point(the mouseH, the mouseV), trackRect) then
      play(gSound, "02e015v0", #OPEFFECT)
      set the member of sprite the currentSpriteNum to the memberNum of sprite the currentSpriteNum - 1
      set tracking to 0
      if the releaseOk of sprite(120) then
        sendSprite(115, #c_grab)
      else
        sendSprite(115, #C_Standard)
      end if
    end if
  end if
end

on checkMyRect me
  put "DOWN UP"
  put "RELEASEOK? ", the releaseOk of sprite(120)
  if active then
    if inside(point(the mouseH, the mouseV), trackRect) then
      if the puttingBack of sprite(120) = "center" then
        sendSprite(120, #forcePartInPlace)
      end if
      put "settin the wherefrom"
      set the WhereFrom of gMulleGlobals to "02"
      put "the wherefrom in ceckrect ", the WhereFrom of gMulleGlobals
      go(string(mediaName))
    end if
  end if
end

on getPropertyDescriptionList
  set p_list to [#mediaName: [#comment: "the name of the destination marker:", #format: #string, #default: EMPTY]]
  return p_list
end
