property activeClick, enterMouseDown
global gDir, gSound

on beginSprite me
  set activeClick to 1
  set enterMouseDown to 0
end

on activateClick me, theState
  set activeClick to theState
end

on mouseUp me
  if activeClick then
    if enterMouseDown = 0 then
      go(marker("06"))
    end if
  end if
end

on mouseEnter me
  if activeClick then
    if the mouseDown then
      set enterMouseDown to 1
    else
      set the loc of sprite getaProp(the spriteList of gDir, #HighLight) to point(320, 240)
      set the member of sprite getaProp(the spriteList of gDir, #HighLight) to "03b006v0"
      sendSprite(115, #c_click)
      play(gSound, "02e011v0", #EFFECT)
    end if
  end if
end

on mouseLeave me
  if activeClick then
    if the mouseDown = 0 then
      set the member of sprite getaProp(the spriteList of gDir, #HighLight) to "dummy"
      sendSprite(115, #C_Standard)
    end if
    set enterMouseDown to 0
  end if
end
