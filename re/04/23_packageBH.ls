property activeClick, currentSound
global gDir, gMulleGlobals, gSound

on beginSprite me
  set activeClick to 1
end

on loop me
  if finished(gSound, currentSound) then
    deleteLoopObject(gDir, me)
    set the gCurrentSound of gDir to EMPTY
  else
    put "play"
  end if
end

on activateClick me, theState
  set activeClick to theState
end

on mouseEnter me
  if activeClick then
    sendSprite(115, #c_click)
  end if
end

on mouseLeave me
  if activeClick then
    sendSprite(115, #C_Standard)
  end if
end

on mouseDown me
  if activeClick then
    if the gCurrentSound of gDir = EMPTY then
      set the member of sprite getProp(the spriteList of gDir, #addresNote) to the number of member "04b006v0"
      stopAllEffects(gSound)
      set currentSound to play(gSound, "04d023v0", #EFFECT)
      set the gCurrentSound of gDir to "04d023v0"
      set the loc of sprite getProp(the spriteList of gDir, #addresNote) to point(320, 240)
      sendAllSprites(#activateClick, 0)
      addLoopObject(gDir, me)
    end if
  end if
end
