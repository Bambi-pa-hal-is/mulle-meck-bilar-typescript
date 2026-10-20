property isOver
global gDir

on beginSprite me
  set isOver to 0
end

on mouseEnter me
  add(the mouseOverCar of gDir, 1)
  set the overPart of sprite(getaProp(the spriteList of gDir, #DoorStart)) to 1
  if the active of getAt(the scriptInstanceList of sprite the spriteNum of me, 1) = 1 then
    sendSprite(115, #c_grab)
  end if
end

on mouseLeave me
  deleteOne(the mouseOverCar of gDir, 1)
  set the overPart of sprite(getaProp(the spriteList of gDir, #DoorStart)) to 0
  if the active of sprite(getaProp(the spriteList of gDir, #drag)) then
    set isOver to sendSprite(getaProp(the spriteList of gDir, #DoorStart), #CheckMouse)
    if isOver and the mouseDown then
      sendSprite(115, #c_MoveIn)
    else
      sendSprite(115, #c_grab)
    end if
  else
    sendSprite(115, #C_Standard)
  end if
end
