on mouseDown
  global gDir
  set X to sendSprite(getaProp(the spriteList of gDir, #DoorStart), #isMouseOver)
  set the overDoor of gDir to X
end

on mouseUp
  global gDir
  if the overDoor of gDir and the frame <= 60 then
    sendSprite(getaProp(the spriteList of gDir, #DoorStart), #checkMyRect)
  else
    sendSprite(getaProp(the spriteList of gDir, #drag), #forceLetGo)
  end if
end
