property dragging, loopcount, mouseCheck
global gDir

on beginSprite
  set dragging to 0
  set mouseCheck to 0
  set dragging to 0
end

on setPart me, theMember
  set the member of sprite the spriteNum of me to theMember
  set dragging to 1
  set mouseCheck to 1
end

on mouseUp me
  forceLetGo(me)
end

on forceLetGo me
  set mouseCheck to 0
  if dragging then
    set dragging to 0
    sendSprite(120, #releasePart)
  end if
end

on drag me
  set the loc of sprite the currentSpriteNum to point(the mouseH, the mouseV)
end
