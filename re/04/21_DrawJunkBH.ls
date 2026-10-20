property partLoc
global gDir

on beginSprite me
  global gMulleGlobals
  set tempSP to -1 + the spriteNum of me
  set floorParts to getJunk(the user of gMulleGlobals, #yard)
  set maxYardParts to 35
  set maxDraw to count(floorParts)
  repeat with n = 1 to maxDraw
    set partId to getPropAt(floorParts, n)
    set partLoc to getAt(floorParts, n)
    set part to getPart(the parts of gMulleGlobals, partId)
    set the member of sprite tempSP + n to member(getJunkView(part))
    set partLoc to point(500 + random(30), 380 + random(30))
    set the loc of sprite tempSP + n to partLoc
  end repeat
end

on drawJunk me, WorldParts
  global gMulleGlobals
  set tempSP to -1 + the spriteNum of me
  set floorParts to getJunk(the user of gMulleGlobals, #yard)
  set maxYardParts to 20
  set maxDraw to count(floorParts)
  repeat with n = 1 to maxYardParts
    if n <= maxDraw then
      set partId to getPropAt(floorParts, n)
      set partLoc to getAt(floorParts, n)
      sendSprite(tempSP + n, #setPart, partId, partLoc)
      next repeat
    end if
    set the loc of sprite tempSP + n to point(-200, -200)
  end repeat
  if maxDraw < maxYardParts then
    sendSprite(tempSP + maxDraw + 1, #setPart, 0)
  end if
end
