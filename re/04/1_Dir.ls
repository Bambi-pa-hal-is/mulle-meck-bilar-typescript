property ancestor, spriteList, cursorOverList, partsCommon, carCopy, webParts, WorldParts, screenClicked, carOnYard, mouseButtonActive, returnFromWindow, goWorld, gCurrentSound
global gMulleGlobals

on new me
  set ancestor to new(script("GeneralAncestor"), me)
  set webParts to []
  set WorldParts to []
  set spriteList to [#CarStart: 19, #DoorStart: 10, #fDialog: 107, #JunkStart: 61, #drag: 100, #mailBox: 13, #giftSprite: 60, #addresNote: 105, #mulleInCar: 38, #mulleStand: 59, #Buffa: 58, #mailBox: 13, #carClick: 101]
  set carCopy to the car of the user of gMulleGlobals
  set screenClicked to 0
  set carOnYard to 0
  set the mouseUpScript to "virtualMouseUp"
  set the mouseDownScript to "virtualMouseDown"
  set mouseButtonActive to 1
  set gCurrentSound to EMPTY
  set returnFromWindow to 0
  set goWorld to 0
  set the loc of sprite getProp(spriteList, #fDialog) to point(320, 240)
  set props to the carProperties of the car of the user of gMulleGlobals
  if the toYardThroughDoor of the user of gMulleGlobals = 0 then
    set carOnYard to 1
    set the loc of sprite getaProp(spriteList, #carClick) to point(50, 15)
    set the member of sprite getaProp(spriteList, #CarStart) + 7 to "20b001v1"
    set the member of sprite getaProp(spriteList, #mulleStand) to "dummy"
    set the member of sprite getaProp(spriteList, #Buffa) to "dummy"
  else
    set carOnYard to 0
    set the loc of sprite getaProp(spriteList, #carClick) to point(-400, -400)
    set the member of sprite getaProp(spriteList, #CarStart) + 7 to "dummy"
    set the member of sprite getaProp(spriteList, #mulleInCar) to "dummy"
  end if
  return me
end

on init me
  set partsCommon to new(script("PartsCommon"), me)
end

on choseWorld me, theWorld
  forget(window("test"))
  set returnFromWindow to 1
  if theWorld = 0 then
    set goWorld to 0
  else
    set goWorld to 1
  end if
end

on activate me, theState
  if theState then
    sendAllSprites(#activateClick, 1)
    set mouseButtonActive to 1
  else
    sendAllSprites(#activateClick, 0)
    set mouseButtonActive to 0
  end if
end

on kill me
  if objectp(partsCommon) then
    set partsCommon to kill(partsCommon)
  end if
  if objectp(ancestor) then
    set ancestor to kill(ancestor)
  end if
  return 0
end
