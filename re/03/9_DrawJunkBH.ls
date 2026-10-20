global gDir

on beginSprite me
  global gMulleGlobals
  set tempSP to -1 + the spriteNum of me
  set floorParts to getJunk(the user of gMulleGlobals, #shopFloor)
  set maxFloorParts to 35
  set maxDraw to count(floorParts)
  repeat with n = 1 to maxDraw
    set partId to getPropAt(floorParts, n)
    set partLoc to getAt(floorParts, n)
    set part to getPart(the parts of gMulleGlobals, partId)
    set the member of sprite tempSP + n to member(getJunkView(part))
    set the loc of sprite tempSP + n to partLoc
  end repeat
end

on drawJunk me, isFalling, where
  global gMulleGlobals
  set tempSP to -1 + the spriteNum of me
  set floorParts to getJunk(the user of gMulleGlobals, #shopFloor)
  set maxFloorParts to 35
  set maxDraw to count(floorParts)
  repeat with n = 1 to maxDraw - 1
    set partId to getPropAt(floorParts, n)
    set partLoc to getAt(floorParts, n)
    sendSprite(tempSP + n, #setPart, partId, partLoc, 0)
  end repeat
  if maxDraw then
    set partId to getPropAt(floorParts, maxDraw)
    set partLoc to getAt(floorParts, maxDraw)
    sendSprite(tempSP + maxDraw, #setPart, partId, partLoc, isFalling, where)
  end if
  if maxDraw < maxFloorParts then
    sendSprite(tempSP + maxDraw + 1, #setPart, 0)
  end if
end

on setjunk me
end
